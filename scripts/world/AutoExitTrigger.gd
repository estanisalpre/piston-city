extends Area2D

## Zona que te saca del mapa apenas la pisás, sin click — para salidas
## simples (ej. la puerta interior de un local) donde no hace falta la
## confirmación de un click derecho, a diferencia de DoorTrigger.
## Reusable — instanciar AutoExitTrigger.tscn y configurar Target Map
## Path + Spawn Marker Name desde el Inspector (igual que DoorTrigger).

## String en vez de PackedScene: mismo motivo que DoorTrigger (evitar
## dependencia circular de recursos entre mapas que se apuntan entre sí).
@export_file("*.tscn") var target_map_path: String
@export var spawn_marker_name := "PlayerSpawn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	var world_manager = get_tree().get_first_node_in_group("world_manager")
	world_manager.travel_to(load(target_map_path), spawn_marker_name)
