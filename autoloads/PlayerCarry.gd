extends Node

## Qué pieza está cargando el jugador ahora mismo (arriba de la
## cabeza) — es autoload porque tanto quien la entrega (ej.
## VehicleRepairMenu) como quien la recibe (PartStorageZone) y el
## visual del jugador (PlayerCarryIcon) necesitan leerlo o cambiarlo.
## Genérico a propósito: no sabe nada de neumáticos en particular,
## cualquier part_id + ícono sirve para la próxima pieza que exista.

signal carry_changed(part_id: String, icon: Texture2D)  # icon null = dejó de cargar algo

const DroppedPartScene := preload("res://scenes/world/DroppedPart.tscn")

var _part_id := ""
var _icon: Texture2D = null

## Nunca se puede cargar una segunda pieza mientras ya tenés una —
## quien llame a esto mientras is_carrying() es true no tiene efecto.
func carry(part_id: String, icon: Texture2D) -> void:
	if is_carrying():
		return

	_part_id = part_id
	_icon = icon
	carry_changed.emit(_part_id, _icon)

func is_carrying() -> bool:
	return _part_id != ""

func get_carried_part_id() -> String:
	return _part_id

func _unhandled_input(event: InputEvent) -> void:
	if not is_carrying():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_drop()

## Prioridad: si el jugador está parado en una PartStorageZone que
## coincide con lo que carga y todavía tiene lugar, va ahí (+1 de
## stock real, ver PartsInventory). Si no, se fija en el piso, en la
## celda que marca FloorPlacementCursor (la que está bajo el mouse) —
## si está libre (verde) la deja ahí como un DroppedPart recogible; si
## está bloqueada (roja), no hace nada, seguís cargando.
func _drop() -> void:
	for zone in get_tree().get_nodes_in_group("part_storage_zone"):
		if zone.try_deposit(_part_id):
			_finish_carry()
			return

	var cursor := get_tree().get_first_node_in_group("floor_placement_cursor")
	if cursor and not cursor.is_cell_free():
		return  # celda roja -- no se puede soltar acá

	_spawn_on_floor(cursor.get_cell_center() if cursor else get_tree().get_first_node_in_group("player").global_position)
	_finish_carry()

func _finish_carry() -> void:
	_part_id = ""
	_icon = null
	carry_changed.emit("", null)

func _spawn_on_floor(at_position: Vector2) -> void:
	var dropped := DroppedPartScene.instantiate()
	dropped.global_position = at_position

	# Recién acá terminan de existir los @onready del nodo (Sprite2D
	# incluido) — setup() tiene que llamarse después de add_to_current_map,
	# nunca antes.
	var world_manager := get_tree().get_first_node_in_group("world_manager")
	world_manager.add_to_current_map(dropped)
	dropped.setup(_part_id, _icon)
