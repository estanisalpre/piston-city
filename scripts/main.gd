extends Node2D

@onready var phone = $UI/Phone
@onready var world: Node2D = $World
@onready var player: Node2D = $World/Entities/Player

## Cuál es "el mapa actual" de verdad, llevado a mano — antes se
## adivinaba recorriendo los hijos de World (el primero que no fuera
## Entities), pero eso se rompió apenas World tuvo otro hijo permanente
## además del mapa y Entities (ver FloorPlacementCursor): terminaba
## confundiéndolo con el mapa actual, lo borraba por error, y el mapa
## viejo de verdad nunca se borraba — quedaban los dos convividos.
var _current_map: Node

func _ready() -> void:
	add_to_group("world_manager")
	_current_map = world.get_node("GarageMap")
	_restore_last_location()
	PlayerCarry.restore_dropped_parts(_current_map, get_current_map_path())

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
	return _current_map.scene_file_path if _current_map else ""

## Lo usa PlayerCarry para dejar cosas tiradas en el piso (ej. una
## pieza sin dónde guardarla) — quedan colgando del mapa actual. El
## registro persistente (para que sigan ahí tras guardar/cargar) es
## responsabilidad de PlayerCarry, no de esto.
func add_to_current_map(node: Node2D) -> void:
	if _current_map:
		_current_map.add_child(node)

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
	PlayerCarry.restore_dropped_parts(new_map, new_map.scene_file_path)

	var spawn_marker := new_map.find_child(spawn_marker_name, true, false)
	if spawn_marker:
		player.global_position = spawn_marker.global_position

## Devuelve el mapa nuevo ya agregado a World. free() en vez de
## queue_free() a propósito: esto ya corre diferido (ver
## _travel_to_deferred), un momento seguro para tocar el árbol, así que
## podemos borrar el mapa viejo al instante en vez de recién al final
## del frame — sin esto, los dos mapas convivían un frame (o más) como
## hijos de World, superpuestos, y a veces se llegaba a notar.
func _swap_map(target_map: PackedScene) -> Node:
	if _current_map:
		_current_map.free()

	var new_map := target_map.instantiate()
	world.add_child(new_map)
	_current_map = new_map
	return new_map
