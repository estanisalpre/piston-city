extends CanvasModulate

func _ready() -> void:
	TimeManager.day_night_color_changed.connect(_on_color_changed)

func _on_color_changed(new_color: Color) -> void:
	color = new_color
