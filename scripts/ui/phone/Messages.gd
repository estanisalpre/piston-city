extends Control

@onready var back_btn: Button = $back_btn
@onready var message_list: VBoxContainer = $message_scroll/message_list

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_render_messages()
	_mark_all_read()

func _render_messages() -> void:
	for child in message_list.get_children():
		child.queue_free()

	var messages := Game.state.messages.duplicate()
	messages.reverse()

	if messages.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No tenés mensajes."
		empty_label.add_theme_font_size_override("font_size", 6)
		message_list.add_child(empty_label)
		return

	for message: Dictionary in messages:
		var row := VBoxContainer.new()

		var title_label := Label.new()
		title_label.text = "Día %d — %s" % [message.get("day", 0), message.get("title", "")]
		title_label.add_theme_font_size_override("font_size", 6)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		title_label.custom_minimum_size.x = 0
		row.add_child(title_label)

		var body_label := Label.new()
		body_label.text = message.get("body", "")
		body_label.add_theme_font_size_override("font_size", 5)
		body_label.modulate = Color(1, 1, 1, 0.7)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(body_label)

		message_list.add_child(row)

func _mark_all_read() -> void:
	for message: Dictionary in Game.state.messages:
		message["read"] = true

func _on_back_pressed() -> void:
	var content = get_parent()
	var home_screen: PackedScene = load("res://scenes/ui/phone/HomeScreen.tscn")

	for child in content.get_children():
		child.queue_free()

	content.add_child(home_screen.instantiate())
