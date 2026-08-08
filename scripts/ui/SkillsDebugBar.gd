extends CanvasLayer

const EXP_STEP := 50

@onready var skill_option: OptionButton = $Bar/Row/SkillOption
@onready var status_label: Label = $Bar/Row/StatusLabel
@onready var exp_up_button: Button = $Bar/Row/ExpUpButton
@onready var exp_down_button: Button = $Bar/Row/ExpDownButton
@onready var level_up_button: Button = $Bar/Row/LevelUpButton
@onready var level_down_button: Button = $Bar/Row/LevelDownButton
@onready var clear_jobs_button: Button = $Bar/Row/ClearJobsButton

func _ready() -> void:
	for skill_id in SkillIds.ALL:
		skill_option.add_item(SkillIds.DISPLAY_NAMES[skill_id])

	skill_option.item_selected.connect(_on_skill_selected)
	exp_up_button.pressed.connect(_on_exp_up_pressed)
	exp_down_button.pressed.connect(_on_exp_down_pressed)
	level_up_button.pressed.connect(_on_level_up_pressed)
	level_down_button.pressed.connect(_on_level_down_pressed)
	clear_jobs_button.pressed.connect(_on_clear_jobs_pressed)

	_refresh_status()

func _selected_skill_id() -> String:
	return SkillIds.ALL[skill_option.selected]

func _refresh_status() -> void:
	var skill_id := _selected_skill_id()
	var level: int = Game.state.skill_levels.get(skill_id, 1)
	var exp: int = Game.state.skill_exp.get(skill_id, 0)
	var next_cap := SkillProgression.exp_to_next_level(level)

	if next_cap == 0:
		status_label.text = "Nivel %d (máximo)" % level
	else:
		status_label.text = "Nivel %d — EXP %d/%d" % [level, exp, next_cap]

func _on_skill_selected(_index: int) -> void:
	_refresh_status()

func _on_exp_up_pressed() -> void:
	SkillProgression.add_exp(_selected_skill_id(), EXP_STEP)
	_refresh_status()

func _on_exp_down_pressed() -> void:
	SkillProgression.add_exp(_selected_skill_id(), -EXP_STEP)
	_refresh_status()

func _on_level_up_pressed() -> void:
	var skill_id := _selected_skill_id()
	var level: int = Game.state.skill_levels.get(skill_id, 1)
	SkillProgression.debug_set_level(skill_id, level + 1)
	_refresh_status()

func _on_level_down_pressed() -> void:
	var skill_id := _selected_skill_id()
	var level: int = Game.state.skill_levels.get(skill_id, 1)
	SkillProgression.debug_set_level(skill_id, level - 1)
	_refresh_status()

func _on_clear_jobs_pressed() -> void:
	JobsManager.clear_all_jobs()
