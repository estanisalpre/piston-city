extends CanvasLayer

const SLIDE_DURATION := 0.3

@onready var panel: Control = $Panel
@onready var message_label: Label = $Panel/VBox/MessageLabel
@onready var yes_button: Button = $Panel/VBox/Buttons/YesButton
@onready var no_button: Button = $Panel/VBox/Buttons/NoButton

var _hidden_offset_top: float
var _shown_offset_top: float
var _player: Node2D

func _ready() -> void:
	add_to_group("sleep_modal")

	_shown_offset_top = panel.offset_top
	_hidden_offset_top = 0.0

	panel.offset_top = _hidden_offset_top
	hide()

	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)

func open() -> void:
	_player = get_tree().get_first_node_in_group("player")

	if _player:
		_player.set_physics_process(false)

	if SleepManager.can_sleep_now():
		message_label.text = "¿Quieres ir a descansar?"
		yes_button.show()
		no_button.text = "No"
	else:
		message_label.text = "Todavía es muy temprano para dormir."
		yes_button.hide()
		no_button.text = "Cerrar"

	show()

	var tween := create_tween()
	tween.tween_property(panel, "offset_top", _shown_offset_top, SLIDE_DURATION)

func close() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "offset_top", _hidden_offset_top, SLIDE_DURATION)
	await tween.finished

	hide()

	if _player:
		_player.set_physics_process(true)

func _on_yes_pressed() -> void:
	await close()
	SleepManager.sleep()

func _on_no_pressed() -> void:
	close()
