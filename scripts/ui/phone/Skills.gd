extends Control

@onready var back_btn: Button = $back_btn
@onready var skill_list: VBoxContainer = $skill_scroll/skill_list

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_render_skills()

func _render_skills() -> void:
	for child in skill_list.get_children():
		child.queue_free()

	for skill_id in SkillIds.ALL:
		var level: int = Game.state.skill_levels.get(skill_id, 1)
		var exp: int = Game.state.skill_exp.get(skill_id, 0)
		var next_cap := SkillProgression.exp_to_next_level(level)

		var row := VBoxContainer.new()

		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 6)
		name_label.text = "%s — Nivel %d/%d" % [SkillIds.DISPLAY_NAMES[skill_id], level, SkillProgression.MAX_LEVEL]
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_label.custom_minimum_size.x = 0
		row.add_child(name_label)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 4)
		bar.show_percentage = false
		if next_cap == 0:
			bar.max_value = 1
			bar.value = 1
		else:
			bar.max_value = next_cap
			bar.value = exp
		row.add_child(bar)

		var exp_label := Label.new()
		exp_label.add_theme_font_size_override("font_size", 6)
		exp_label.text = "MAX" if next_cap == 0 else "EXP %d/%d" % [exp, next_cap]
		row.add_child(exp_label)

		skill_list.add_child(row)

func _on_back_pressed() -> void:
	var content = get_parent()
	var home_screen: PackedScene = load("res://scenes/ui/phone/HomeScreen.tscn")

	for child in content.get_children():
		child.queue_free()

	content.add_child(home_screen.instantiate())
