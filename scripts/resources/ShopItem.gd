extends Resource
class_name ShopItem

## Un producto comprable en cualquier local (ver ShopCounter/PurchaseModal)
## — Resource plano, sin lógica de Godot, mismo espíritu que se usará
## para VehicleData cuando exista el marketplace (ver CLAUDE.md). Se
## define directo en el Inspector, uno por producto, sin catálogo
## centralizado todavía — eso recién tiene sentido cuando haya muchos
## locales repitiendo los mismos productos.

@export var part_id: String = ""
@export var display_name: String = ""
@export var price: int = 0
@export var icon: Texture2D

## A qué estantería del taller va esta compra (ver PartsInventory.
## deposit_in_zone/PartStorageZone.zone_id) y cuántos lugares tiene esa
## estantería en total — comprar respeta el mismo cupo compartido que
## cualquier otra pieza que ya esté puesta ahí, sea del tipo que sea.
@export var storage_zone_id: String = ""
@export var storage_capacity: int = 5
