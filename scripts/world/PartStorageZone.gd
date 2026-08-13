extends Area2D

## Mueble con lugares físicos limitados en el taller (ej. la
## estantería de neumáticos, o una caja de la estantería del cuarto de
## almacenamiento) — reusable: instanciar PartStorageZone.tscn en
## cualquier lugar y completar Zone Id, Capacity y Part Icons desde el
## Inspector.
##
## Pura vista: nunca decide qué hay dónde, eso vive en
## PartsInventory.get_slots(zone_id, capacity) (ver ahí el porqué —
## tiene que existir incluso comprando desde otro mapa donde este nodo
## ni está cargado). Este script solo pinta ese estado sobre hasta
## "capacity" lugares, en el mismo orden — el lugar que ocupó un
## neumático usado no se pisa nunca con uno nuevo ni viceversa, cada
## uno tiene su propio lugar hasta que se saca de ahí.
##
## Cada Sprite2D hijo directo (ej. tire_1..tire_5) es "un lugar": se
## ve/oculta según si está ocupado — patrón de la estantería de
## neumáticos, un mueble ABIERTO donde tiene sentido ver cada pieza
## puesta en su lugar físico.
##
## Para muebles CERRADOS (ej. las cajas del cuarto de almacenamiento,
## donde no tiene sentido ver íconos flotando sobre la tapa) usar
## use_modal = true: no se dibuja nada en el mundo, y clickear la caja
## abre BoxInventoryModal en grande con la grilla completa — recién
## ahí se ve qué hay en cada lugar.
##
## Dos interacciones:
## - Cualquiera que esté cargando una pieza (ver PlayerCarry) puede
##   depositarla acá con try_deposit() — nunca decide cuándo llamarlo,
##   eso lo maneja PlayerCarry al soltar. Funciona igual con o sin
##   modal.
## - Click izquierdo, parado acá y sin cargar nada: en modo normal
##   agarra el lugar MÁS CERCANO al mouse (sea nuevo o usado, lo que
##   sea que tenga puesto ese lugar puntual); en modo use_modal abre
##   el modal en vez de sacar nada directo.

@export var zone_id: String = "tire_shelf"
@export var capacity: int = 5

## true para muebles cerrados (ver arriba) — clickear abre
## BoxInventoryModal en vez de sacar un lugar directo del mundo.
@export var use_modal: bool = false

## part_id (ej. "neumatico", "neumatico_usado") -> textura a mostrar en
## el lugar que ocupe. Un mueble puede tener varios tipos mezclados.
@export var part_icons: Dictionary[String, Texture2D] = {}

var player_in_range := false

func _ready() -> void:
	add_to_group("part_storage_zone")
	input_pickable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	PartsInventory.slots_changed.connect(_on_slots_changed)
	_refresh_slots()

## Lo llama PlayerCarry al soltar — deposita solo si el jugador está
## parado acá, esta estantería acepta ese tipo de pieza, y todavía hay
## lugar libre (sea cual sea la mezcla de tipos ya puestos).
func try_deposit(carried_part_id: String) -> bool:
	if not player_in_range or not part_icons.has(carried_part_id):
		return false

	return PartsInventory.deposit_in_zone(zone_id, capacity, carried_part_id)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not player_in_range or PlayerCarry.is_carrying():
		return

	get_viewport().set_input_as_handled()

	if use_modal:
		_open_modal()
		return

	var index := _closest_slot_index()
	if index == -1:
		return

	var taken_part_id := PartsInventory.take_from_index(zone_id, index)
	if taken_part_id == "":
		return

	PlayerCarry.carry(taken_part_id, part_icons.get(taken_part_id))

## Solo para muebles cerrados (use_modal = true) — el modal se agrega
## una única vez a la escena principal (ver Main.tscn), así que
## siempre existe sin importar qué mapa esté cargado.
func _open_modal() -> void:
	var modal := get_tree().get_first_node_in_group("box_inventory_modal")
	if modal:
		modal.open(zone_id, capacity, part_icons)

## Cuál de los Sprite2D hijos está más cerca del mouse ahora mismo —
## así el click agarra el lugar que estás mirando, no siempre el
## primero de la fila.
func _closest_slot_index() -> int:
	var sprite_slots := _get_slots()
	var mouse_pos := get_global_mouse_position()

	var best_index := -1
	var best_dist := INF

	for i in sprite_slots.size():
		var dist: float = sprite_slots[i].global_position.distance_to(mouse_pos)
		if dist < best_dist:
			best_dist = dist
			best_index = i

	return best_index

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
	if use_modal:
		return

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
