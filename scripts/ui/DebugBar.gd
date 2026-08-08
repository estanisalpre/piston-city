extends CanvasLayer

@onready var season_option: OptionButton = $Bar/Row/SeasonOption
@onready var day_spin: SpinBox = $Bar/Row/DaySpin
@onready var hour_spin: SpinBox = $Bar/Row/HourSpin
@onready var minute_spin: SpinBox = $Bar/Row/MinuteSpin
@onready var apply_button: Button = $Bar/Row/ApplyButton

func _ready() -> void:
	for season_name in TimeManager.SEASON_NAMES:
		season_option.add_item(season_name)

	season_option.select(TimeManager.SEASON_NAMES.find(TimeManager.get_season()))
	day_spin.value = TimeManager.get_month_day()
	hour_spin.value = TimeManager.get_hour()
	minute_spin.value = TimeManager.get_minute()

	apply_button.pressed.connect(_on_apply_pressed)

	# El SpinBox tiene un LineEdit interno propio que sí puede agarrar
	# el foco de teclado aunque el SpinBox tenga focus_mode = 0.
	for spin in [day_spin, hour_spin, minute_spin]:
		spin.get_line_edit().focus_mode = Control.FOCUS_NONE

func _on_apply_pressed() -> void:
	TimeManager.set_debug_time(
		season_option.selected,
		int(day_spin.value),
		int(hour_spin.value),
		int(minute_spin.value)
	)
