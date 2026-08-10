extends Node

## El "cerebro" de todos los NPCs del mundo (ver NpcRoster para la
## lista): dónde está cada uno, hacia dónde va, y en qué modo — corre
## todo el tiempo, sin importar qué mapa esté cargado. Las escenas
## (CityMap para verlos caminar, GarageMap para el encuentro puntual)
## solo leen este estado para mostrarlo; nunca son la fuente de verdad.
##
## Modos de un NPC:
## - "patrol": deambulando su rutina del día (rebota entre b_point y el
##   punto final de una ruta al azar, reservada solo para él — ver
##   _reserve_random_route). El punto 0 (la puerta del taller) nunca es
##   parte de este ciclo, solo es destino en "to_workshop". Si un punto
##   tiene NpcRouteWaitPoint.gd, se queda parado ahí esos minutos de
##   juego antes de seguir — se ignora por completo en cualquier otro
##   modo (si lo llaman, corta la espera y va derecho al taller).
## - "to_workshop": le aceptaron/le avisaron de un encargo — corta la
##   rutina y camina de vuelta por la MISMA ruta que ya tenía, hacia el
##   punto 0 (la puerta del taller), tarde lo que tarde.
## - "entering_garage": ya llegó a la puerta del taller y camina desde
##   ahí hasta el lugar donde está (o va a estar) el auto del encargo —
##   este tramo también se simula acá, nunca depende de que el garage
##   esté cargado (así el NPC llega igual aunque no estés mirando).
## - "waiting_at_door": ya llegó junto al auto y espera parado — de acá
##   en más lo maneja la escena del garage (ver JobEncounterSpawner),
##   hasta que se llama a start_leaving_garage().
## - "leaving_garage": terminó el encuentro (entrega o retiro) y camina
##   de vuelta a la puerta — también simulado acá, para que termine de
##   irse aunque el jugador ya haya salido del garage. Al llegar a la
##   puerta retoma la patrulla normal (resume_patrol), sola.
## - "off_duty": completó un retiro — no se lo ve en ningún mapa (ni
##   ciudad ni garage) por el resto del día de juego. Vuelve solo a
##   "patrol" en cuanto cambia el día (ver TimeManager.day_changed).
##
## Rutas exteriores: se leen una sola vez de CityMap.tscn al arrancar
## (los grupos de Marker2D bajo "WanderRoutes", con "anchor_point_path"
## como punto 0 de todas). El tramo interior del garage (puerta + lugares
## de estacionamiento) se lee de la misma forma desde GarageMap.tscn —
## en ambos casos se instancia la escena en memoria sin agregarla al
## árbol, así el simulador nunca depende de que ese mapa esté cargado.

## Debe coincidir con Client.gd (que reproduce visualmente este mismo
## movimiento cuando la escena está a la vista).
const WALK_SPEED := 80.0 # cambiar a 40.0 cuando ya no testiemos npcs

const CITY_MAP_PATH := "res://scenes/city/CityMap.tscn"
const ROUTES_CONTAINER_NAME := "WanderRoutes"
const ANCHOR_NODE_PATH := "Map/outside_garage/PlayerSpawn"
const HOMES_CONTAINER_NAME := "homes"

const GARAGE_MAP_PATH := "res://scenes/garage/GarageMap.tscn"
const GARAGE_SPAWNER_NODE_PATH := "Map/vehicles/JobEncounterSpawner"

const NAV_REGION_NODE_NAME := "NavigationRegion2D"

## Hora fija (igual para todos los NPCs) en la que cortan la patrulla y
## caminan a su casa — ver _on_minute_changed. La hora de DESPERTAR sí
## es por NPC (ver NpcHome.gd/_home_wake_hours), a propósito, para que
## no salgan todos juntos.
const HEAD_HOME_HOUR := 20.0

## Offset desde el lugar de estacionamiento donde el NPC se para a
## esperar (no encima del sprite del vehículo). JobEncounterSpawner usa
## la posición del lugar sin este offset para ubicar el auto.
const WAITING_OFFSET := Vector2(0, 24)

## Emite cuando un NPC que iba camino al taller (por un encargo) llega
## junto al auto y queda esperando. JobEncounterSpawner escucha esto
## (o directamente lee get_mode todos los frames) para mostrarlo.
signal npc_arrived_at_workshop(npc_id: String, job_id: String)

var _routes: Dictionary = {}  # route_name (String) -> Array[Vector2]
var _route_waits: Dictionary = {}  # route_name (String) -> Array[float] (minutos de juego, index a index con _routes)
var _route_reservations: Dictionary = {}  # route_name (String) -> npc_id (String)
var _npc_state: Dictionary = {}  # npc_id (String) -> Dictionary (ver _init_npc)

var _garage_door_position := Vector2.ZERO
var _garage_spot_positions: Array[Vector2] = []
var _job_spots: Dictionary = {}  # job_id (String) -> spot_index (int)

var _homes: Dictionary = {}  # npc_id (String) -> Vector2
var _home_wake_hours: Dictionary = {}  # npc_id (String) -> float (0-24)

## Mapa de NavigationServer2D armado a mano (ver _load_navigation) con el
## NavigationPolygon de CityMap.tscn — RID() (inválido) si esa escena
## todavía no tiene un NavigationRegion2D horneado. Usado "headless": sin
## ningún NavigationAgent2D ni nodo en el árbol, solo consultas por
## código, para no romper que esto corra sin depender de qué mapa esté
## cargado.
var _nav_map := RID()

func _ready() -> void:
	print("[NpcDirector] _ready() arrancando...")

	_load_routes()
	print("[NpcDirector] rutas cargadas: %s" % [_routes.keys()])

	_load_homes()
	print("[NpcDirector] casas cargadas: %s" % [_homes])

	_load_garage_layout()
	_load_navigation()

	# SaveManager (autoload anterior a este, ver project.godot) ya corrió
	# load_game() para acá si había partida guardada — Game.state.npc_snapshots
	# ya viene con los datos si corresponde.
	for npc_id in NpcRoster.ALL:
		_restore_or_init_npc(npc_id)

	TimeManager.day_changed.connect(_on_day_changed)
	TimeManager.minute_changed.connect(_on_minute_changed)
	print("[NpcDirector] listo — conectado a minute_changed.")

## Instancia CityMap.tscn en memoria (sin agregarlo al árbol) solo para
## leer las posiciones de sus Marker2D, y lo descarta enseguida.
func _load_routes() -> void:
	var city_scene: PackedScene = load(CITY_MAP_PATH)
	var city: Node = city_scene.instantiate()

	var anchor: Node2D = city.get_node(ANCHOR_NODE_PATH)
	var container: Node = city.find_child(ROUTES_CONTAINER_NAME, true, false)

	if container:
		for route_node in container.get_children():
			var points: Array[Vector2] = [anchor.global_position]
			var waits: Array[float] = [0.0]  # el punto 0 (la puerta) nunca espera
			for point_node in route_node.get_children():
				points.append(point_node.global_position)
				# Si el punto no tiene NpcRouteWaitPoint.gd (u otro script sin
				# esa propiedad), point_node.get() devuelve null -> 0.0.
				waits.append(point_node.get("wait_minutes") if point_node.get("wait_minutes") != null else 0.0)

			if points.size() >= 2:
				_routes[route_node.name] = points
				_route_waits[route_node.name] = waits

	city.free()

## Mismo truco, pero para leer las casas (NpcHome.gd) — un Marker2D por
## NPC bajo Map/Homes, con su propio npc_id y wake_hour. Un NPC sin
## casa configurada ahí simplemente no entra al ciclo de dormir/
## despertar (ver _on_minute_changed) y sigue patrullando como siempre.
func _load_homes() -> void:
	var city_scene: PackedScene = load(CITY_MAP_PATH)
	var city: Node = city_scene.instantiate()

	var container: Node = city.find_child(HOMES_CONTAINER_NAME, true, false)
	print("[NpcDirector] buscando contenedor '%s' -> %s" % [HOMES_CONTAINER_NAME, container])

	if container:
		print("[NpcDirector] '%s' tiene %d hijo(s): %s" % [
			HOMES_CONTAINER_NAME, container.get_child_count(), container.get_children()
		])
		for home_node in container.get_children():
			var home_npc_id: Variant = home_node.get("npc_id")
			print("[NpcDirector] hijo '%s' -> npc_id=%s (script=%s)" % [home_node.name, home_npc_id, home_node.get_script()])
			if home_npc_id != null and home_npc_id != "":
				_homes[home_npc_id] = home_node.global_position
				var wake: Variant = home_node.get("wake_hour")
				_home_wake_hours[home_npc_id] = wake if wake != null else 6.5

	city.free()

	if _homes.is_empty():
		push_warning("NpcDirector: no encontré ninguna casa en Map/%s de CityMap.tscn (¿falta guardar la escena, o el contenedor no se llama exactamente así?) — ningún NPC va a tener ciclo de dormir/despertar." % HOMES_CONTAINER_NAME)

## Mismo truco que _load_routes, pero para leer del garage dónde está
## la puerta de entrada y los lugares de estacionamiento — los mismos
## NodePath que ya usa JobEncounterSpawner (export vars leídas desde su
## nodo, sin duplicar los paths a mano).
func _load_garage_layout() -> void:
	var garage_scene: PackedScene = load(GARAGE_MAP_PATH)
	var garage: Node = garage_scene.instantiate()

	var spawner: Node2D = garage.get_node(GARAGE_SPAWNER_NODE_PATH)
	_garage_door_position = spawner.get_node(spawner.client_spawn_point).global_position

	_garage_spot_positions.clear()
	for spot_path in spawner.parking_spots:
		_garage_spot_positions.append(spawner.get_node(spot_path).global_position)

	garage.free()

## Registra "a mano" el NavigationPolygon de CityMap.tscn en un mapa de
## NavigationServer2D propio, sin depender de que ese NavigationRegion2D
## esté nunca en el árbol — mismo espíritu que _load_routes/_load_garage_layout.
##
## A propósito NO se combina por código con otros CollisionPolygon2D
## sueltos del mapa (edificios, calles) — la API de Godot para armar un
## NavigationPolygon (make_polygons_from_outlines) no tolera que los
## contornos se toquen ni se cruicen entre sí, y esos polígonos no se
## dibujaron pensando en eso. Todo (el contorno grande, los agujeros de
## los edificios, los cortes para cruzar la calle) se dibuja a mano en
## el editor de NavigationPolygon del NavigationRegion2D — esa
## herramienta sí está pensada para evitar cruces entre contornos.
func _load_navigation() -> void:
	var city_scene: PackedScene = load(CITY_MAP_PATH)
	var city: Node = city_scene.instantiate()

	var nav_region: NavigationRegion2D = city.find_child(NAV_REGION_NODE_NAME, true, false)
	if nav_region and nav_region.navigation_polygon:
		_nav_map = NavigationServer2D.map_create()
		NavigationServer2D.map_set_active(_nav_map, true)

		var region := NavigationServer2D.region_create()
		NavigationServer2D.region_set_map(region, _nav_map)
		NavigationServer2D.region_set_transform(region, nav_region.global_transform)
		NavigationServer2D.region_set_navigation_polygon(region, nav_region.navigation_polygon)
	else:
		push_warning("NpcDirector: CityMap.tscn no tiene ningún '%s' horneado — los NPCs van a caminar en línea recta." % NAV_REGION_NODE_NAME)

	city.free()

func _init_npc(npc_id: String) -> void:
	var route_name := _reserve_random_route(npc_id)
	if route_name == "":
		return  # no hay ninguna ruta cargada (revisá CityMap.tscn/WanderRoutes)

	_npc_state[npc_id] = {
		"route": route_name,
		"points": _routes[route_name],
		"waits": _route_waits[route_name],
		"index": 1,
		"dir": 1,
		"position": _routes[route_name][1],
		"mode": "patrol",
		"job_id": "",
		"wait_remaining": 0.0,
		"_wait_consumed": false,
		"nav_path": [],
	}

## Si hay un snapshot guardado para este NPC (ver capture_snapshot), lo
## retoma tal cual — misma ruta reservada, mismo índice/dirección,
## misma posición exacta, mismo modo, sin importar cuál sea (patrullando,
## camino al taller, esperando, de franco). Si no hay snapshot (partida
## nueva, o NPC agregado después del último guardado), arranca de cero.
func _restore_or_init_npc(npc_id: String) -> void:
	var snapshot: Dictionary = Game.state.npc_snapshots.get(npc_id, {})
	if snapshot.is_empty():
		_init_npc(npc_id)
		return

	var mode: String = snapshot.get("mode", "patrol")
	var route_name: String = snapshot.get("route", "")
	var job_id: String = snapshot.get("job_id", "")
	var position: Vector2 = snapshot.get("position", Vector2.ZERO)
	var points: Array = _points_for_restored_mode(npc_id, mode, route_name, job_id, position)

	if mode in ["patrol", "to_workshop", "to_route"] and points.size() < 2:
		_init_npc(npc_id)  # la ruta guardada ya no existe (se rediseñó el mapa) — arranca de cero
		return

	if route_name != "" and _routes.has(route_name):
		_route_reservations[route_name] = npc_id

	_npc_state[npc_id] = {
		"route": route_name,
		"points": points,
		"waits": _route_waits.get(route_name, []),
		"index": snapshot.get("index", 0),
		"dir": snapshot.get("dir", 1),
		"position": position,
		"mode": mode,
		"job_id": job_id,
		"wait_remaining": snapshot.get("wait_remaining", 0.0),
		# Si se guardó a mitad de una espera (wait_remaining > 0), esto
		# viene en true — si no se persiste tal cual, al terminar los
		# minutos que le quedaban arrancaría la espera completa de
		# nuevo en vez de seguir camino (ver _on_point_reached).
		"_wait_consumed": snapshot.get("_wait_consumed", false),
		"nav_path": [],  # se recalcula solo en el próximo paso (ver _begin_travel_to)
	}

## Reconstruye el array de puntos según el modo guardado — nunca se
## persiste "points" directo (dependen de posiciones del mapa que se
## recalculan solas al cargar GarageMap/CityMap.tscn de nuevo).
func _points_for_restored_mode(
	npc_id: String, mode: String, route_name: String, job_id: String, position: Vector2
) -> Array:
	match mode:
		"entering_garage":
			return [_garage_door_position, get_job_spot_position(job_id) + WAITING_OFFSET]
		"leaving_garage":
			return [position, _garage_door_position]  # solo importa points[1], el índice queda fijo en 1
		"to_home":
			return [_homes.get(npc_id, position)]
		"patrol", "to_workshop", "to_route":
			return _routes.get(route_name, [])
		_:
			return []  # "waiting_at_door"/"off_duty"/"at_home": no se mueven, no hace falta

## Lo llama SaveManager antes de guardar — vuelca el estado de cada NPC
## (sin importar el modo) a Game.state.npc_snapshots para que
## _restore_or_init_npc pueda retomarlo tal cual la próxima vez.
func capture_snapshot() -> void:
	var snapshot := {}

	for npc_id in _npc_state.keys():
		var state: Dictionary = _npc_state[npc_id]
		snapshot[npc_id] = {
			"route": state.get("route", ""),
			"index": state.get("index", 0),
			"dir": state.get("dir", 1),
			"position": state.position,
			"mode": state.mode,
			"job_id": state.get("job_id", ""),
			"wait_remaining": state.get("wait_remaining", 0.0),
			"_wait_consumed": state.get("_wait_consumed", false),
		}

	Game.state.npc_snapshots = snapshot

func _reserve_random_route(npc_id: String) -> String:
	var free_routes: Array = []
	for route_name in _routes.keys():
		if not _route_reservations.has(route_name):
			free_routes.append(route_name)

	if free_routes.is_empty():
		return ""

	var chosen: String = free_routes[randi() % free_routes.size()]
	_route_reservations[chosen] = npc_id
	return chosen

func _release_route(npc_id: String) -> void:
	for route_name in _route_reservations.keys():
		if _route_reservations[route_name] == npc_id:
			_route_reservations.erase(route_name)
			return

# --- Consultas para las escenas visuales --------------------------------

func get_position(npc_id: String) -> Vector2:
	return _npc_state.get(npc_id, {}).get("position", Vector2.ZERO)

func get_mode(npc_id: String) -> String:
	return _npc_state.get(npc_id, {}).get("mode", "")

func get_job_id(npc_id: String) -> String:
	return _npc_state.get(npc_id, {}).get("job_id", "")

## Dónde tiene (o va a tener) su auto este encargo, sin el offset de
## espera — lo usa JobEncounterSpawner para ubicar el JobVehicle.
## Asigna el primer lugar libre la primera vez que se pregunta por un
## job_id nuevo, y lo recuerda mientras el encargo esté activo.
func get_job_spot_position(job_id: String) -> Vector2:
	var index := _spot_index_for_job(job_id)
	if index == -1:
		return _garage_door_position
	return _garage_spot_positions[index]

## Lo llama JobEncounterSpawner cuando el auto de un encargo ya se fue
## (retiro completado) o el encargo venció — libera el lugar para otro.
func release_job_spot(job_id: String) -> void:
	_job_spots.erase(job_id)

func _spot_index_for_job(job_id: String) -> int:
	if _job_spots.has(job_id):
		return _job_spots[job_id]

	for i in _garage_spot_positions.size():
		if not _job_spots.values().has(i):
			_job_spots[job_id] = i
			return i

	return -1  # no debería pasar con pocos encargos simultáneos

# --- Comandos ------------------------------------------------------------

## Lo llama JobsManager al aceptar un encargo, o al avisar al vendedor
## para el retiro — el NPC corta lo que esté haciendo (patrullando
## donde sea) y arranca camino al taller desde donde esté, por su
## propia ruta, tarde lo que tarde.
func summon_to_workshop(npc_id: String, job_id: String) -> void:
	var state: Dictionary = _npc_state.get(npc_id, {})
	if state.is_empty():
		return

	state.mode = "to_workshop"
	state.job_id = job_id
	state.dir = -1

func _start_entering_garage(_npc_id: String, state: Dictionary) -> void:
	var waiting_point: Vector2 = get_job_spot_position(state.job_id) + WAITING_OFFSET

	state.points = [_garage_door_position, waiting_point]
	state.index = 1
	state.dir = 1
	state.position = _garage_door_position
	state.mode = "entering_garage"

func _on_arrived_at_car(npc_id: String, state: Dictionary) -> void:
	state.mode = "waiting_at_door"
	npc_arrived_at_workshop.emit(npc_id, state.job_id)

## Lo llama JobEncounterSpawner apenas termina el diálogo del encuentro
## (entrega o retiro) — el encargo ya quedó resuelto en Game.state en
## ese momento, esto solo hace que el NPC se vea volviendo a la puerta
## antes de retomar su rutina, tarde lo que tarde, se lo vea o no.
func start_leaving_garage(npc_id: String) -> void:
	var state: Dictionary = _npc_state.get(npc_id, {})
	if state.is_empty():
		return

	state.points = [state.position, _garage_door_position]
	state.index = 1
	state.dir = 1
	state.mode = "leaving_garage"

## Lo llama JobEncounterSpawner cuando se completa un retiro — el NPC
## no se muestra en ningún mapa hasta que cambie el día (_on_day_changed
## lo devuelve solo a "patrol"). El enfriamiento de qué trabajos ofrece
## después es cosa de Game.state (ver JobsManager.finish_pickup), no de
## este autoload.
func go_off_duty(npc_id: String) -> void:
	_release_route(npc_id)

	_npc_state[npc_id] = {
		"route": "",
		"points": [],
		"index": 0,
		"dir": 1,
		"position": Vector2.ZERO,
		"mode": "off_duty",
		"job_id": "",
		"nav_path": [],
	}

func _on_day_changed(_day: int) -> void:
	for npc_id in _npc_state.keys():
		if _npc_state[npc_id].mode == "off_duty":
			resume_patrol(npc_id)

## Ciclo diario de casa: a HEAD_HOME_HOUR, cualquier NPC patrullando
## tranquilo corta camino a su casa; a su wake_hour (por NPC), el que
## está en casa sale hacia la ruta del día. Un encargo en curso tiene
## prioridad — esto nunca interrumpe "to_workshop"/"entering_garage"/
## "waiting_at_door"/"leaving_garage", solo agarra a los que ya estén
## en "patrol", así que ni bien vuelven de un encargo tarde, el próximo
## minuto los manda para casa igual si ya pasó la hora.
func _on_minute_changed(_hour: int, _minute: int) -> void:
	var minute_of_day := fmod(TimeManager.get_total_minutes(), TimeManager.MINUTES_PER_DAY)

	for npc_id in NpcRoster.ALL:
		if not _homes.has(npc_id):
			continue  # sin casa configurada todavía -- sigue patrullando sin ciclo de día/noche

		var state: Dictionary = _npc_state.get(npc_id, {})
		if state.is_empty():
			print("[NPC] %s: sin estado (nunca se inicializó) — minute_of_day=%.1f" % [_log_name(npc_id), minute_of_day])
			continue

		if state.mode == "patrol" and minute_of_day >= HEAD_HOME_HOUR * 60.0:
			print("[NPC] %s: son las %s, corta patrulla y va para casa" % [_log_name(npc_id), _fmt_minute(minute_of_day)])
			_start_heading_home(npc_id, state)
		elif state.mode == "at_home" and _is_awake_hour(minute_of_day, _home_wake_hours[npc_id]):
			print("[NPC] %s: son las %s, se despierta y sale para una ruta" % [_log_name(npc_id), _fmt_minute(minute_of_day)])
			_start_heading_to_route(npc_id, state)
		else:
			print("[NPC] %s: hora=%s modo=%s (nada que hacer)" % [_log_name(npc_id), _fmt_minute(minute_of_day), state.mode])

## Lo llama el botón "Regresar a casa" de DebugBar — manda a todos los
## NPCs que estén patrullando tranquilos a su casa ya mismo, sin esperar
## a HEAD_HOME_HOUR. No interrumpe a los que estén en un encargo (mismo
## criterio que _on_minute_changed) ni a los que ya no tengan casa
## configurada.
func debug_send_all_home() -> void:
	for npc_id in NpcRoster.ALL:
		if not _homes.has(npc_id):
			continue

		var state: Dictionary = _npc_state.get(npc_id, {})
		if not state.is_empty() and state.mode == "patrol":
			_start_heading_home(npc_id, state)

func _log_name(npc_id: String) -> String:
	return "%s (%s)" % [NpcRoster.get_display_name(npc_id), npc_id]

func _fmt_minute(minute_of_day: float) -> String:
	var h := int(minute_of_day / 60.0)
	var m := int(minute_of_day) % 60
	return "%02d:%02d" % [h, m]

## A propósito NO es "¿es exactamente este minuto?" — así funciona sin
## importar cómo se llegue a esa hora (un minuto de juego a la vez en
## partida normal, o un salto directo con el reloj de debug que solo
## dispara minute_changed una vez, con el valor final).
func _is_awake_hour(minute_of_day: float, wake_hour: float) -> bool:
	return minute_of_day >= wake_hour * 60.0 and minute_of_day < HEAD_HOME_HOUR * 60.0

func _start_heading_home(npc_id: String, state: Dictionary) -> void:
	print("[NPC] %s: arranca a caminar a casa, desde %s hacia %s" % [_log_name(npc_id), state.position, _homes[npc_id]])
	_release_route(npc_id)

	state.route = ""
	state.points = [_homes[npc_id]]
	state.waits = []
	state.index = 0
	state.dir = 1
	state.mode = "to_home"
	state.wait_remaining = 0.0
	state._wait_consumed = false
	state.nav_path = []

## Elige una ruta al azar (nunca la del taller) y camina, con
## pathfinding real, hasta el punto de esa ruta más cercano a la
## casa — no arranca siempre desde b_point, sino de donde le quede más
## a mano. Si en ese instante no hay ninguna ruta libre, no hace nada:
## sigue "at_home" y se reintenta solo el próximo minuto.
func _start_heading_to_route(npc_id: String, state: Dictionary) -> void:
	var route_name := _reserve_random_route(npc_id)
	if route_name == "":
		print("[NPC] %s: se quiso despertar pero no había ninguna ruta libre, sigue en casa" % _log_name(npc_id))
		return

	var points: Array = _routes[route_name]
	var nearest_index := _nearest_point_index(points, _homes[npc_id])
	print("[NPC] %s: elige la ruta %s, va hacia el punto más cercano (índice %d)" % [_log_name(npc_id), route_name, nearest_index])

	state.route = route_name
	state.points = points
	state.waits = _route_waits[route_name]
	state.index = nearest_index
	state.dir = 1
	state.mode = "to_route"
	state.wait_remaining = 0.0
	state._wait_consumed = false
	state.nav_path = []

## El índice 0 (la puerta del taller) nunca es candidato — arrancar el
## día ahí no tiene sentido, es solo el destino de un encargo.
func _nearest_point_index(points: Array, from: Vector2) -> int:
	var best_index := 1
	var best_dist_sq := INF

	for i in range(1, points.size()):
		var dist_sq: float = points[i].distance_squared_to(from)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_index = i

	return best_index

## Lo llama _on_point_reached cuando el NPC termina de volver a la
## puerta tras un encargo — retoma su vida normal con una rutina nueva
## al azar. Arranca en el índice 0 (la puerta) porque ahí está parado
## de verdad en ese momento — así el primer paso lo camina normal hacia
## el índice 1 en vez de teletransportarse directo al b_point.
func resume_patrol(npc_id: String) -> void:
	_release_route(npc_id)

	var route_name := _reserve_random_route(npc_id)
	if route_name == "":
		return

	_npc_state[npc_id] = {
		"route": route_name,
		"points": _routes[route_name],
		"waits": _route_waits[route_name],
		"index": 0,
		"dir": 1,
		"position": _routes[route_name][0],
		"mode": "patrol",
		"job_id": "",
		"wait_remaining": 0.0,
		"_wait_consumed": false,
		"nav_path": [],
	}

# --- Simulación ------------------------------------------------------------

func _process(delta: float) -> void:
	for npc_id in _npc_state.keys():
		_step_npc(npc_id, delta)

func _step_npc(npc_id: String, delta: float) -> void:
	var state: Dictionary = _npc_state[npc_id]
	if state.mode in ["waiting_at_door", "off_duty", "at_home"]:
		return  # "waiting_at_door": lo maneja la escena del garage. "off_duty"/"at_home": no se mueve, no se muestra en ningún lado.

	if state.mode == "patrol" and state.wait_remaining > 0.0:
		# Parado en un NpcRouteWaitPoint — cuenta minutos de JUEGO, no
		# tiempo real (ver TimeManager._process, que usa esta misma cuenta).
		var minutes_per_second: float = TimeManager.MINUTES_PER_DAY / TimeManager.REAL_SECONDS_PER_DAY
		state.wait_remaining -= delta * minutes_per_second
		return

	if state.nav_path.is_empty():
		_begin_travel_to(state, state.points[state.index])

	var target: Vector2 = state.nav_path[0]
	var to_target: Vector2 = target - state.position
	var step_len: float = WALK_SPEED * delta

	if to_target.length() <= step_len:
		state.position = target
		state.nav_path.pop_front()
		if state.nav_path.is_empty():
			_on_point_reached(npc_id, state)
	else:
		state.position += to_target.normalized() * step_len

## Arma el tramo a caminar hasta target — con pathfinding real
## (NavigationServer2D) para los modos que se mueven por la ciudad
## ("patrol", "to_workshop", "to_home", "to_route" — ahí es donde hay un
## NavigationPolygon horneado), y en línea recta para el resto (los
## tramos del garage son saltos fijos de 2 puntos en un espacio chico,
## sin necesidad de navmesh ahí). Si no hay _nav_map válido o la
## consulta no devuelve nada, también cae en línea recta.
const CITY_NAV_MODES := ["patrol", "to_workshop", "to_home", "to_route"]

func _begin_travel_to(state: Dictionary, target: Vector2) -> void:
	if _nav_map == RID() or not state.mode in CITY_NAV_MODES:
		state.nav_path = [target]
		return

	var path: PackedVector2Array = NavigationServer2D.map_get_path(_nav_map, state.position, target, true)

	if path.size() > 1:
		state.nav_path = Array(path.slice(1))  # el primer punto es ~el origen mismo
	else:
		state.nav_path = [target]  # sin camino válido (ej. fuera del área horneada) -> línea recta igual

func _on_point_reached(npc_id: String, state: Dictionary) -> void:
	if state.mode == "to_workshop":
		if state.index == 0:
			_start_entering_garage(npc_id, state)
			return
		state.index -= 1
		return

	if state.mode == "entering_garage":
		_on_arrived_at_car(npc_id, state)
		return

	if state.mode == "leaving_garage":
		resume_patrol(npc_id)
		return

	if state.mode == "to_home":
		print("[NPC] %s: llegó a su casa, queda invisible hasta despertar" % _log_name(npc_id))
		state.mode = "at_home"
		return

	if state.mode == "to_route":
		print("[NPC] %s: llegó a su ruta del día (ruta=%s, índice=%d), arranca a patrullar" % [_log_name(npc_id), state.route, state.index])
		state.mode = "patrol"
		return

	# Si este punto tiene tiempo de espera configurado (NpcRouteWaitPoint)
	# y todavía no lo consumió en este paso por acá, se queda quieto —
	# _step_npc lo cuenta en minutos de juego antes de volver a llamar
	# a esta función una vez que termina.
	var wait: float = state.waits[state.index] if state.index < state.waits.size() else 0.0
	if wait > 0.0 and not state._wait_consumed:
		state.wait_remaining = wait
		state._wait_consumed = true
		return

	state._wait_consumed = false

	# Patrulla normal: rebota entre b_point (índice 1) y el punto final
	# de la ruta — el índice 0 (la puerta del taller) nunca es parte de
	# este ciclo, solo es destino cuando lo llaman (ver "to_workshop").
	var next_index: int = state.index + state.dir
	if next_index >= state.points.size():
		state.dir = -1
		next_index = state.points.size() - 2
	elif next_index < 1:
		state.dir = 1
		next_index = 1

	state.index = next_index
