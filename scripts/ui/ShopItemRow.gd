extends HBoxContainer

## Una fila del PurchaseModal — un producto (ShopItem), su stock actual
## y el botón de compra. Se instancia una por producto, se descarta al
## cerrar el modal (ver PurchaseModal.open). Autónoma: escucha sola los
## cambios de stock/plata, nadie de afuera necesita refrescarla.

@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $Info/NameLabel
@onready var stock_label: Label = $Info/StockLabel
@onready var buy_button: Button = $BuyButton

var item: ShopItem

func setup(shop_item: ShopItem) -> void:
	item = shop_item
	icon.texture = item.icon
	name_label.text = "%s — $%d" % [item.display_name, item.price]

	buy_button.pressed.connect(_on_buy_pressed)
	PartsInventory.part_changed.connect(_on_part_changed)
	Game.state.money_changed.connect(_on_money_changed)

	_refresh()

func _on_buy_pressed() -> void:
	if PartsInventory.get_quantity(item.part_id) >= item.capacity:
		return
	if Game.state.money < item.price:
		return

	Game.state.money -= item.price
	PartsInventory.add_part(item.part_id, 1)

func _on_part_changed(changed_part_id: String, _quantity: int) -> void:
	if changed_part_id == item.part_id:
		_refresh()

func _on_money_changed(_amount: int) -> void:
	_refresh()

func _refresh() -> void:
	var stock: int = PartsInventory.get_quantity(item.part_id)
	stock_label.text = "%d/%d en el taller" % [stock, item.capacity]
	buy_button.disabled = stock >= item.capacity or Game.state.money < item.price
