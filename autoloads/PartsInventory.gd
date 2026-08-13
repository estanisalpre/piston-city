extends Node

## Fuente de verdad del stock de piezas del taller (ver GameState.parts)
## — nunca mochila del jugador, todo lo comprado entra directo acá.
## part_id es un String libre (ej. "neumatico") — sin catálogo todavía,
## eso llega junto con la compra real en el Marketplace.

## Avisa cada vez que cambia el stock de una pieza — lo escucha
## PartStorageZone para mostrar/ocultar sprites sin tener que revisar
## esto todos los frames.
signal part_changed(part_id: String, quantity: int)

func add_part(part_id: String, amount: int = 1) -> void:
	Game.state.parts[part_id] = get_quantity(part_id) + amount
	part_changed.emit(part_id, get_quantity(part_id))

func remove_part(part_id: String, amount: int = 1) -> bool:
	if get_quantity(part_id) < amount:
		return false

	Game.state.parts[part_id] -= amount
	part_changed.emit(part_id, get_quantity(part_id))
	return true

func get_quantity(part_id: String) -> int:
	return Game.state.parts.get(part_id, 0)

# --- Estanterías con lugares físicos limitados -----------------------------
#
# Un "zone_id" (ej. "tire_shelf") es un mueble con "capacity" lugares en
# fila. Cada lugar guarda "" (vacío) o el part_id puesto ahí — nuevos y
# usados pueden convivir en el mismo mueble, cada uno en su propio
# lugar, sin pisarse. Es la ÚNICA fuente de verdad de qué hay dónde,
# vive en Game.state (no en el nodo de la escena) para que funcione
# incluso comprando desde otro mapa (ej. la gomería) donde el mueble
## real ni está cargado — PartStorageZone solo dibuja lo que diga acá.

signal slots_changed(zone_id: String)

func _ensure_slots(zone_id: String, capacity: int) -> void:
	if not Game.state.storage_slots.has(zone_id):
		var slots: Array = []
		for i in capacity:
			slots.append("")
		Game.state.storage_slots[zone_id] = slots

func get_slots(zone_id: String, capacity: int) -> Array:
	_ensure_slots(zone_id, capacity)
	return Game.state.storage_slots[zone_id]

## Ocupa el primer lugar libre de esa estantería con part_id — sea
## comprado en un local o traído a upa por el jugador, siempre pasa por
## acá, así nunca hay más piezas físicas que lugares, sin importar la
## mezcla de tipos que sean. Devuelve false (sin efecto) si no queda
## ningún lugar libre.
func deposit_in_zone(zone_id: String, capacity: int, part_id: String) -> bool:
	var slots := get_slots(zone_id, capacity)
	var empty_index: int = slots.find("")
	if empty_index == -1:
		return false

	slots[empty_index] = part_id
	add_part(part_id, 1)
	slots_changed.emit(zone_id)
	return true

## Libera el lugar puntual "index" de esa estantería (el que el
## jugador clickeó/seleccionó, ver PartStorageZone, o el que eligió
## vender desde la computadora, ver MarketplaceManager) y devuelve qué
## part_id tenía puesto — "" si ese lugar estaba vacío, el índice no
## existe, o la estantería ni se cargó todavía. Sin "capacity" a
## propósito: para SACAR algo no hace falta saber el tamaño máximo,
## solo importa para cuando hay que crear la estantería la primera vez
## (ver deposit_in_zone).
func take_from_index(zone_id: String, index: int) -> String:
	if not Game.state.storage_slots.has(zone_id):
		return ""

	var slots: Array = Game.state.storage_slots[zone_id]
	if index < 0 or index >= slots.size():
		return ""

	var part_id: String = slots[index]
	if part_id == "":
		return ""

	slots[index] = ""
	remove_part(part_id, 1)
	slots_changed.emit(zone_id)
	return part_id

# --- Etiquetas de caja (texto libre) ----------------------------------------
#
# El jugador describe a mano qué guardó en cada caja (ver ZoneLabel) — no se
# arma solo a partir de storage_slots porque no hay catálogo de piezas con
# nombres lindos todavía, solo part_ids como "bateria".

signal zone_label_changed(zone_id: String)

func get_zone_label(zone_id: String) -> String:
	return Game.state.box_labels.get(zone_id, "")

func set_zone_label(zone_id: String, text: String) -> void:
	Game.state.box_labels[zone_id] = text
	zone_label_changed.emit(zone_id)
