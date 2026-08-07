extends Area2D

var _shown_this_visit := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _shown_this_visit:
		_shown_this_visit = true
		var modal = get_tree().get_first_node_in_group("sleep_modal")
		modal.open()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_shown_this_visit = false

		var modal = get_tree().get_first_node_in_group("sleep_modal")

		if modal.visible:
			modal.close()
