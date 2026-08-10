extends Node2D

## Conecta NpcDirector con la escena del garage. El movimiento del NPC
## (afuera y adentro del garage, incluyendo la caminata de vuelta a la
## puerta al terminar) siempre lo calcula NpcDirector, exista o no esta
## escena — este script solo lo refleja:
##
## - Mientras el NPC está en modo "entering_garage", "waiting_at_door"
##   o "leaving_garage" (ver NpcDirector), acá se muestra un Client en
##   modo espejo (caminando) o parado esperando al jugador, según
##   corresponda. Si el NPC ya venía en alguno de esos tramos antes de
##   que esta escena existiera, aparece tal cual está, sin repetir
##   ninguna animación desde cero. Al volver a "patrol" (ya afuera),
##   el Client se borra solo.
## - El auto del encargo (JobVehicle) se crea la primera vez que se lo
##   necesita, en el lugar que NpcDirector le asignó a ese job_id, y
##   sigue existiendo (Game.state.active_jobs/pending_pickups) aunque
##   se recargue el garage.
##
## Encuentro (entrega o retiro): cuando el jugador se acerca a 32px del
## NPC que espera, se dispara el diálogo correspondiente. En cuanto
## termina, el encargo queda resuelto de una — JobsManager.start_job_clock
## o finish_pickup — antes de cualquier animación de salida, así que el
## encargo nunca queda "a medio resolver" si el jugador sale del garage
## antes de que termine:
## - Entrega: el NPC vuelve caminando a la puerta (NpcDirector.
##   start_leaving_garage) — puramente cosmético, se ve o no.
## - Retiro: el NPC se sube al auto (desaparece ahí mismo, no camina a
##   la puerta) y unos segundos después el auto se va con el fundido —
##   también puramente cosmético. Además queda "de franco"
##   (NpcDirector.go_off_duty) hasta el otro día: no tiene sentido que
##   lo cruces caminando el mismo día que te devolvió el auto.

const POST_PICKUP_WAIT_SECONDS := 3.0

const VISIBLE_MODES := ["entering_garage", "waiting_at_door", "leaving_garage"]
const MIRRORED_MODES := ["entering_garage", "leaving_garage"]

const PICKUP_GREETINGS := [
	["Qué bueno que pudiste arreglarlo.", "Gracias, acá está tu pago."],
	["Perfecto, justo lo que necesitaba.", "Te dejo la plata, ya me lo llevo."],
	["Excelente trabajo, se nota.", "Acá tenés, muchas gracias."],
]

## Estas dos exports las sigue leyendo NpcDirector (instanciando esta
## escena en memoria, sin agregarla al árbol) para saber dónde está la
## puerta y los lugares de estacionamiento — es la única razón por la
## que siguen viviendo acá y no se leen directo en este script.
@export var parking_spots: Array[NodePath] = []
@export var client_spawn_point: NodePath
@export var vehicle_scene: PackedScene
@export var client_scene: PackedScene

var _clients: Dictionary = {}  # npc_id (String) -> {client: Node, phase: String}
var _job_vehicles: Dictionary = {}  # job_id (String) -> vehicle instance

func _ready() -> void:
	JobsManager.job_expired.connect(_free_job_vehicle)
	JobsManager.jobs_cleared.connect(_reset)

	_restore_parked_vehicles()

## El Node del auto no se guarda solo — Game.state sí persistió qué
## encargos están en curso o esperando retiro, así que los recreamos acá.
func _restore_parked_vehicles() -> void:
	for job_id in Game.state.active_jobs.keys():
		if Game.state.active_jobs[job_id] != JobsManager.RESERVED:
			_ensure_vehicle_exists(job_id, false)

	for job_id in Game.state.pending_pickups.keys():
		_ensure_vehicle_exists(job_id, false)

func _process(_delta: float) -> void:
	for npc_id in NpcRoster.ALL:
		var mode := NpcDirector.get_mode(npc_id)
		var job_id := NpcDirector.get_job_id(npc_id)

		if VISIBLE_MODES.has(mode) and job_id != "":
			_sync_client(npc_id, job_id, mode)
		elif _clients.has(npc_id):
			_despawn_client(npc_id)

func _sync_client(npc_id: String, job_id: String, mode: String) -> void:
	var first_sighting := not _clients.has(npc_id)
	if first_sighting:
		_spawn_client(npc_id, job_id)
		# Recién ahora vemos a este auto por primera vez esta carga del
		# garage: si el NPC todavía está entrando, es la llegada en vivo
		# (fundido); si ya estaba esperando, ya estaba ahí hace rato.
		_ensure_vehicle_exists(job_id, mode == "entering_garage")

	var entry: Dictionary = _clients[npc_id]
	if entry.phase == mode:
		return  # ya está en la fase correcta, no repetir la transición

	entry.phase = mode
	if mode == "waiting_at_door":
		entry.client.stop_mirroring()
		entry.client.global_position = NpcDirector.get_position(npc_id)
		entry.client.player_approached.connect(
			_on_client_approached.bind(npc_id, job_id), CONNECT_ONE_SHOT
		)
		entry.client.wait_for_player()
	elif MIRRORED_MODES.has(mode):
		entry.client.mirror_npc(npc_id)

func _spawn_client(npc_id: String, job_id: String) -> void:
	var client: CharacterBody2D = client_scene.instantiate()
	add_child(client)
	client.set_appearance(NpcRoster.get_texture(npc_id))
	client.job_id = job_id
	_clients[npc_id] = {"client": client, "phase": ""}

func _despawn_client(npc_id: String) -> void:
	_clients[npc_id].client.queue_free()
	_clients.erase(npc_id)

func _ensure_vehicle_exists(job_id: String, arriving: bool) -> void:
	if _job_vehicles.has(job_id):
		return

	var vehicle: Node2D = vehicle_scene.instantiate()
	vehicle.job_id = job_id
	add_child(vehicle)
	vehicle.global_position = NpcDirector.get_job_spot_position(job_id)
	_job_vehicles[job_id] = vehicle

	if arriving:
		vehicle.play_arrival_fade()
	else:
		vehicle.show_parked()

# --- Encuentro (diálogo) -------------------------------------------------

func _on_client_approached(npc_id: String, job_id: String) -> void:
	if Game.state.pending_pickups.has(job_id):
		_run_pickup_dialogue(npc_id, job_id)
	else:
		_run_delivery_dialogue(npc_id, job_id)

func _run_delivery_dialogue(npc_id: String, job_id: String) -> void:
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

	JobsManager.start_job_clock(job_id)
	NpcDirector.start_leaving_garage(npc_id)  # vuelve a la puerta, se vea o no
	# El auto se queda estacionado, esperando a que lo entregues.

func _run_pickup_dialogue(npc_id: String, job_id: String) -> void:
	var greeting: Array = PICKUP_GREETINGS[randi() % PICKUP_GREETINGS.size()]
	var lines: Array[String] = []
	for line in greeting:
		lines.append(line)

	var dialogue := get_tree().get_first_node_in_group("dialogue_modal")
	dialogue.show_lines(lines)
	await dialogue.finished

	JobsManager.finish_pickup(job_id)
	NpcDirector.go_off_duty(npc_id)  # se sube al auto y no vuelve hasta el otro día
	NpcDirector.release_job_spot(job_id)  # el lugar queda libre ya mismo
	_depart_vehicle(job_id)

## El auto se va con el fundido entrecortado al revés, unos segundos
## después de pagado — puramente cosmético: si el jugador sale del
## garage antes de que termine, el auto simplemente desaparece con la
## escena (el encargo ya quedó resuelto arriba, antes de este await).
func _depart_vehicle(job_id: String) -> void:
	await get_tree().create_timer(POST_PICKUP_WAIT_SECONDS).timeout

	var vehicle: Node2D = _job_vehicles.get(job_id)
	if vehicle:
		_job_vehicles.erase(job_id)
		vehicle.play_departure_fade()  # se autodestruye al terminar el fundido

# --- Debug / vencimiento ------------------------------------------------

## Debug: borra cualquier auto/NPC que haya spawneado, para que el
## estado del mundo quede igual de limpio que el de Game.state tras
## JobsManager.clear_all_jobs().
func _reset() -> void:
	for job_id in _job_vehicles.keys():
		NpcDirector.release_job_spot(job_id)

	for child in get_children():
		child.queue_free()

	_clients.clear()
	_job_vehicles.clear()

func _free_job_vehicle(job_id: String) -> void:
	var vehicle: Node2D = _job_vehicles.get(job_id)
	if vehicle:
		vehicle.queue_free()
		_job_vehicles.erase(job_id)

	NpcDirector.release_job_spot(job_id)
