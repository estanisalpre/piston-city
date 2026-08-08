extends Control

@onready var apps_grid: GridContainer = $apps_grid

func _ready() -> void:
	for app_icon in apps_grid.get_children():
		app_icon.app_selected.connect(_on_app_selected)

	_refresh_notifications()

func _refresh_notifications() -> void:
	var messages_icon: AppIcon = apps_grid.get_node_or_null("Messages")
	if messages_icon:
		messages_icon.set_badge_count(MessagesCenter.unread_count())

func _on_app_selected(app_scene: PackedScene) -> void:
	var content = get_parent()

	for child in content.get_children():
		child.queue_free()

	content.add_child(app_scene.instantiate())
