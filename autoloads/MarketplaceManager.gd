extends Node

## Junta piezas usadas (dondequiera que estén: estanterías o tiradas en
## el piso, sin importar el mapa) para venderlas de a varias desde la
## computadora del marketplace — el pago NUNCA es instantáneo, se
## acredita al día siguiente a las 08:00 (ver SellCatalog para qué es
## "usado" y a qué precio).

const PAYOUT_HOUR := 8.0  # 08:00

func _ready() -> void:
	TimeManager.minute_changed.connect(_on_minute_changed)

## Todo lo vendible que existe ahora mismo, sin importar dónde esté
## guardado. Cada entrada: {"source": "shelf"|"floor", part_id,
## price, y "zone_id"+"index" (shelf) o "id" (floor) para poder
## sacarla después con sell_items()}.
func list_sellable_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []

	for zone_id in Game.state.storage_slots.keys():
		var slots: Array = Game.state.storage_slots[zone_id]
		for i in slots.size():
			var part_id: String = slots[i]
			if part_id != "" and SellCatalog.is_sellable(part_id):
				items.append({
					"source": "shelf",
					"zone_id": zone_id,
					"index": i,
					"part_id": part_id,
					"price": SellCatalog.price_of(part_id),
				})

	for record in Game.state.dropped_parts:
		if SellCatalog.is_sellable(record.part_id):
			items.append({
				"source": "floor",
				"id": record.id,
				"part_id": record.part_id,
				"price": SellCatalog.price_of(record.part_id),
			})

	return items

## Saca cada ítem de donde esté (estantería o piso) y programa un solo
## pago conjunto para mañana a las 08:00.
func sell_items(items: Array) -> void:
	var total := 0

	for item in items:
		if item.source == "shelf":
			PartsInventory.take_from_index(item.zone_id, item.index)
		else:
			PlayerCarry.remove_dropped_record(item.id)

		total += item.price

	if total <= 0:
		return

	Game.state.pending_sales.append({
		"amount": total,
		"pay_day": Game.state.day + 1,
	})

func _on_minute_changed(_hour: int, _minute: int) -> void:
	if Game.state.pending_sales.is_empty():
		return

	var minute_of_day := fmod(TimeManager.get_total_minutes(), TimeManager.MINUTES_PER_DAY)
	if minute_of_day < PAYOUT_HOUR * 60.0:
		return

	var paid: Array[Dictionary] = []
	for sale in Game.state.pending_sales:
		if Game.state.day >= sale.pay_day:
			Game.state.money += sale.amount
			paid.append(sale)

	for sale in paid:
		Game.state.pending_sales.erase(sale)
