extends Area2D

## Una pieza que quedó tirada en el piso (ver PlayerCarry.gd, cuando no
## había dónde guardarla) — click izquierdo la vuelve a levantar y
## desaparece de acá. Si ya estás cargando otra cosa, no hace nada
## (nunca se puede llevar más de una pieza a la vez).

@onready var sprite: Sprite2D = $Sprite2D

var _part_id := ""
var _icon: Texture2D

func setup(part_id: String, icon: Texture2D) -> void:
	_part_id = part_id
	_icon = icon
	sprite.texture = icon

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	if PlayerCarry.is_carrying():
		return

	get_viewport().set_input_as_handled()
	PlayerCarry.carry(_part_id, _icon)
	queue_free()
