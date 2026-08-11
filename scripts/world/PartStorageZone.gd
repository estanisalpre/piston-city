extends Area2D

## Mueble con lugares físicos limitados en el taller (ej. la
## estantería de neumáticos) — reusable: instanciar
## PartStorageZone.tscn en cualquier lugar y completar Zone Id,
## Capacity y Part Icons desde el Inspector.
##
## Pura vista: nunca decide qué hay dónde, eso vive en
## PartsInventory.get_slots(zone_id, capacity) (ver ahí el porqué —
## tiene que existir incluso comprando desde otro mapa donde este nodo
## ni está cargado). Este script solo pinta ese estado sobre hasta
## "capacity" Sprite2D hijos, en el mismo orden — el lugar que ocupó un
## neumático usado no se pisa nunca con uno nuevo ni viceversa, cada
## uno tiene su propio lugar hasta que se saca de ahí.
##
## Además, cualquiera que esté cargando una pieza (ver PlayerCarry)
## puede depositarla acá con try_deposit() — nunca decide cuándo
## llamarlo, eso lo maneja PlayerCarry al soltar.

@export var zone_id: String = "tire_shelf"
@export var capacity: int = 5

## part_id (ej. "neumatico", "neumatico_usado") -> textura a mostrar en
## el lugar que ocupe. Un mueble puede tener varios tipos mezclados.
@export var part_icons: Dictionary[String, Texture2D] = {}

var player_in_range := false

func _ready() -> void:
	add_to_group("part_storage_zone")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	PartsInventory.slots_changed.connect(_on_slots_changed)
	_refresh_slots()

## Lo llama PlayerCarry al soltar — deposita solo si el jugador está
## parado acá, esta estantería acepta ese tipo de pieza, y todavía hay
## lugar libre (sea cual sea la mezcla de tipos ya puestos).
func try_deposit(carried_part_id: String) -> bool:
	print("[PartStorageZone %s] try_deposit('%s') — player_in_range=%s, part_icons acepta=%s, part_icons keys=%s" % [
		zone_id, carried_part_id, player_in_range, part_icons.has(carried_part_id), part_icons.keys()
	])

	if not player_in_range or not part_icons.has(carried_part_id):
		return false

	var ok := PartsInventory.deposit_in_zone(zone_id, capacity, carried_part_id)
	print("[PartStorageZone %s] deposit_in_zone -> %s (slots=%s)" % [zone_id, ok, PartsInventory.get_slots(zone_id, capacity)])
	return ok

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _on_slots_changed(changed_zone_id: String) -> void:
	if changed_zone_id == zone_id:
		_refresh_slots()

func _refresh_slots() -> void:
	var occupants: Array = PartsInventory.get_slots(zone_id, capacity)
	var sprite_slots := _get_slots()

	for i in sprite_slots.size():
		var part_id: String = occupants[i] if i < occupants.size() else ""
		sprite_slots[i].visible = part_id != ""
		if part_id != "":
			sprite_slots[i].texture = part_icons.get(part_id)

func _get_slots() -> Array:
	var slots: Array = []
	for child in get_children():
		if child is Sprite2D:
			slots.append(child)
	return slots
