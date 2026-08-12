extends RefCounted
class_name SellCatalog

## Qué piezas "usadas" se pueden vender desde la computadora del
## marketplace (ver MarketplaceManager) y cuánto vale la pieza NUEVA
## equivalente — el precio de venta SIEMPRE es ese * USED_DISCOUNT,
## nunca se configura un precio de reventa a mano. Sumás una línea acá
## por cada pieza usada nueva que quieras poder vender a futuro.

const USED_DISCOUNT := 0.25

const ORIGINAL_PRICES := {
	"neumatico_usado": 500,
}

static func is_sellable(part_id: String) -> bool:
	return ORIGINAL_PRICES.has(part_id)

static func price_of(part_id: String) -> int:
	return int(ORIGINAL_PRICES.get(part_id, 0) * USED_DISCOUNT)
