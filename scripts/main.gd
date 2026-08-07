extends Node2D

@onready var phone = $UI/Phone

func _unhandled_input(event):
	if event.is_action_pressed("phone_toggle"):
		phone.toggle()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		SaveManager.quit_game()