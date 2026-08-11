extends HBoxContainer

## Una fila del PurchaseModal — un producto (ShopItem), el cupo
## compartido de su estantería (ver PartsInventory.deposit_in_zone) y
## el botón de compra. Se instancia una por producto, se descarta al
## cerrar el modal (ver PurchaseModal.open). Autónoma: escucha sola los
## cambios de esa estantería/plata, nadie de afuera necesita refrescarla.

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
	PartsInventory.slots_changed.connect(_on_slots_changed)
	Game.state.money_changed.connect(_on_money_changed)

	_refresh()

func _on_buy_pressed() -> void:
	if Game.state.money < item.price:
		return

	if not PartsInventory.deposit_in_zone(item.storage_zone_id, item.storage_capacity, item.part_id):
		return  # sin lugar libre en esa estantería, sea cual sea la mezcla de tipos ya puestos

	Game.state.money -= item.price

func _on_slots_changed(changed_zone_id: String) -> void:
	if changed_zone_id == item.storage_zone_id:
		_refresh()

func _on_money_changed(_amount: int) -> void:
	_refresh()

func _refresh() -> void:
	var occupants: Array = PartsInventory.get_slots(item.storage_zone_id, item.storage_capacity)
	var occupied: int = item.storage_capacity - occupants.count("")

	stock_label.text = "%d/%d en el taller" % [occupied, item.storage_capacity]
	buy_button.disabled = occupied >= item.storage_capacity or Game.state.money < item.price
