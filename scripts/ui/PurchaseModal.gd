extends CanvasLayer

## Modal de compra genérico, para cualquier local (ver ShopCounter) — se
## desliza de abajo hacia arriba (mismo mecanismo de Tween que
## Phone.gd). Arma una fila (ShopItemRow) por cada ShopItem que le pasen
## en open(); cada fila se encarga sola de descontar plata y sumar
## stock. No sabe nada de "neumáticos" ni de ningún producto en
## particular — eso vive en el ShopItem de cada local.

const ANIM_DURATION := 0.25
const BASE_HEIGHT := 70.0  # título + botón cerrar + márgenes
const ROW_HEIGHT := 46.0

const ShopItemRowScene := preload("res://scenes/ui/ShopItemRow.tscn")

@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var items_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/Items
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	add_to_group("purchase_modal")
	hide()
	panel.offset_top = 0.0
	close_button.pressed.connect(close)

func open(title: String, items: Array[ShopItem]) -> void:
	title_label.text = title

	for child in items_container.get_children():
		child.queue_free()

	for item in items:
		var row := ShopItemRowScene.instantiate()
		items_container.add_child(row)
		row.setup(item)

	show()

	var target_height: float = BASE_HEIGHT + items.size() * ROW_HEIGHT
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "offset_top", -target_height, ANIM_DURATION)

func close() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "offset_top", 0.0, ANIM_DURATION)
	await tween.finished
	hide()
