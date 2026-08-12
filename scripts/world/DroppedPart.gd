extends Area2D

## Una pieza que quedó tirada en el piso (ver PlayerCarry.gd, cuando no
## había dónde guardarla) — click izquierdo la vuelve a levantar y
## desaparece de acá. Si ya estás cargando otra cosa, no hace nada
## (nunca se puede llevar más de una pieza a la vez).

@onready var sprite: Sprite2D = $Sprite2D

var _part_id := ""
var _icon: Texture2D
var _record_id := -1

func setup(part_id: String, icon: Texture2D, record_id: int) -> void:
	_part_id = part_id
	_icon = icon
	_record_id = record_id
	sprite.texture = icon

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	PlayerCarry.dropped_part_removed.connect(_on_dropped_part_removed)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	if PlayerCarry.is_carrying():
		return

	get_viewport().set_input_as_handled()
	PlayerCarry.carry(_part_id, _icon)
	PlayerCarry.remove_dropped_record(_record_id)

## Se dispara también cuando ESTA MISMA pieza se vendió desde la
## computadora del marketplace (ver MarketplaceManager) — ahí nadie la
## "levantó" a mano, pero igual tiene que desaparecer del mapa.
func _on_dropped_part_removed(id: int) -> void:
	if id == _record_id:
		queue_free()
