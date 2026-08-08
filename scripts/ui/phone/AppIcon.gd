extends Button
class_name AppIcon

@export var app_name: String = "App"
@export var app_icon: Texture2D
@export var app_scene: PackedScene

signal app_selected(scene: PackedScene)

@onready var icon_rect: TextureRect = $layout/icon
@onready var name_label: Label = $layout/app_name
@onready var badge_label: Label = $layout/icon/badge

func _ready() -> void:
	icon_rect.texture = app_icon
	name_label.text = app_name
	pressed.connect(_on_pressed)
	badge_label.hide()

func _on_pressed() -> void:
	app_selected.emit(app_scene)

func set_badge_count(count: int) -> void:
	if count <= 0:
		badge_label.hide()
	else:
		badge_label.text = str(count)
		badge_label.show()
