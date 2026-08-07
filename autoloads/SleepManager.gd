extends Node

func can_sleep_now() -> bool:
	return TimeManager.can_sleep_now()

func sleep() -> void:
	var player := get_tree().get_first_node_in_group("player")

	if player:
		player.set_physics_process(false)

	var transition: CanvasLayer = get_tree().get_first_node_in_group("sleep_transition")

	if not transition.midpoint_reached.is_connected(_on_transition_midpoint):
		transition.midpoint_reached.connect(_on_transition_midpoint, CONNECT_ONE_SHOT)

	await transition.play()

	if player:
		player.set_physics_process(true)

func _on_transition_midpoint() -> void:
	TimeManager.advance_to_next_morning()
	SaveManager.save_game()
