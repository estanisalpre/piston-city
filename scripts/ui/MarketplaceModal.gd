extends CanvasLayer

## Modal a pantalla completa de la computadora del marketplace — lista
## todo lo vendible que junta MarketplaceManager (estanterías + piso,
## de cualquier mapa), con un check por fila para elegir cuáles vender
## juntas. El pago nunca es instantáneo (ver MarketplaceManager).

@onready var list_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/List
@onready var sell_button: Button = $Panel/MarginContainer/VBoxContainer/SellButton
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var _rows: Array = []  # Array[{"item": Dictionary, "checkbox": CheckBox}]

func _ready() -> void:
	add_to_group("marketplace_modal")
	hide()
	sell_button.pressed.connect(_on_sell_pressed)
	close_button.pressed.connect(_on_close_pressed)

func open() -> void:
	_refresh()
	show()

func _refresh() -> void:
	for child in list_container.get_children():
		child.queue_free()
	_rows.clear()

	for item in MarketplaceManager.list_sellable_items():
		var row := HBoxContainer.new()

		var check := CheckBox.new()
		row.add_child(check)

		var label := Label.new()
		label.text = "%s — $%d" % [item.part_id, item.price]
		row.add_child(label)

		list_container.add_child(row)
		_rows.append({"item": item, "checkbox": check})

func _on_sell_pressed() -> void:
	var selected: Array = []
	for row in _rows:
		if row.checkbox.button_pressed:
			selected.append(row.item)

	if selected.is_empty():
		return

	MarketplaceManager.sell_items(selected)
	_refresh()

func _on_close_pressed() -> void:
	hide()
