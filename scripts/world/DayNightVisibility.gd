extends Node

@export var day_node_path: NodePath
@export var night_node_path: NodePath

var day_node: CanvasItem
var night_node: CanvasItem

func _ready() -> void:
	day_node = get_node(day_node_path)
	night_node = get_node(night_node_path)

	TimeManager.day_phase_changed.connect(_on_day_phase_changed)
	_on_day_phase_changed(TimeManager.is_daytime())

func _on_day_phase_changed(is_day: bool) -> void:
	day_node.visible = is_day
	night_node.visible = not is_day
