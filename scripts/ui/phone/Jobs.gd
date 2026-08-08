extends Control

@onready var back_btn: Button = $back_btn
@onready var job_list: VBoxContainer = $job_list

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_render_jobs()

func _render_jobs() -> void:
	for child in job_list.get_children():
		child.queue_free()

	for job: JobData in JobsRepository.get_all_jobs():
		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = "%s\n$%d + %d EXP" % [job.title, job.reward_money, job.reward_exp]
		label.add_theme_font_size_override("font_size", 6)
		row.add_child(label)

		var action_btn := Button.new()
		action_btn.add_theme_font_size_override("font_size", 6)
		if JobsRepository.is_job_available(job):
			action_btn.text = "Aceptar"
			action_btn.pressed.connect(_on_accept_pressed.bind(job, action_btn))
		else:
			action_btn.text = "Bloqueado (Lv %d)" % job.required_level
			action_btn.disabled = true
		row.add_child(action_btn)

		job_list.add_child(row)

func _on_accept_pressed(job: JobData, action_btn: Button) -> void:
	Game.state.money += job.reward_money
	SkillProgression.add_exp(job.required_skill, job.reward_exp)

	action_btn.text = "Listo (+$%d)" % job.reward_money
	action_btn.disabled = true

func _on_back_pressed() -> void:
	var content = get_parent()
	var home_screen: PackedScene = load("res://scenes/ui/phone/HomeScreen.tscn")

	for child in content.get_children():
		child.queue_free()

	content.add_child(home_screen.instantiate())
