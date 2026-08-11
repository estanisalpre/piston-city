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

	# Si el click llegó hasta acá (no lo absorbió ningún control de UI),
	# es que fue afuera de cualquier barra de debug — le sacamos el foco
	# a lo que sea que lo tuviera (ej. el campo de texto de un SpinBox),
	# para que Tab/Escape vuelvan a funcionar normal.
	if event is InputEventMouseButton and event.pressed:
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			focused.release_focus()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		SaveManager.quit_game()

## Ruta de escena del mapa actualmente cargado bajo World. SaveManager la lee
## para saber qué guardar como "dónde quedó el jugador".
func get_current_map_path() -> String:
	var current_map := _get_current_map_node()
	return current_map.scene_file_path if current_map else ""

## Lo usa PlayerCarry para dejar cosas tiradas en el piso (ej. una
## pieza sin dónde guardarla) — quedan colgando del mapa actual, así
## que desaparecen solas si cambiás de mapa (aceptable para algo
## puramente decorativo).
func add_to_current_map(node: Node2D) -> void:
	var current_map := _get_current_map_node()
	if current_map:
		current_map.add_child(node)

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
## Diferido a propósito: quien llama a esto casi siempre lo hace desde un
## callback de físicas (Area2D.body_entered de una puerta/salida) — tocar
## el árbol ahí mismo (queue_free + add_child) rompe con "Can't change
## this state while flushing queries". call_deferred lo corre apenas
## termina el paso de física actual, sin que cada puerta tenga que
## saberlo.
func travel_to(target_map: PackedScene, spawn_marker_name: String) -> void:
	call_deferred("_travel_to_deferred", target_map, spawn_marker_name)

func _travel_to_deferred(target_map: PackedScene, spawn_marker_name: String) -> void:
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
