extends Node

## Fuente de verdad del stock de piezas del taller (ver GameState.parts)
## — nunca mochila del jugador, todo lo comprado entra directo acá.
## part_id es un String libre (ej. "neumatico") — sin catálogo todavía,
## eso llega junto con la compra real en el Marketplace.

func add_part(part_id: String, amount: int = 1) -> void:
	Game.state.parts[part_id] = get_quantity(part_id) + amount

func remove_part(part_id: String, amount: int = 1) -> bool:
	if get_quantity(part_id) < amount:
		return false

	Game.state.parts[part_id] -= amount
	return true

func get_quantity(part_id: String) -> int:
	return Game.state.parts.get(part_id, 0)
