extends Control

@onready var apps_grid: GridContainer = $apps_grid

func _ready() -> void:
	for app_icon in apps_grid.get_children():
		app_icon.app_selected.connect(_on_app_selected)

func _on_app_selected(app_scene: PackedScene) -> void:
	var content = get_parent()

	for child in content.get_children():
		child.queue_free()

	content.add_child(app_scene.instantiate())
