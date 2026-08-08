extends Area2D

## Puerta interactuable: parado cerca + click derecho SOBRE la puerta viaja a
## otro mapa. Reusable — instanciar DoorTrigger.tscn en cualquier puerta y
## configurar Target Map Path + Spawn Marker Name desde el Inspector (igual
## que WallBehindTrigger). El CollisionShape2D cumple doble función: detecta
## la cercanía del jugador (body_entered) y define el área clickeable
## (input_event) — por eso tiene que quedar del tamaño del sprite de la puerta.

## String en vez de PackedScene a propósito: GarageMap y CityMap se apuntan
## entre sí, y precargar ambos como PackedScene crea una dependencia circular
## de recursos (mismo motivo por el que Marketplace.gd usa load() en vez de
## preload() para volver a HomeScreen). load() en el momento del click rompe el ciclo.
@export_file("*.tscn") var target_map_path: String
@export var spawn_marker_name := "PlayerSpawn"

var _player_in_range := false

func _ready() -> void:
	input_pickable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _player_in_range:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var world_manager = get_tree().get_first_node_in_group("world_manager")
		world_manager.travel_to(load(target_map_path), spawn_marker_name)
