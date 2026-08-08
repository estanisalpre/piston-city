extends Node2D

## Conecta NpcDirector con la escena del garage. Cuando el NPC de un
## encargo llega a la puerta del taller (NpcDirector.npc_arrived_at_workshop
## — que se dispara sin importar qué mapa esté cargado en ese momento),
## corre el encuentro visual correspondiente:
##
## 1. Entrega: aparece el auto (con fundido entrecortado) y el NPC
##    camina hasta el auto y espera ahí — no persigue al jugador, lo
##    espera. Cuando el jugador se acerca a 32px: diálogo de llegada,
##    se va — recién ahí arranca el plazo de 7 días
##    (JobsManager.start_job_clock) y NpcDirector lo pone de vuelta a
##    patrullar, ya mismo.
## 2. Retiro: si el taller está en horario, el mismo NPC espera junto
##    al auto igual que en la entrega. Cuando el jugador se acerca:
##    diálogo de agradecimiento, paga (JobsManager.finish_pickup),
##    camina hasta el auto y desaparece (no se muestra que sube), y
##    unos segundos después el auto se va con el mismo fundido, al
##    revés — y NpcDirector lo pone de vuelta a patrullar.
##
## Si el NPC llega mientras este garage no estaba cargado, o llega
## fuera de horario para un retiro, se queda esperando en NpcDirector
## (modo "waiting_at_door") — al cargar esta escena (o en el próximo
## chequeo de horario) se retoma el encuentro, nunca se resuelve solo.

const POST_PICKUP_WAIT_SECONDS := 3.0

## Offset desde el auto donde el NPC se para a esperar (no encima del
## sprite del vehículo).
const WAITING_OFFSET := Vector2(0, 24)

const PICKUP_GREETINGS := [
	["Qué bueno que pudiste arreglarlo.", "Gracias, acá está tu pago."],
	["Perfecto, justo lo que necesitaba.", "Te dejo la plata, ya me lo llevo."],
	["Excelente trabajo, se nota.", "Acá tenés, muchas gracias."],
]

@export var parking_spots: Array[NodePath] = []
@export var client_spawn_point: NodePath
@export var vehicle_scene: PackedScene
@export var client_scene: PackedScene

var _pending_arrivals: Array[Dictionary] = []  # {npc_id, job_id}, en el orden en que llegaron
var _busy := false
var _occupied_spots: Dictionary = {}  # spot_index (int) -> job_id (String)
var _job_vehicles: Dictionary = {}  # job_id (String) -> vehicle instance

func _ready() -> void:
	JobsManager.job_expired.connect(_free_job_vehicle)
	JobsManager.jobs_cleared.connect(_reset)
	NpcDirector.npc_arrived_at_workshop.connect(_on_npc_arrived_at_workshop)
	TimeManager.minute_changed.connect(_on_minute_changed)  # para reintentar cuando abre el taller

	_restore_parked_vehicles()
	_restore_waiting_arrivals()

## El Node del auto no se guarda solo — Game.state sí persistió qué
## encargos están en curso o esperando retiro, así que los recreamos acá.
func _restore_parked_vehicles() -> void:
	for job_id in Game.state.active_jobs.keys():
		if Game.state.active_jobs[job_id] != JobsManager.RESERVED:
			_ensure_vehicle_exists(job_id)

	for job_id in Game.state.pending_pickups.keys():
		_ensure_vehicle_exists(job_id)

## Si algún NPC ya estaba parado en la puerta (llegó mientras este
## garage no estaba cargado), retoma el encuentro ahora.
func _restore_waiting_arrivals() -> void:
	for npc_id in NpcRoster.ALL:
		if NpcDirector.get_mode(npc_id) == "waiting_at_door":
			var job_id := NpcDirector.get_job_id(npc_id)
			if job_id != "":
				_queue_arrival(npc_id, job_id)

	_process_pending_arrivals()

func _ensure_vehicle_exists(job_id: String) -> void:
	if _job_vehicles.has(job_id):
		return

	var spot_index := _find_free_spot()
	if spot_index == -1:
		return

	var vehicle := _spawn_vehicle_at(job_id, spot_index)
	vehicle.show_parked()

func _spawn_vehicle_at(job_id: String, spot_index: int) -> Node2D:
	var spot: Node2D = get_node(parking_spots[spot_index])
	var vehicle: Node2D = vehicle_scene.instantiate()
	vehicle.job_id = job_id
	add_child(vehicle)
	vehicle.global_position = spot.global_position

	_occupied_spots[spot_index] = job_id
	_job_vehicles[job_id] = vehicle
	return vehicle

func _find_free_spot() -> int:
	for i in parking_spots.size():
		if not _occupied_spots.has(i):
			return i
	return -1

func _spot_position_for_job(job_id: String) -> Variant:
	for spot_index in _occupied_spots.keys():
		if _occupied_spots[spot_index] == job_id:
			var spot: Node2D = get_node(parking_spots[spot_index])
			return spot.global_position
	return null

func _on_npc_arrived_at_workshop(npc_id: String, job_id: String) -> void:
	_queue_arrival(npc_id, job_id)
	_process_pending_arrivals()

## Reintenta la cola cada minuto de juego — hace falta para el caso de
## un retiro que llegó fuera de horario: el NPC ya está parado en la
## puerta (NpcDirector), solo falta que abra el taller.
func _on_minute_changed(_hour: int, _minute: int) -> void:
	_process_pending_arrivals()

func _queue_arrival(npc_id: String, job_id: String) -> void:
	for item in _pending_arrivals:
		if item.npc_id == npc_id:
			return  # ya está en la cola

	_pending_arrivals.append({"npc_id": npc_id, "job_id": job_id})

func _process_pending_arrivals() -> void:
	if _busy or _pending_arrivals.is_empty():
		return

	var item: Dictionary = _pending_arrivals[0]
	var job_id: String = item.job_id
	var npc_id: String = item.npc_id
	var is_pickup := Game.state.pending_pickups.has(job_id)

	if is_pickup:
		if not JobsManager.is_shop_open_now():
			return  # espera parado en la puerta a que abra; se reintenta cada minuto

		_pending_arrivals.pop_front()
		_busy = true
		_run_pickup_encounter(npc_id, job_id)
		return

	var spot_index := _find_free_spot()
	if spot_index == -1:
		return  # no hay lugar libre todavía; se reintenta cuando se libere uno

	_pending_arrivals.pop_front()
	_busy = true
	_run_delivery_encounter(npc_id, job_id, spot_index)

# --- Entrega ---------------------------------------------------------

func _run_delivery_encounter(npc_id: String, job_id: String, spot_index: int) -> void:
	var vehicle := _spawn_vehicle_at(job_id, spot_index)
	vehicle.play_arrival_fade()

	var spawn_point: Node2D = get_node(client_spawn_point)
	var client: CharacterBody2D = client_scene.instantiate()
	add_child(client)
	client.set_appearance(NpcRoster.get_texture(npc_id))
	client.global_position = spawn_point.global_position
	client.job_id = job_id

	client.arrived.connect(client.wait_for_player, CONNECT_ONE_SHOT)
	client.player_approached.connect(
		_on_delivery_client_approached.bind(client, spawn_point, npc_id, job_id), CONNECT_ONE_SHOT
	)
	client.walk_to(vehicle.global_position + WAITING_OFFSET)

func _on_delivery_client_approached(
	client: CharacterBody2D, spawn_point: Node2D, npc_id: String, job_id: String
) -> void:
	var job := JobsRepository.get_job(job_id)
	var job_title := job.title if job else "el trabajo"

	var lines: Array[String] = [
		"Hola, disculpa la demora.",
		"Te traje el auto para que le hagas: \"%s\"." % job_title,
		"Quedo por acá cerca, avisame cuando esté listo.",
	]

	var dialogue := get_tree().get_first_node_in_group("dialogue_modal")
	dialogue.show_lines(lines)
	await dialogue.finished

	client.arrived.connect(_on_delivery_client_left.bind(client, npc_id, job_id), CONNECT_ONE_SHOT)
	client.walk_to(spawn_point.global_position)

func _on_delivery_client_left(client: CharacterBody2D, npc_id: String, job_id: String) -> void:
	client.queue_free()
	JobsManager.start_job_clock(job_id)
	NpcDirector.resume_patrol(npc_id)  # sigue su vida ya mismo, se vea o no

	_busy = false
	_process_pending_arrivals()

# --- Retiro ------------------------------------------------------------

func _run_pickup_encounter(npc_id: String, job_id: String) -> void:
	var spawn_point: Node2D = get_node(client_spawn_point)
	var client: CharacterBody2D = client_scene.instantiate()
	add_child(client)
	client.set_appearance(NpcRoster.get_texture(npc_id))
	client.global_position = spawn_point.global_position
	client.job_id = job_id

	var vehicle_spot_position: Variant = _spot_position_for_job(job_id)
	var waiting_point: Vector2 = (
		vehicle_spot_position + WAITING_OFFSET if vehicle_spot_position != null
		else spawn_point.global_position
	)

	client.arrived.connect(client.wait_for_player, CONNECT_ONE_SHOT)
	client.player_approached.connect(
		_on_pickup_client_approached.bind(client, spawn_point, npc_id, job_id), CONNECT_ONE_SHOT
	)
	client.walk_to(waiting_point)

func _on_pickup_client_approached(
	client: CharacterBody2D, spawn_point: Node2D, npc_id: String, job_id: String
) -> void:
	var greeting: Array = PICKUP_GREETINGS[randi() % PICKUP_GREETINGS.size()]
	var lines: Array[String] = []
	for line in greeting:
		lines.append(line)

	var dialogue := get_tree().get_first_node_in_group("dialogue_modal")
	dialogue.show_lines(lines)
	await dialogue.finished

	JobsManager.finish_pickup(job_id)

	var vehicle_spot_position: Variant = _spot_position_for_job(job_id)
	var walk_target: Vector2 = vehicle_spot_position if vehicle_spot_position != null else spawn_point.global_position

	client.arrived.connect(_on_pickup_client_left.bind(client, npc_id, job_id), CONNECT_ONE_SHOT)
	client.walk_to(walk_target)

## Al llegar al auto, el cliente "se sube" sin que lo mostremos —
## simplemente desaparece — y unos segundos después el auto se va.
func _on_pickup_client_left(client: CharacterBody2D, npc_id: String, job_id: String) -> void:
	client.queue_free()

	await get_tree().create_timer(POST_PICKUP_WAIT_SECONDS).timeout

	var vehicle: Node2D = _job_vehicles.get(job_id)
	if vehicle:
		_job_vehicles.erase(job_id)
		_free_spot_for_job(job_id)
		vehicle.play_departure_fade()  # se autodestruye al terminar el fundido

	NpcDirector.resume_patrol(npc_id)  # sigue su vida ya mismo, se vea o no

	_busy = false
	_process_pending_arrivals()

# --- Debug / vencimiento ------------------------------------------------

## Debug: borra cualquier auto/NPC que haya spawneado y la cola de
## llegadas, para que el estado del mundo quede igual de limpio que el
## de Game.state tras JobsManager.clear_all_jobs().
func _reset() -> void:
	for child in get_children():
		child.queue_free()

	_pending_arrivals.clear()
	_occupied_spots.clear()
	_job_vehicles.clear()
	_busy = false

func _free_job_vehicle(job_id: String) -> void:
	var vehicle: Node2D = _job_vehicles.get(job_id)
	if vehicle:
		vehicle.queue_free()
		_job_vehicles.erase(job_id)

	_free_spot_for_job(job_id)
	_process_pending_arrivals()

func _free_spot_for_job(job_id: String) -> void:
	for spot_index in _occupied_spots.keys():
		if _occupied_spots[spot_index] == job_id:
			_occupied_spots.erase(spot_index)
			break
