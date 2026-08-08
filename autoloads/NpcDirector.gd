extends Node

## El "cerebro" de todos los NPCs del mundo (ver NpcRoster para la
## lista): dónde está cada uno, hacia dónde va, y en qué modo — corre
## todo el tiempo, sin importar qué mapa esté cargado. Las escenas
## (CityMap para verlos caminar, GarageMap para el encuentro puntual)
## solo leen este estado para mostrarlo; nunca son la fuente de verdad.
##
## Modos de un NPC:
## - "patrol": deambulando su rutina del día (rebota entre los puntos
##   de una ruta al azar, reservada solo para él — ver
##   _reserve_random_route).
## - "to_workshop": le aceptaron/le avisaron de un encargo — corta la
##   rutina y camina de vuelta por la MISMA ruta que ya tenía, hacia el
##   punto 0 (la puerta del taller), tarde lo que tarde.
## - "waiting_at_door": ya llegó a la puerta — de acá en más lo maneja
##   la escena del garage (ver JobEncounterSpawner), hasta que se llama
##   a resume_patrol().
##
## Rutas: se leen una sola vez de CityMap.tscn al arrancar (los grupos
## de Marker2D bajo "WanderRoutes", con "anchor_point_path" como punto
## 0 de todas), cargando esa escena en memoria sin necesidad de que
## esté en el árbol — así el simulador no depende de que ese mapa esté
## cargado nunca más.

## Debe coincidir con Client.gd (que reproduce visualmente este mismo
## movimiento cuando la escena está a la vista).
const WALK_SPEED := 40.0

const CITY_MAP_PATH := "res://scenes/city/CityMap.tscn"
const ROUTES_CONTAINER_NAME := "WanderRoutes"
const ANCHOR_NODE_PATH := "Map/outside_garage/PlayerSpawn"

## Emite cuando un NPC que iba camino al taller (por un encargo) llega
## a la puerta. JobEncounterSpawner escucha esto para arrancar el
## encuentro visual (si el garage está cargado en ese momento) o lo
## chequea al entrar (si llegó mientras no estabas).
signal npc_arrived_at_workshop(npc_id: String, job_id: String)

var _routes: Dictionary = {}  # route_name (String) -> Array[Vector2]
var _route_reservations: Dictionary = {}  # route_name (String) -> npc_id (String)
var _npc_state: Dictionary = {}  # npc_id (String) -> Dictionary (ver _init_npc)

func _ready() -> void:
	_load_routes()

	for npc_id in NpcRoster.ALL:
		_init_npc(npc_id)

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
			for point_node in route_node.get_children():
				points.append(point_node.global_position)

			if points.size() >= 2:
				_routes[route_node.name] = points

	city.free()

func _init_npc(npc_id: String) -> void:
	var route_name := _reserve_random_route(npc_id)
	if route_name == "":
		return  # no hay ninguna ruta cargada (revisá CityMap.tscn/WanderRoutes)

	_npc_state[npc_id] = {
		"route": route_name,
		"points": _routes[route_name],
		"index": 0,
		"dir": 1,
		"position": _routes[route_name][0],
		"mode": "patrol",
		"job_id": "",
	}

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

func _on_arrived_at_workshop(npc_id: String) -> void:
	var state: Dictionary = _npc_state[npc_id]
	state.mode = "waiting_at_door"
	npc_arrived_at_workshop.emit(npc_id, state.job_id)

## Lo llama JobEncounterSpawner cuando termina el encuentro visual (la
## entrega o el retiro) y el NPC "se va" — retoma su vida normal con
## una rutina nueva al azar, arrancando ya mismo, sin importar si hay
## alguien mirando.
func resume_patrol(npc_id: String) -> void:
	_release_route(npc_id)

	var route_name := _reserve_random_route(npc_id)
	if route_name == "":
		return

	_npc_state[npc_id] = {
		"route": route_name,
		"points": _routes[route_name],
		"index": 0,
		"dir": 1,
		"position": _routes[route_name][0],
		"mode": "patrol",
		"job_id": "",
	}

# --- Simulación ------------------------------------------------------------

func _process(delta: float) -> void:
	for npc_id in _npc_state.keys():
		_step_npc(npc_id, delta)

func _step_npc(npc_id: String, delta: float) -> void:
	var state: Dictionary = _npc_state[npc_id]
	if state.mode == "waiting_at_door":
		return  # de acá en más lo maneja la escena visual del garage

	var points: Array = state.points
	var target: Vector2 = points[state.index]
	var to_target: Vector2 = target - state.position
	var step_len: float = WALK_SPEED * delta

	if to_target.length() <= step_len:
		state.position = target
		_on_point_reached(npc_id, state)
	else:
		state.position += to_target.normalized() * step_len

func _on_point_reached(npc_id: String, state: Dictionary) -> void:
	if state.mode == "to_workshop":
		if state.index == 0:
			_on_arrived_at_workshop(npc_id)
			return
		state.index -= 1
		return

	# Patrulla normal: rebota entre los dos extremos de la ruta.
	var next_index: int = state.index + state.dir
	if next_index >= state.points.size():
		state.dir = -1
		next_index = state.points.size() - 2
	elif next_index < 0:
		state.dir = 1
		next_index = 1

	state.index = next_index
