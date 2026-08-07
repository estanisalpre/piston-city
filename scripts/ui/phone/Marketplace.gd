extends Control

@onready var back_btn: Button = $back_btn

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	var content = get_parent()
	var home_screen: PackedScene = load("res://scenes/ui/phone/HomeScreen.tscn")

	for child in content.get_children():
		child.queue_free()

	content.add_child(home_screen.instantiate())
