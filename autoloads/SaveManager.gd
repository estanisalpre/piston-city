extends Node

signal autosave_triggered

## Lo escucha Hud para mostrar el aviso de "guardando" antes de salir —
## se emite ANTES de guardar de verdad, para que el aviso llegue a
## dibujarse un frame antes de que la ventana se cierre.
signal quit_save_started

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

## Async a propósito: Hud necesita al menos un par de frames para
## dibujar el aviso de "guardando" antes de que la ventana se cierre de
## golpe — si no, save_game()+quit() pasan en el mismo frame y nunca se
## llega a ver nada.
func quit_game() -> void:
	quit_save_started.emit()

	await get_tree().process_frame
	await get_tree().process_frame

	save_game()
	get_tree().quit()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	_capture_world_state()

	var error := ResourceSaver.save(Game.state, SAVE_PATH)

	if error != OK:
		push_error("No se pudo guardar la partida: %s" % error)

## Antes de guardar, le pregunta al mundo dónde está el jugador y en qué mapa
## (mismo patrón de "buscar por grupo" que ya usan BedTrigger/DoorTrigger).
func _capture_world_state() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var world_manager := get_tree().get_first_node_in_group("world_manager")

	if player:
		Game.state.player_position = player.global_position
	if world_manager:
		Game.state.current_map_path = world_manager.get_current_map_path()

	NpcDirector.capture_snapshot()

func load_game() -> void:
	var loaded_state := load(SAVE_PATH) as GameState

	if loaded_state:
		Game.state.money = loaded_state.money
		Game.state.owned_vehicles = loaded_state.owned_vehicles
		Game.state.selected_vehicle = loaded_state.selected_vehicle
		Game.state.day = loaded_state.day
		Game.state.time_of_day = loaded_state.time_of_day
		Game.state.skill_levels = loaded_state.skill_levels
		Game.state.skill_exp = loaded_state.skill_exp
		Game.state.active_jobs = loaded_state.active_jobs
		Game.state.pending_pickups = loaded_state.pending_pickups
		Game.state.messages = loaded_state.messages
		Game.state.current_map_path = loaded_state.current_map_path
		Game.state.player_position = loaded_state.player_position
		Game.state.npc_cooldowns = loaded_state.npc_cooldowns
		Game.state.job_cooldowns = loaded_state.job_cooldowns
		Game.state.npc_snapshots = loaded_state.npc_snapshots
