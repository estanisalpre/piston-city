extends Area2D

## Etiqueta de texto libre flotando sobre una caja/estantería —
## reusable: instanciar ZoneLabel.tscn como hermano de la caja (mismo
## Node2D padre) y completar Zone Id desde el Inspector.
##
## Pura vista: el texto nunca vive acá, vive en
## Game.state.box_labels (ver PartsInventory.get_zone_label/
## set_zone_label) — mismo patrón que PartStorageZone con los slots.
##
## Click izquierdo sobre la etiqueta abre un LineEdit en el mismo
## lugar, precargado con el texto actual. Enter o click afuera guarda.

@export var zone_id: String = ""

@onready var label: Label = $Label
@onready var line_edit: LineEdit = $LineEdit

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	line_edit.text_submitted.connect(_on_text_submitted)
	line_edit.focus_exited.connect(_on_focus_exited)
	line_edit.visible = false
	PartsInventory.zone_label_changed.connect(_on_zone_label_changed)
	_refresh_label()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	get_viewport().set_input_as_handled()
	_start_editing()

func _start_editing() -> void:
	line_edit.text = PartsInventory.get_zone_label(zone_id)
	label.visible = false
	line_edit.visible = true
	line_edit.grab_focus()
	line_edit.select_all()

func _on_text_submitted(new_text: String) -> void:
	PartsInventory.set_zone_label(zone_id, new_text)
	_stop_editing()

func _on_focus_exited() -> void:
	_stop_editing()

func _stop_editing() -> void:
	if not line_edit.visible:
		return

	line_edit.visible = false
	label.visible = true
	_refresh_label()

func _on_zone_label_changed(changed_zone_id: String) -> void:
	if changed_zone_id == zone_id:
		_refresh_label()

func _refresh_label() -> void:
	var text := PartsInventory.get_zone_label(zone_id)
	label.text = text if text != "" else "(vacío)"
