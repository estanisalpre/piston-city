extends Node2D

## Conecta JobsManager con el mundo. Dos encuentros con el NPC:
##
## 1. Entrega: 30 min de juego después de aceptar, aparece el auto (con
##    fundido entrecortado) y el NPC camina hasta el lugar donde quedó
##    el auto y espera ahí — no persigue al jugador, lo espera. Cuando
##    el jugador se acerca a 32px, diálogo de llegada, se va — recién
##    ahí arranca el plazo de 7 días (JobsManager.start_job_clock).
## 2. Retiro: al tocar "Avisar al vendedor", según el horario del
##    taller (JobsManager._compute_pickup_arrival) vuelve el mismo tipo
##    de NPC, espera junto al auto, y cuando el jugador se acerca:
##    diálogo de agradecimiento, paga (JobsManager.finish_pickup),
##    camina hasta el auto y desaparece (no se muestra que sube), y
##    unos segundos después el auto se va con el mismo fundido, al revés.
##
## Ninguno de los dos encuentros depende de que el jugador ya esté
## parado en un punto exacto en el momento justo — el NPC llega y
## espera, sin importar cuándo aparezcas.
##
## Los Node de auto/NPC no persisten solos entre partidas — por eso al
## arrancar se reconstruyen los autos de los encargos que ya estaban en
## curso o esperando retiro (ver _restore_parked_vehicles). Si un
## retiro ya venció mientras el garage no estaba cargado, se dispara
## igual apenas carga — el NPC espera acá, no se resuelve solo.

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

var _queue: Array[Dictionary] = []  # {type: "deliver"|"pickup", job_id: String}
var _pickup_enqueued: Dictionary = {}  # job_id -> true, evita re-encolar cada minuto
var _busy := false
var _occupied_spots: Dictionary = {}  # spot_index (int) -> job_id (String)
var _job_vehicles: Dictionary = {}  # job_id (String) -> vehicle instance

func _ready() -> void:
	JobsManager.job_expired.connect(_free_job_vehicle)
	JobsManager.jobs_cleared.connect(_reset)
	TimeManager.minute_changed.connect(_on_minute_changed)
	_restore_parked_vehicles()

## El Node del auto no se guarda solo — Game.state sí persistió qué
## encargos están en curso o esperando retiro, así que los recreamos
## acá. Si algún retiro ya venció mientras el garage no estaba cargado,
## dispara el encuentro (el NPC espera, no resuelve nada en silencio).
func _restore_parked_vehicles() -> void:
	for job_id in Game.state.active_jobs.keys():
		if Game.state.active_jobs[job_id] != JobsManager.RESERVED:
			_ensure_vehicle_exists(job_id)

	var now := TimeManager.get_total_minutes()
	for job_id in Game.state.pending_pickups.keys():
		_ensure_vehicle_exists(job_id)

		if now >= Game.state.pending_pickups[job_id] and not _pickup_enqueued.has(job_id):
			_pickup_enqueued[job_id] = true
			_queue.append({"type": "pickup", "job_id": job_id})

	_process_queue()

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

func _on_minute_changed(_hour: int, _minute: int) -> void:
	var now := TimeManager.get_total_minutes()
	var has_new_items := false

	var ready_deliveries: Array[String] = []
	for job_id in Game.state.scheduled_deliveries.keys():
		if now >= Game.state.scheduled_deliveries[job_id]:
			ready_deliveries.append(job_id)
	for job_id in ready_deliveries:
		Game.state.scheduled_deliveries.erase(job_id)
		_queue.append({"type": "deliver", "job_id": job_id})
		has_new_items = true

	var ready_pickups: Array[String] = []
	for job_id in Game.state.pending_pickups.keys():
		if now >= Game.state.pending_pickups[job_id] and not _pickup_enqueued.has(job_id):
			ready_pickups.append(job_id)
	for job_id in ready_pickups:
		_pickup_enqueued[job_id] = true
		_queue.append({"type": "pickup", "job_id": job_id})
		has_new_items = true

	if has_new_items:
		_process_queue()

func _process_queue() -> void:
	if _busy or _queue.is_empty():
		return

	var item: Dictionary = _queue[0]

	if item.type == "deliver":
		var spot_index := _find_free_spot()
		if spot_index == -1:
			return  # no hay lugar libre todavía; se reintenta cuando se libere uno

		_queue.pop_front()
		_busy = true
		_run_delivery_encounter(item.job_id, spot_index)
	else:
		_queue.pop_front()
		_busy = true
		_run_pickup_encounter(item.job_id)

func _spot_position_for_job(job_id: String) -> Variant:
	for spot_index in _occupied_spots.keys():
		if _occupied_spots[spot_index] == job_id:
			var spot: Node2D = get_node(parking_spots[spot_index])
			return spot.global_position
	return null

# --- Entrega ---------------------------------------------------------

func _run_delivery_encounter(job_id: String, spot_index: int) -> void:
	Game.state.npc_busy_in_garage[job_id] = true

	var vehicle := _spawn_vehicle_at(job_id, spot_index)
	vehicle.play_arrival_fade()

	var spawn_point: Node2D = get_node(client_spawn_point)
	var client: CharacterBody2D = client_scene.instantiate()
	add_child(client)
	client.global_position = spawn_point.global_position

	client.arrived.connect(client.wait_for_player, CONNECT_ONE_SHOT)
	client.player_approached.connect(
		_on_delivery_client_approached.bind(client, spawn_point, job_id), CONNECT_ONE_SHOT
	)
	client.walk_to(vehicle.global_position + WAITING_OFFSET)

func _on_delivery_client_approached(client: CharacterBody2D, spawn_point: Node2D, job_id: String) -> void:
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

	client.arrived.connect(_on_delivery_client_left.bind(client, job_id), CONNECT_ONE_SHOT)
	client.walk_to(spawn_point.global_position)

func _on_delivery_client_left(client: CharacterBody2D, job_id: String) -> void:
	client.queue_free()
	Game.state.npc_busy_in_garage.erase(job_id)
	JobsManager.start_job_clock(job_id)

	_busy = false
	_process_queue()

# --- Retiro ------------------------------------------------------------

func _run_pickup_encounter(job_id: String) -> void:
	Game.state.npc_busy_in_garage[job_id] = true

	var spawn_point: Node2D = get_node(client_spawn_point)
	var client: CharacterBody2D = client_scene.instantiate()
	add_child(client)
	client.global_position = spawn_point.global_position

	var vehicle_spot_position: Variant = _spot_position_for_job(job_id)
	var waiting_point: Vector2 = (
		vehicle_spot_position + WAITING_OFFSET if vehicle_spot_position != null
		else spawn_point.global_position
	)

	client.arrived.connect(client.wait_for_player, CONNECT_ONE_SHOT)
	client.player_approached.connect(
		_on_pickup_client_approached.bind(client, spawn_point, job_id), CONNECT_ONE_SHOT
	)
	client.walk_to(waiting_point)

func _on_pickup_client_approached(client: CharacterBody2D, spawn_point: Node2D, job_id: String) -> void:
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

	client.arrived.connect(_on_pickup_client_left.bind(client, job_id), CONNECT_ONE_SHOT)
	client.walk_to(walk_target)

## Al llegar al auto, el cliente "se sube" sin que lo mostremos —
## simplemente desaparece — y unos segundos después el auto se va.
func _on_pickup_client_left(client: CharacterBody2D, job_id: String) -> void:
	client.queue_free()
	Game.state.npc_busy_in_garage.erase(job_id)
	_pickup_enqueued.erase(job_id)  # recién ahora está resuelto de verdad

	await get_tree().create_timer(POST_PICKUP_WAIT_SECONDS).timeout

	var vehicle: Node2D = _job_vehicles.get(job_id)
	if vehicle:
		_job_vehicles.erase(job_id)
		_free_spot_for_job(job_id)
		vehicle.play_departure_fade()  # se autodestruye al terminar el fundido

	_busy = false
	_process_queue()

# --- Debug / vencimiento ------------------------------------------------

## Debug: borra cualquier auto/NPC que haya spawneado, la cola de
## espera y las llegadas/retiros programados, para que el estado del
## mundo quede igual de limpio que el de Game.state tras
## JobsManager.clear_all_jobs().
func _reset() -> void:
	for child in get_children():
		child.queue_free()

	_queue.clear()
	_pickup_enqueued.clear()
	_occupied_spots.clear()
	_job_vehicles.clear()
	_busy = false
	Game.state.npc_busy_in_garage.clear()

func _free_job_vehicle(job_id: String) -> void:
	var vehicle: Node2D = _job_vehicles.get(job_id)
	if vehicle:
		vehicle.queue_free()
		_job_vehicles.erase(job_id)

	_free_spot_for_job(job_id)
	_process_queue()

func _free_spot_for_job(job_id: String) -> void:
	for spot_index in _occupied_spots.keys():
		if _occupied_spots[spot_index] == job_id:
			_occupied_spots.erase(spot_index)
			break
