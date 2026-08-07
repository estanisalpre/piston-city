extends Area2D

@export var wall_path: NodePath
@export var z_index_wall_behind_player := 9
@export var z_index_wall_in_front_of_player := 11

var wall: CanvasItem

func _ready() -> void:
	wall = get_node(wall_path)
	wall.z_index = z_index_wall_behind_player

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		wall.z_index = z_index_wall_in_front_of_player

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		wall.z_index = z_index_wall_behind_player
