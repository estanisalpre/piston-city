extends CharacterBody2D

const SPEED := 300.0 # 100.0 es el movimiento base

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var last_direction := Vector2.DOWN


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = input_direction * SPEED
	move_and_slide()

	_update_animation(input_direction)


func _update_animation(input_direction: Vector2) -> void:
	if input_direction != Vector2.ZERO:
		last_direction = input_direction

	var animation_name := _get_idle_animation(last_direction)

	if input_direction != Vector2.ZERO:
		if abs(input_direction.x) > abs(input_direction.y):
			animation_name = "running_right" if input_direction.x > 0 else "running_left"
		else:
			animation_name = "running_down" if input_direction.y > 0 else "running_up"

	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)


func _get_idle_animation(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		return "idle_right" if direction.x > 0 else "idle_left"
	return "idle_down" if direction.y > 0 else "idle_up"