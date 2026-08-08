extends Node2D

@onready var phone = $UI/Phone
@onready var world: Node2D = $World
@onready var player: Node2D = $World/Entities/Player

func _ready() -> void:
	add_to_group("world_manager")
	_restore_last_location()

func _unhandled_input(event):
	if event.is_action_pressed("phone_toggle"):
		phone.toggle()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		SaveManager.quit_game()

## Ruta de escena del mapa actualmente cargado bajo World. SaveManager la lee
## para saber qué guardar como "dónde quedó el jugador".
func get_current_map_path() -> String:
	var current_map := _get_current_map_node()
	return current_map.scene_file_path if current_map else ""

## Al arrancar: si hay partida guardada, vuelve exactamente a donde quedó
## (mapa + posición). Si es partida nueva (current_map_path == ""), se queda
## con el mapa que ya trae Main.tscn y aparece en la cama del garage.
func _restore_last_location() -> void:
	if Game.state.current_map_path == "":
		player.global_position = world.get_node("GarageMap/SpawnPlayer").global_position
		return

	if Game.state.current_map_path != get_current_map_path():
		_swap_map(load(Game.state.current_map_path))

	player.global_position = Game.state.player_position

## Saca el mapa actual y pone el de destino en su lugar, sin tocar Entities
## (el Player nunca se destruye, solo se reposiciona en el marcador de spawn).
func travel_to(target_map: PackedScene, spawn_marker_name: String) -> void:
	var new_map := _swap_map(target_map)

	var spawn_marker := new_map.find_child(spawn_marker_name, true, false)
	if spawn_marker:
		player.global_position = spawn_marker.global_position

## Devuelve el mapa nuevo ya agregado a World. queue_free() no borra al mapa
## viejo en el acto (recién al final del frame), así que hay que quedarse con
## la referencia al nuevo en vez de volver a buscar "el mapa actual" después
## de llamar a esta función — mientras tanto conviven los dos como hijos de
## World y _get_current_map_node() podría devolver el que se está yendo.
func _swap_map(target_map: PackedScene) -> Node:
	var current_map := _get_current_map_node()
	if current_map:
		current_map.queue_free()

	var new_map := target_map.instantiate()
	world.add_child(new_map)
	return new_map

func _get_current_map_node() -> Node:
	var entities := player.get_parent()

	for map_node in world.get_children():
		if map_node != entities and not map_node.is_queued_for_deletion():
			return map_node

	return null
