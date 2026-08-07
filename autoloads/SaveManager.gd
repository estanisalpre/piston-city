extends Node

signal autosave_triggered

const SAVE_PATH := "user://savegame.tres"
const AUTOSAVE_INTERVAL := 10.0

var autosave_timer: Timer

func _ready() -> void:
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(autosave_timer)
	autosave_timer.start()

	if has_save():
		load_game()

func _on_autosave_timeout() -> void:
	save_game()
	autosave_triggered.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func quit_game() -> void:
	save_game()
	get_tree().quit()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var error := ResourceSaver.save(Game.state, SAVE_PATH)

	if error != OK:
		push_error("No se pudo guardar la partida: %s" % error)

func load_game() -> void:
	var loaded_state := load(SAVE_PATH) as GameState

	if loaded_state:
		Game.state.money = loaded_state.money
		Game.state.owned_vehicles = loaded_state.owned_vehicles
		Game.state.selected_vehicle = loaded_state.selected_vehicle
		Game.state.day = loaded_state.day
		Game.state.time_of_day = loaded_state.time_of_day
