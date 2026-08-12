extends Area2D

## Pieza desmontable de un auto (rueda, y a futuro espejo/vidrio/etc)
## — reusable: instanciarlo como hijo directo del auto (ver
## sistema-vehiculos.md), con su propio Sprite2D hijo llamado
## "Sprite2D" y un CollisionShape2D ajustado para cubrir justo esa
## pieza (no todo el lienzo del auto, que es transparente alrededor).
## Un solo script sirve para cualquier pieza de cualquier auto — no
## sabe nada de "auto" en particular, ni de neumáticos específicamente.
##
## Click izquierdo: si la pieza está puesta, la saca (con minijuego si
## corresponde) y la carga (ver PlayerCarry); si está sacada, la pone
## de nuevo si el jugador carga la pieza correcta.
##
## El progreso se guarda en Game.state.job_repair_progress, con clave
## "<job_id>:<slot_id>" (un mismo auto puede tener varias piezas
## desmontables, cada una con su propio progreso) — así sobrevive un
## guardado/cargado, igual que el resto de la reparación.

@export var slot_id: String = ""

## part_id que pasa a cargar el jugador al sacarla, y el que tiene que
## estar cargando para poder ponerla — separados por si algún día una
## pieza usada y una nueva no son intercambiables 1 a 1.
@export var removed_part_id: String = "neumatico_usado"
@export var install_part_id: String = "neumatico"
@export var carry_icon: Texture2D

## Vacío = se saca directo, sin minijuego (ej. un espejo a futuro).
@export var remove_sequence: Array[String] = ["B", "C", "B"]

## Textura a mostrar en vez de la normal mientras esta pieza esté
## "dañada" para el job activo (ver JobData.damaged_slots) y todavía no
## se haya cambiado. Vacío = nunca se ve distinta a la que ya tiene el
## Sprite2D puesta en la escena.
@export var damaged_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

## El auto siempre instancia esta pieza como hijo suyo directo (ver
## JobVehicle.gd) — de ahí sacamos el job_id.
@onready var vehicle: Node = get_parent()

var _healthy_texture: Texture2D

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	_healthy_texture = sprite.texture
	refresh_visual()

## Vuelve a calcular textura/visibilidad desde Game.state.job_repair_progress
## — además de _ready(), lo llama JobVehicle.advance_round() cuando un
## job de varias tandas (ver JobData.repair_rounds) resetea el progreso
## para la tanda siguiente, así esta pieza "vuelve a ensuciarse" sin
## tener que recargar la escena.
func refresh_visual() -> void:
	sprite.visible = _stage() != "removed"
	sprite.texture = damaged_texture if (_stage() == "" and damaged_texture and _is_damaged()) else _healthy_texture

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	get_viewport().set_input_as_handled()

	if not Game.state.active_jobs.has(vehicle.job_id):
		# Ya se avisó al vendedor (o ya se completó) — el auto es del
		# cliente a partir de acá, no se le toca más nada, esté todavía
		# esperando el retiro o yéndose con el fundido.
		_show_message("Este vehículo ya está entregado, no hay nada más que hacerle.")
		return

	if sprite.visible:
		if not _is_required():
			_show_message("Este neumático no necesita cambio...")
			return
		_start_remove()
	else:
		_try_install()

func _start_remove() -> void:
	if PlayerCarry.is_carrying():
		_show_message("Ya tenés algo en las manos — dejalo en algún lado primero.")
		return

	if remove_sequence.is_empty():
		_finish_remove()
		return

	var minigame := get_tree().get_first_node_in_group("button_sequence_minigame")
	minigame.start(remove_sequence)

	var success: bool = await minigame.finished
	if success:
		_finish_remove()

func _finish_remove() -> void:
	# Lo que se saca es lo que estaba puesto de verdad: si ya se había
	# instalado la pieza nueva antes, es esa la que se lleva el
	# jugador — no siempre "la usada" (ver bug: sacar una pieza nueva
	# la devolvía como usada y después no dejaba volver a ponerla).
	var mounted_part_id := install_part_id if _stage() == "installed" else removed_part_id
	PlayerCarry.carry(mounted_part_id, carry_icon)
	Game.state.job_repair_progress[_progress_key()] = "removed"
	sprite.visible = false

func _try_install() -> void:
	if PlayerCarry.get_carried_part_id() != install_part_id:
		_show_message("Necesitás traer la pieza correcta para poder ponerla.")
		return

	PlayerCarry.consume()
	Game.state.job_repair_progress[_progress_key()] = "installed"
	sprite.texture = _healthy_texture
	sprite.visible = true

	var job := JobsRepository.get_job(vehicle.job_id)
	if job and Game.state.active_jobs.has(vehicle.job_id) and JobsRepository.required_slots_done(job):
		if vehicle.has_more_rounds(job):
			_show_message("Listo, quedó puesto. Ahora falta el otro lado.")
			vehicle.advance_round(job)
		else:
			JobsManager.request_pickup(vehicle.job_id)
			_show_message("Listo, quedó puesto. Ya avisé al cliente que puede venir a buscarlo.")
	else:
		_show_message("Listo, quedó puesto.")

func _progress_key() -> String:
	return "%s:%s" % [vehicle.job_id, slot_id]

func _stage() -> String:
	return Game.state.job_repair_progress.get(_progress_key(), "")

## Este job no pidió tocar esta pieza — no hay motivo para desarmarla.
func _is_required() -> bool:
	var job := JobsRepository.get_job(vehicle.job_id)
	return job != null and job.required_slots.has(slot_id)

func _is_damaged() -> bool:
	var job := JobsRepository.get_job(vehicle.job_id)
	return job != null and job.damaged_slots.has(slot_id)

func _show_message(text: String) -> void:
	var lines: Array[String] = [text]
	var dialogue := get_tree().get_first_node_in_group("dialogue_modal")
	dialogue.show_lines(lines)
