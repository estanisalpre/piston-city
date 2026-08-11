extends Area2D

## Zona de almacenamiento de un tipo de pieza en el taller — marca dónde
## "vive" cada part_id (ver PartsInventory) para que el jugador la
## busque ahí cuando la necesite. Reusable: instanciar
## PartStorageZone.tscn en cualquier lugar del taller y completar Part
## Id desde el Inspector.
##
## El dibujo de cada unidad NO lo pone este script — agregá a mano, como
## hijos de este nodo, hasta "capacity" Sprite2D con la textura de la
## pieza (ej. el PNG del neumático), posicionados donde quede bien
## visualmente sobre el dibujo de la estantería. Este script solo
## muestra los primeros N (según el stock actual en PartsInventory) y
## oculta el resto — nunca decide dónde van.
##
## Además, cualquiera que esté cargando una pieza (ver PlayerCarry)
## puede depositarla acá con try_deposit() — nunca decide cuándo
## llamarlo, eso lo maneja PlayerCarry al soltar.

@export var part_id: String = ""

## Cuántas unidades entran acá con el nivel actual de la estantería (a
## futuro esto sube con una mejora) — si agregás menos Sprite2D hijos
## que este número, el excedente de stock simplemente no se ve.
@export var capacity: int = 5

var player_in_range := false

func _ready() -> void:
	add_to_group("part_storage_zone")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	PartsInventory.part_changed.connect(_on_part_changed)
	_refresh_slots()

## Lo llama PlayerCarry al soltar — deposita solo si el jugador está
## parado acá, la pieza coincide con esta zona, y todavía hay lugar.
## Devuelve si lo pudo dejar (PlayerCarry decide qué hacer si no).
func try_deposit(carried_part_id: String) -> bool:
	if not player_in_range or carried_part_id != part_id:
		return false

	if PartsInventory.get_quantity(part_id) >= capacity:
		return false

	PartsInventory.add_part(part_id, 1)
	return true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _on_part_changed(changed_part_id: String, _quantity: int) -> void:
	if changed_part_id == part_id:
		_refresh_slots()

func _refresh_slots() -> void:
	var stock: int = min(PartsInventory.get_quantity(part_id), capacity)
	var slots := _get_slots()

	for i in slots.size():
		slots[i].visible = i < stock

func _get_slots() -> Array:
	var slots: Array = []
	for child in get_children():
		if child is Sprite2D:
			slots.append(child)
	return slots
