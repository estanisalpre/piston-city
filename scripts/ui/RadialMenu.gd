extends CanvasLayer

## Menú radial genérico y reusable — abrí con open(items) y esperá
## action_chosen. Pensado para interactuar con el auto (ver
## VehicleRepairMenu) pero no sabe nada de neumáticos ni de ningún
## rubro en particular; eso vive en los RadialMenuItem que le pasen.
##
## Si un item tiene "children", elegirlo abre un nuevo nivel con esos
## hijos en el mismo radial (con un botón "Atrás" para volver). Un item
## sin children es una acción final: emite su id y se cierra solo.

signal action_chosen(action_id: String)

const RADIUS := 70.0
const ITEM_SIZE := Vector2(48, 60)

@onready var center: Control = $Center
@onready var back_button: Button = $Center/BackButton

var _stack: Array = []  # Array[Array] (cada nivel es un Array[RadialMenuItem])

func _ready() -> void:
	add_to_group("radial_menu")
	hide()
	back_button.pressed.connect(_on_back_pressed)

func open(items: Array) -> void:
	_stack = [items]
	show()
	_render(items)

func close() -> void:
	hide()

func _render(items: Array) -> void:
	for child in center.get_children():
		if child != back_button:
			child.queue_free()

	back_button.visible = _stack.size() > 1

	var count: int = items.size()
	for i in count:
		var item: RadialMenuItem = items[i]
		var angle: float = (TAU / count) * i - PI / 2.0
		var offset := Vector2(cos(angle), sin(angle)) * RADIUS

		var item_control := _build_item_control(item)
		item_control.position = offset - ITEM_SIZE / 2.0
		center.add_child(item_control)

func _build_item_control(item: RadialMenuItem) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = ITEM_SIZE

	var button := TextureButton.new()
	button.texture_normal = item.icon
	button.custom_minimum_size = Vector2(32, 32)
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_item_pressed.bind(item))
	container.add_child(button)

	var label := Label.new()
	label.text = item.label
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)

	return container

func _on_item_pressed(item: RadialMenuItem) -> void:
	if item.children.is_empty():
		hide()
		action_chosen.emit(item.id)
	else:
		_stack.append(item.children)
		_render(item.children)

func _on_back_pressed() -> void:
	_stack.pop_back()
	_render(_stack[-1])
