extends CanvasLayer

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var autosave_label: Label = $AutosaveLabel

func _ready() -> void:
	Game.state.money_changed.connect(_on_money_changed)
	_on_money_changed(Game.state.money)

	SaveManager.autosave_triggered.connect(_on_autosave_triggered)

	TimeManager.minute_changed.connect(_on_minute_changed)
	_on_minute_changed(TimeManager.get_hour(), TimeManager.get_minute())

func _on_money_changed(new_amount: int) -> void:
	money_label.text = "$" + str(new_amount)

func _on_minute_changed(hour: int, minute: int) -> void:
	var hour_text := str(hour).pad_zeros(2)
	var minute_text := str(minute).pad_zeros(2)
	var day_text := TimeManager.get_month_day()
	var season_text := TimeManager.get_season()

	time_label.text = "%s:%s - Día %s, %s" % [hour_text, minute_text, day_text, season_text]

func _on_autosave_triggered() -> void:
	autosave_label.modulate.a = 1.0
	autosave_label.show()

	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(autosave_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(autosave_label.hide)
