extends Node

## Dueño del ciclo de vida completo de un encargo (ver
## docs/habilidades-y-escuela.md sección 8):
##
## aceptar -> (30 min de juego) -> entrega en el garage -> se trabaja
## -> "Avisar al vendedor" -> (según horario del taller) -> retiro y pago.
##
## La app "Trabajos" del celular y JobEncounterSpawner (el mundo) solo
## llaman a estas funciones, nunca tocan Game.state.active_jobs /
## scheduled_deliveries / pending_pickups directamente.

const DEADLINE_DAYS := 7
const RESERVED := -1

const DELIVERY_DELAY_MINUTES := 30.0

## El cliente no llega siempre puntual — entre 1:00 y 1:30hs.
const PICKUP_DELAY_MIN_MINUTES := 60.0
const PICKUP_DELAY_MAX_MINUTES := 90.0

## Horario fijo del taller — fuera de este rango el cliente no viene
## a retirar el auto, espera a que abra.
const SHOP_OPEN_MINUTE := 480.0   # 08:00
const SHOP_CLOSE_MINUTE := 1200.0 # 20:00

signal job_completed(job_id: String)
signal job_expired(job_id: String)
signal jobs_cleared

func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)

func accept_job(job_id: String) -> void:
	Game.state.active_jobs[job_id] = RESERVED
	Game.state.scheduled_deliveries[job_id] = TimeManager.get_total_minutes() + DELIVERY_DELAY_MINUTES

## Lo llama el mundo (JobEncounterSpawner) cuando el NPC de bienvenida
## terminó su visita y se fue — recién ahí arranca el plazo de 7 días.
func start_job_clock(job_id: String) -> void:
	if Game.state.active_jobs.get(job_id) == RESERVED:
		Game.state.active_jobs[job_id] = Game.state.day + DEADLINE_DAYS

## Lo llama Jobs.gd al tocar "Avisar al vendedor". Todavía no paga —
## solo agenda cuándo viene el cliente a buscar el auto, respetando el
## horario del taller.
func request_pickup(job_id: String) -> void:
	Game.state.active_jobs.erase(job_id)
	Game.state.pending_pickups[job_id] = _compute_pickup_arrival(TimeManager.get_total_minutes())

## Si el taller está abierto, el cliente viene 1 hora después. Si ya
## cerró o todavía no abrió, viene recién a la apertura (hoy o mañana
## según corresponda).
func _compute_pickup_arrival(now: float) -> float:
	var minutes_per_day := TimeManager.MINUTES_PER_DAY
	var time_of_day := fmod(now, minutes_per_day)
	var day_start := now - time_of_day

	if time_of_day < SHOP_OPEN_MINUTE:
		return day_start + SHOP_OPEN_MINUTE
	if time_of_day >= SHOP_CLOSE_MINUTE:
		return day_start + minutes_per_day + SHOP_OPEN_MINUTE
	return now + randf_range(PICKUP_DELAY_MIN_MINUTES, PICKUP_DELAY_MAX_MINUTES)

## Recién acá se paga de verdad — lo llama JobEncounterSpawner cuando
## el NPC de la entrega llega y termina el diálogo de agradecimiento.
func finish_pickup(job_id: String) -> void:
	var job := JobsRepository.get_job(job_id)
	Game.state.pending_pickups.erase(job_id)
	Game.state.wanderer_progress.erase(job_id)
	Game.state.wanderer_updated_at.erase(job_id)
	Game.state.npc_busy_in_garage.erase(job_id)

	if job:
		Game.state.money += job.reward_money
		SkillProgression.add_exp(job.required_skill, job.reward_exp)

	job_completed.emit(job_id)

## Debug: borra todos los encargos (reservados, en curso o esperando
## retiro), sin pagar ni penalizar. Es solo para dejar el estado
## limpio al probar.
func clear_all_jobs() -> void:
	Game.state.active_jobs.clear()
	Game.state.scheduled_deliveries.clear()
	Game.state.pending_pickups.clear()
	Game.state.wanderer_progress.clear()
	Game.state.wanderer_updated_at.clear()
	Game.state.npc_busy_in_garage.clear()
	jobs_cleared.emit()

func _on_day_changed(current_day: int) -> void:
	for job_id in Game.state.active_jobs.keys():
		var deadline: int = Game.state.active_jobs[job_id]
		if deadline != RESERVED and current_day > deadline:
			_expire_job(job_id)

## Se pierde el trabajo sin pagar nada. Lo que el jugador ya haya gastado
## (plata, piezas, cuando exista inventario) no se devuelve — es su costo
## por no haber entregado a tiempo.
func _expire_job(job_id: String) -> void:
	var job := JobsRepository.get_job(job_id)
	Game.state.active_jobs.erase(job_id)
	Game.state.wanderer_progress.erase(job_id)
	Game.state.wanderer_updated_at.erase(job_id)
	Game.state.npc_busy_in_garage.erase(job_id)
	job_expired.emit(job_id)

	if job:
		MessagesCenter.send(
			"Cliente molesto",
			"El cliente de \"%s\" se cansó de esperar y se llevó el auto a otro lado." % job.title
		)
