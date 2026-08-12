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

@onready var sprite: Sprite2D = $Sprite2D

## El auto siempre instancia esta pieza como hijo suyo directo (ver
## JobVehicle.gd) — de ahí sacamos el job_id.
@onready var vehicle: Node = get_parent()

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	sprite.visible = _stage() != "removed"

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	get_viewport().set_input_as_handled()

	if sprite.visible:
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
	PlayerCarry.carry(removed_part_id, carry_icon)
	Game.state.job_repair_progress[_progress_key()] = "removed"
	sprite.visible = false

func _try_install() -> void:
	if PlayerCarry.get_carried_part_id() != install_part_id:
		_show_message("Necesitás traer la pieza correcta para poder ponerla.")
		return

	PlayerCarry.consume()
	Game.state.job_repair_progress[_progress_key()] = "installed"
	sprite.visible = true
	_show_message("Listo, quedó puesto.")

func _progress_key() -> String:
	return "%s:%s" % [vehicle.job_id, slot_id]

func _stage() -> String:
	return Game.state.job_repair_progress.get(_progress_key(), "")

func _show_message(text: String) -> void:
	var lines: Array[String] = [text]
	var dialogue := get_tree().get_first_node_in_group("dialogue_modal")
	dialogue.show_lines(lines)
