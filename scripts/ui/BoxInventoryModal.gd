extends CanvasLayer

## Modal a pantalla completa que muestra en grande los lugares de UNA
## caja de almacenamiento — se abre solo al clickear esa caja puntual
## (ver PartStorageZone.use_modal), nunca antes. Clickear un lugar
## ocupado saca esa pieza a la mano del jugador y cierra el modal.

const CELL_SIZE := Vector2(64, 64)
const EMPTY_STYLE_COLOR := Color(0, 0, 0, 0.35)
const BORDER_COLOR := Color(1, 1, 1, 0.4)

@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var grid: GridContainer = $Panel/MarginContainer/VBox/Grid
@onready var close_button: Button = $Panel/MarginContainer/VBox/CloseButton

var _zone_id := ""
var _capacity := 0
var _part_icons: Dictionary = {}

func _ready() -> void:
	add_to_group("box_inventory_modal")
	hide()
	close_button.pressed.connect(close)
	PartsInventory.slots_changed.connect(_on_slots_changed)
	PartsInventory.zone_label_changed.connect(_on_zone_label_changed)

func open(zone_id: String, capacity: int, part_icons: Dictionary) -> void:
	_zone_id = zone_id
	_capacity = capacity
	_part_icons = part_icons
	_refresh()
	show()

func close() -> void:
	hide()

func _on_slots_changed(changed_zone_id: String) -> void:
	if visible and changed_zone_id == _zone_id:
		_refresh_grid()

func _on_zone_label_changed(changed_zone_id: String) -> void:
	if visible and changed_zone_id == _zone_id:
		_refresh_title()

func _refresh() -> void:
	_refresh_title()
	_refresh_grid()

func _refresh_title() -> void:
	var text := PartsInventory.get_zone_label(_zone_id)
	title_label.text = text if text != "" else "(sin descripción)"

func _refresh_grid() -> void:
	for child in grid.get_children():
		child.queue_free()

	var occupants: Array = PartsInventory.get_slots(_zone_id, _capacity)

	for i in _capacity:
		var part_id: String = occupants[i] if i < occupants.size() else ""
		grid.add_child(_build_cell(i, part_id))

func _build_cell(index: int, part_id: String) -> Control:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = CELL_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = EMPTY_STYLE_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	cell.add_theme_stylebox_override("panel", style)

	if part_id != "":
		var icon := TextureRect.new()
		icon.texture = _part_icons.get(part_id)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(icon)

		var button := Button.new()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_cell_pressed.bind(index))
		cell.add_child(button)

	return cell

func _on_cell_pressed(index: int) -> void:
	if PlayerCarry.is_carrying():
		return

	var part_id := PartsInventory.take_from_index(_zone_id, index)
	if part_id == "":
		return

	PlayerCarry.carry(part_id, _part_icons.get(part_id))
	close()
