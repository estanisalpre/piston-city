extends CanvasLayer

signal midpoint_reached

const FADE_DURATION := 1.2
const LOADING_DURATION := 1.5

@onready var fade_rect: ColorRect = $FadeRect
@onready var loading_label: Label = $LoadingLabel

func _ready() -> void:
	add_to_group("sleep_transition")
	hide()
	fade_rect.color.a = 0.0
	loading_label.hide()

func play() -> void:
	show()

	var fade_out_tween := create_tween()
	fade_out_tween.tween_property(fade_rect, "color:a", 1.0, FADE_DURATION)
	await fade_out_tween.finished

	loading_label.show()
	midpoint_reached.emit()
	await get_tree().create_timer(LOADING_DURATION).timeout
	loading_label.hide()

	var fade_in_tween := create_tween()
	fade_in_tween.tween_property(fade_rect, "color:a", 0.0, FADE_DURATION)
	await fade_in_tween.finished

	hide()
