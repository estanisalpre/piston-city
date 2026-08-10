extends CanvasLayer

## Cartel de opciones al interactuar con un NPC fijo (ver
## NpcInteraction) — a diferencia de DialogueModal (una sola vía), acá
## el jugador elige entre botones. Reusable: cualquiera puede pedirle
## show_options([...]) y esperar option_chosen.

signal option_chosen(option: String)

@onready var button_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer

func _ready() -> void:
	add_to_group("options_modal")
	hide()

func show_options(options: Array[String]) -> void:
	for child in button_container.get_children():
		child.queue_free()

	for option in options:
		var button := Button.new()
		button.text = option
		button.pressed.connect(_on_option_pressed.bind(option))
		button_container.add_child(button)

	show()

func _on_option_pressed(option: String) -> void:
	hide()
	option_chosen.emit(option)
