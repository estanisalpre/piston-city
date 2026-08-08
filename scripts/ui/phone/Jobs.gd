extends Control

@onready var back_btn: Button = $back_btn
@onready var job_list: VBoxContainer = $job_scroll/job_list

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_render_jobs()

func _render_jobs() -> void:
	for child in job_list.get_children():
		child.queue_free()

	var available: Array[JobData] = []
	var pending: Array[JobData] = []

	for job: JobData in JobsRepository.get_all_jobs():
		if Game.state.active_jobs.has(job.id) or Game.state.pending_pickups.has(job.id):
			pending.append(job)
		elif JobsRepository.is_job_available(job):
			# Un trabajo de un nivel que el jugador todavía no tiene ni
			# siquiera se muestra (no aparece "bloqueado").
			available.append(job)

	available.shuffle()

	if not pending.is_empty():
		job_list.add_child(_make_section_label("Pendientes"))
		for job in pending:
			job_list.add_child(_make_pending_row(job))

	job_list.add_child(_make_section_label("Disponibles"))
	for job in available:
		job_list.add_child(_make_available_row(job))

func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 6)
	return label

func _make_job_texts(job: JobData, extra_line: String) -> VBoxContainer:
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label := Label.new()
	title_label.text = "%s\n$%d — %s" % [job.title, job.reward_money, extra_line]
	title_label.add_theme_font_size_override("font_size", 6)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_label.custom_minimum_size.x = 0
	texts.add_child(title_label)

	var skill_label := Label.new()
	skill_label.text = "Sube: %s +%d EXP" % [SkillIds.DISPLAY_NAMES[job.required_skill], job.reward_exp]
	skill_label.add_theme_font_size_override("font_size", 5)
	skill_label.modulate = Color(1, 1, 1, 0.7)
	skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	skill_label.custom_minimum_size.x = 0
	texts.add_child(skill_label)

	return texts

func _make_available_row(job: JobData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(_make_job_texts(job, "req. Lv %d" % job.required_level))

	var action_btn := Button.new()
	action_btn.add_theme_font_size_override("font_size", 6)
	action_btn.text = "Aceptar"
	action_btn.pressed.connect(_on_accept_pressed.bind(job.id))
	row.add_child(action_btn)

	return row

func _make_pending_row(job: JobData) -> HBoxContainer:
	var row := HBoxContainer.new()

	if Game.state.pending_pickups.has(job.id):
		row.add_child(_make_job_texts(job, "enseguida voy a por él"))
		return row

	var deadline_day: int = Game.state.active_jobs[job.id]

	if deadline_day == JobsManager.RESERVED:
		row.add_child(_make_job_texts(job, "en camino al taller..."))
		return row

	var days_left := deadline_day - Game.state.day
	row.add_child(_make_job_texts(job, "vence en %d día(s)" % days_left))

	var action_btn := Button.new()
	action_btn.add_theme_font_size_override("font_size", 6)
	action_btn.text = "Avisar al vendedor"
	action_btn.pressed.connect(_on_request_pickup_pressed.bind(job.id))
	row.add_child(action_btn)

	return row

func _on_accept_pressed(job_id: String) -> void:
	JobsManager.accept_job(job_id)
	_render_jobs()

func _on_request_pickup_pressed(job_id: String) -> void:
	JobsManager.request_pickup(job_id)
	_render_jobs()

func _on_back_pressed() -> void:
	var content = get_parent()
	var home_screen: PackedScene = load("res://scenes/ui/phone/HomeScreen.tscn")

	for child in content.get_children():
		child.queue_free()

	content.add_child(home_screen.instantiate())
