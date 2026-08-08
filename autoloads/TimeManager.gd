extends Node

signal minute_changed(hour: int, minute: int)
signal day_changed(day: int)
signal day_night_color_changed(color: Color)
signal heat_strength_changed(strength: float)
signal day_phase_changed(is_day: bool)

const MINUTES_PER_DAY := 1440.0
const REAL_SECONDS_PER_DAY := 1440.0
const DAYS_PER_SEASON := 28
const DAWN_RAMP_MINUTES := 30.0

const HEAT_SEASON := "Verano"
const HEAT_START := 720.0
const HEAT_END := 1050.0
const HEAT_RAMP_MINUTES := 30.0

const WAKE_TIME := 390.0
const SLEEP_ALLOWED_FROM := 1200.0

const SEASON_NAMES := ["Primavera", "Verano", "Otoño", "Invierno"]

# Cada estación define su propio horario de luz:
# - dawn_peak: hora en la que se ve el color de amanecer con más fuerza.
# - dawn_end: hora en la que ya es de día completo.
# - dusk_start: hora en la que empieza a atardecer.
# - dusk_peak: hora del tono más fuerte del atardecer (= dusk_start si la
#   estación no tiene un tono propio de atardecer, y pasa directo día->noche).
# - dusk_end: hora en la que ya es de noche completa.
const SEASON_SCHEDULES := {
	"Primavera": {
		"dawn_peak": 390.0, "dawn_end": 420.0,
		"dusk_start": 1050.0, "dusk_peak": 1080.0, "dusk_end": 1110.0,
		"dawn_color": Color(1.0, 0.78, 0.62), "day_color": Color(1.02, 1.0, 0.98),
		"dusk_color": Color(1.0, 0.6, 0.55), "night_color": Color(0.42, 0.42, 0.6),
	},
	"Verano": {
		"dawn_peak": 330.0, "dawn_end": 390.0,
		"dusk_start": 1050.0, "dusk_peak": 1110.0, "dusk_end": 1170.0,
		"dawn_color": Color(1.0, 0.75, 0.45), "day_color": Color(1.0, 1.0, 1.0),
		"dusk_color": Color(1.0, 0.55, 0.35), "night_color": Color(0.55, 0.55, 0.7),
	},
	"Otoño": {
		"dawn_peak": 390.0, "dawn_end": 420.0,
		"dusk_start": 1050.0, "dusk_peak": 1080.0, "dusk_end": 1110.0,
		"dawn_color": Color(0.95, 0.7, 0.5), "day_color": Color(1.0, 0.95, 0.85),
		"dusk_color": Color(0.95, 0.55, 0.35), "night_color": Color(0.4, 0.42, 0.58),
	},
	"Invierno": {
		"dawn_peak": 480.0, "dawn_end": 510.0,
		"dusk_start": 1020.0, "dusk_peak": 1020.0, "dusk_end": 1080.0,
		"dawn_color": Color(0.6, 0.7, 0.95), "day_color": Color(0.85, 0.9, 1.0),
		"dusk_color": Color(0.85, 0.9, 1.0), "night_color": Color(0.35, 0.4, 0.6),
	},
}

var _last_minute := -1
var _last_is_day := true

func _ready() -> void:
	_emit_color()
	_last_is_day = is_daytime()

func _process(delta: float) -> void:
	var minutes_per_second := MINUTES_PER_DAY / REAL_SECONDS_PER_DAY

	Game.state.time_of_day += delta * minutes_per_second

	if Game.state.time_of_day >= MINUTES_PER_DAY:
		Game.state.time_of_day -= MINUTES_PER_DAY
		Game.state.day += 1
		day_changed.emit(Game.state.day)

	var current_minute := int(Game.state.time_of_day)

	if current_minute != _last_minute:
		_last_minute = current_minute
		minute_changed.emit(get_hour(), get_minute())
		_emit_color()
		_emit_heat_strength()
		_emit_day_phase_if_changed()

func set_debug_time(season_index: int, day_in_season: int, hour: int, minute: int) -> void:
	var year := get_year()

	Game.state.day = (year - 1) * DAYS_PER_SEASON * SEASON_NAMES.size() + season_index * DAYS_PER_SEASON + day_in_season
	Game.state.time_of_day = hour * 60.0 + minute

	_last_minute = int(Game.state.time_of_day)
	day_changed.emit(Game.state.day)
	minute_changed.emit(get_hour(), get_minute())
	_emit_color()
	_emit_heat_strength()
	_last_is_day = not is_daytime()
	_emit_day_phase_if_changed()

func is_daytime() -> bool:
	var schedule: Dictionary = SEASON_SCHEDULES[get_season()]
	var t: float = Game.state.time_of_day

	return t >= schedule.dawn_end and t < schedule.dusk_end

func can_sleep_now() -> bool:
	var t: float = Game.state.time_of_day
	return t >= SLEEP_ALLOWED_FROM or t < WAKE_TIME

func advance_to_next_morning() -> void:
	Game.state.day += 1
	Game.state.time_of_day = WAKE_TIME

	_last_minute = int(WAKE_TIME)
	day_changed.emit(Game.state.day)
	minute_changed.emit(get_hour(), get_minute())
	_emit_color()
	_emit_heat_strength()
	_last_is_day = not is_daytime()
	_emit_day_phase_if_changed()

## Minuto de juego absoluto (día*1440 + hora del día), útil para
## agendar cosas a futuro (ver JobsManager/JobEncounterSpawner) sin
## tener que lidiar con el cruce de medianoche a mano.
func get_total_minutes() -> float:
	return Game.state.day * MINUTES_PER_DAY + Game.state.time_of_day

func get_hour() -> int:
	return int(Game.state.time_of_day / 60.0)

func get_minute() -> int:
	return int(Game.state.time_of_day) % 60

func get_season() -> String:
	return SEASON_NAMES[((Game.state.day - 1) / DAYS_PER_SEASON) % SEASON_NAMES.size()]

func get_month_day() -> int:
	return ((Game.state.day - 1) % DAYS_PER_SEASON) + 1

func get_year() -> int:
	return ((Game.state.day - 1) / (DAYS_PER_SEASON * SEASON_NAMES.size())) + 1

func _emit_day_phase_if_changed() -> void:
	var current_is_day := is_daytime()

	if current_is_day != _last_is_day:
		_last_is_day = current_is_day
		day_phase_changed.emit(current_is_day)

func _emit_color() -> void:
	day_night_color_changed.emit(_calculate_color())

func _emit_heat_strength() -> void:
	heat_strength_changed.emit(_calculate_heat_strength())

func _calculate_heat_strength() -> float:
	if get_season() != HEAT_SEASON:
		return 0.0

	var t: float = Game.state.time_of_day
	var ramp_in_start := HEAT_START - HEAT_RAMP_MINUTES
	var ramp_out_start := HEAT_END - HEAT_RAMP_MINUTES

	if t < ramp_in_start or t >= HEAT_END:
		return 0.0
	if t < HEAT_START:
		return (t - ramp_in_start) / HEAT_RAMP_MINUTES
	if t < ramp_out_start:
		return 1.0
	return 1.0 - (t - ramp_out_start) / HEAT_RAMP_MINUTES

func _calculate_color() -> Color:
	var schedule: Dictionary = SEASON_SCHEDULES[get_season()]
	var t: float = Game.state.time_of_day

	var dawn_ramp_start: float = schedule.dawn_peak - DAWN_RAMP_MINUTES
	var dawn_peak: float = schedule.dawn_peak
	var dawn_end: float = schedule.dawn_end
	var dusk_start: float = schedule.dusk_start
	var dusk_peak: float = schedule.dusk_peak
	var dusk_end: float = schedule.dusk_end

	var night: Color = schedule.night_color
	var dawn: Color = schedule.dawn_color
	var day: Color = schedule.day_color
	var dusk: Color = schedule.dusk_color

	if t < dawn_ramp_start or t >= dusk_end:
		return night
	if t < dawn_peak:
		return night.lerp(dawn, (t - dawn_ramp_start) / (dawn_peak - dawn_ramp_start))
	if t < dawn_end:
		return dawn.lerp(day, (t - dawn_peak) / (dawn_end - dawn_peak))
	if t < dusk_start:
		return day
	if t < dusk_peak:
		return day.lerp(dusk, (t - dusk_start) / (dusk_peak - dusk_start))
	return dusk.lerp(night, (t - dusk_peak) / (dusk_end - dusk_peak))
