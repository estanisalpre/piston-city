extends CanvasLayer

@onready var season_option: OptionButton = $Bar/Columns/Row/SeasonOption
@onready var day_spin: SpinBox = $Bar/Columns/Row/DaySpin
@onready var hour_spin: SpinBox = $Bar/Columns/Row/HourSpin
@onready var minute_spin: SpinBox = $Bar/Columns/Row/MinuteSpin
@onready var apply_button: Button = $Bar/Columns/Row/ApplyButton
@onready var send_home_button: Button = $Bar/Columns/ButtonsRow/SendHomeButton
@onready var add_tire_button: Button = $Bar/Columns/ButtonsRow/AddTireButton
@onready var remove_tire_button: Button = $Bar/Columns/ButtonsRow/RemoveTireButton
@onready var add_bumper_button: Button = $Bar/Columns/ButtonsRow/AddBumperButton
@onready var respawn_garage_button: Button = $Bar/Columns/ButtonsRow/RespawnGarageButton
@onready var reset_all_button: Button = $Bar/Columns/ButtonsRow/ResetAllButton

func _ready() -> void:
	for season_name in TimeManager.SEASON_NAMES:
		season_option.add_item(season_name)

	season_option.select(TimeManager.SEASON_NAMES.find(TimeManager.get_season()))
	day_spin.value = TimeManager.get_month_day()
	hour_spin.value = TimeManager.get_hour()
	minute_spin.value = TimeManager.get_minute()

	apply_button.pressed.connect(_on_apply_pressed)
	send_home_button.pressed.connect(_on_send_home_pressed)
	add_tire_button.pressed.connect(_on_add_tire_pressed)
	remove_tire_button.pressed.connect(_on_remove_tire_pressed)
	add_bumper_button.pressed.connect(_on_add_bumper_pressed)
	respawn_garage_button.pressed.connect(_on_respawn_garage_pressed)
	reset_all_button.pressed.connect(_on_reset_all_pressed)

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

func _on_send_home_pressed() -> void:
	NpcDirector.debug_send_all_home()

func _on_add_tire_pressed() -> void:
	PartsInventory.add_part("neumatico", 1)
	print("neumatico: %d" % PartsInventory.get_quantity("neumatico"))

func _on_remove_tire_pressed() -> void:
	PartsInventory.remove_part("neumatico", 1)
	print("neumatico: %d" % PartsInventory.get_quantity("neumatico"))

## Provisorio mientras no exista un local que venda parachoques (ver
## TireShop/ShopItemRow para cuando llegue ese local real) — deposita
## directo en la misma caja grande que ya tiene "parachoques" en su
## Part Icons, igual que hace una compra real.
func _on_add_bumper_pressed() -> void:
	var deposited := PartsInventory.deposit_in_zone("large_box_1", 6, "parachoques")
	print("parachoques depositado: %s" % deposited)

func _on_respawn_garage_pressed() -> void:
	var world_manager = get_tree().get_first_node_in_group("world_manager")
	world_manager.travel_to(load("res://scenes/garage/GarageMap.tscn"), "PlayerSpawn")

func _on_reset_all_pressed() -> void:
	SaveManager.debug_reset_everything()
