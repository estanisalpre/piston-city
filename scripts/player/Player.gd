extends CharacterBody2D

const SPEED := 70.0

func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * SPEED
	move_and_slide()

func _ready():
	global_position = get_tree().current_scene.get_node("World/SpawnPlayer").global_position
