extends Node

## Qué pieza está cargando el jugador ahora mismo (arriba de la
## cabeza) — es autoload porque tanto quien la entrega (ej.
## VehicleRepairMenu) como quien la recibe (PartStorageZone) y el
## visual del jugador (PlayerCarryIcon) necesitan leerlo o cambiarlo.
## Genérico a propósito: no sabe nada de neumáticos en particular,
## cualquier part_id + ícono sirve para la próxima pieza que exista.

signal carry_changed(part_id: String, icon: Texture2D)  # icon null = dejó de cargar algo

## Avisa cuando se sacó un registro de dropped_parts (levantado a mano,
## o vendido desde la computadora del marketplace) — lo escucha
## DroppedPart para autodestruirse si en ese momento está visible en
## el mapa cargado, sin importar quién haya pedido sacar el registro.
signal dropped_part_removed(id: int)

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

## Lo llama quien use la pieza cargada en una acción (ej. instalarla en
## el auto) — a diferencia de soltarla, no busca dónde dejarla: la
## pieza se consume y desaparece de la cabeza sin ir a ningún lado.
func consume() -> void:
	_finish_carry()

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

## Crea el DroppedPart Y guarda su registro en Game.state.dropped_parts
## — sin esto, lo tirado en el piso desaparecía al guardar/cargar (ver
## restore_dropped_parts, que lo llama main.gd cada vez que termina de
## cargar un mapa).
func _spawn_on_floor(at_position: Vector2) -> void:
	var world_manager := get_tree().get_first_node_in_group("world_manager")

	var record := {
		"id": Game.state.next_dropped_part_id,
		"map_path": world_manager.get_current_map_path(),
		"position": at_position,
		"part_id": _part_id,
		"icon": _icon,
	}
	Game.state.next_dropped_part_id += 1
	Game.state.dropped_parts.append(record)

	_instance_dropped_part(record, world_manager.add_to_current_map)

func _instance_dropped_part(record: Dictionary, add_to_map: Callable) -> void:
	var dropped := DroppedPartScene.instantiate()
	dropped.global_position = record.position

	# Recién al agregarlo a la escena existen los @onready del nodo
	# (Sprite2D incluido) — setup() tiene que llamarse después, nunca antes.
	add_to_map.call(dropped)
	dropped.setup(record.part_id, record.icon, record.id)

## Lo llama main.gd cada vez que termina de cargar un mapa (nuevo, o el
## inicial al arrancar) — recrea ahí las piezas que hayan quedado
## tiradas en ese mapa puntual en partidas/visitas anteriores.
func restore_dropped_parts(map: Node, map_path: String) -> void:
	for record in Game.state.dropped_parts:
		if record.map_path == map_path:
			_instance_dropped_part(record, map.add_child)

## Lo llama DroppedPart al levantarse — saca su registro para que no
## vuelva a aparecer la próxima vez que se cargue este mapa.
func remove_dropped_record(id: int) -> void:
	for i in Game.state.dropped_parts.size():
		if Game.state.dropped_parts[i].id == id:
			Game.state.dropped_parts.remove_at(i)
			dropped_part_removed.emit(id)
			return
