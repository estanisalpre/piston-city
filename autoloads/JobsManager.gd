extends Node

## Dueño del ciclo de vida completo de un encargo (ver
## docs/habilidades-y-escuela.md sección 8):
##
## aceptar -> el NPC de ese encargo (NpcRoster/NpcDirector) corta lo que
## esté haciendo y camina al taller, tarde lo que tarde -> se trabaja
## -> "Avisar al vendedor" -> el mismo NPC vuelve (respetando el
## horario del taller para el encuentro) -> retiro y pago. Al pagar,
## ese NPC se toma el día (NpcDirector.go_off_duty) y quedan dos
## enfriamientos en Game.state: el NPC no trae trabajos nuevos por
## NPC_JOB_COOLDOWN_DAYS, y ESE encargo puntual no se repite hasta
## JOB_REPEAT_COOLDOWN_DAYS (ver JobsRepository.is_job_available).
##
## La app "Trabajos" del celular y JobEncounterSpawner (el mundo) solo
## llaman a estas funciones, nunca tocan Game.state.active_jobs /
## pending_pickups directamente. El movimiento del NPC lo maneja
## siempre NpcDirector, nunca este autoload.

const DEADLINE_DAYS := 7
const RESERVED := -1

## Al completar un retiro, ese NPC no ofrece trabajos nuevos por esta
## cantidad de días (sigue viviendo su vida en el mundo, solo no trae
## un encargo nuevo enseguida).
const NPC_JOB_COOLDOWN_DAYS := 7

## Al completar un retiro, ESE encargo puntual (ej. "Cambio de
## neumáticos") no vuelve a aparecer hasta pasado esto — 28 días x 4
## estaciones (ver TimeManager) = 1 año de juego.
const JOB_REPEAT_COOLDOWN_DAYS := 112

## Horario fijo del taller — solo importa para el encuentro de retiro
## (el NPC puede caminar de vuelta a cualquier hora, pero no toca la
## puerta hasta que el taller abre).
const SHOP_OPEN_MINUTE := 480.0   # 08:00
const SHOP_CLOSE_MINUTE := 1200.0 # 20:00

signal job_completed(job_id: String)
signal job_expired(job_id: String)
signal jobs_cleared

func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)

func accept_job(job_id: String) -> void:
	var job := JobsRepository.get_job(job_id)
	if not job:
		return

	Game.state.active_jobs[job_id] = RESERVED
	NpcDirector.summon_to_workshop(job.npc_id, job_id)

## Lo llama el mundo (JobEncounterSpawner) cuando el NPC de bienvenida
## terminó su visita y se fue — recién ahí arranca el plazo de 7 días.
func start_job_clock(job_id: String) -> void:
	if Game.state.active_jobs.get(job_id) == RESERVED:
		Game.state.active_jobs[job_id] = Game.state.day + DEADLINE_DAYS

## Lo llama Jobs.gd al tocar "Avisar al vendedor". Todavía no paga —
## el NPC arranca a caminar de vuelta ya mismo (JobEncounterSpawner
## espera a que abra el taller para recién ahí correr el diálogo).
func request_pickup(job_id: String) -> void:
	var job := JobsRepository.get_job(job_id)
	if not job:
		return

	Game.state.active_jobs.erase(job_id)
	Game.state.pending_pickups[job_id] = TimeManager.get_total_minutes()
	NpcDirector.summon_to_workshop(job.npc_id, job_id)

func is_shop_open_now() -> bool:
	var time_of_day := fmod(TimeManager.get_total_minutes(), TimeManager.MINUTES_PER_DAY)
	return time_of_day >= SHOP_OPEN_MINUTE and time_of_day < SHOP_CLOSE_MINUTE

## Recién acá se paga de verdad — lo llama JobEncounterSpawner cuando
## el NPC del retiro llega, el taller está abierto, y termina el
## diálogo de agradecimiento.
func finish_pickup(job_id: String) -> void:
	var job := JobsRepository.get_job(job_id)
	Game.state.pending_pickups.erase(job_id)
	Game.state.job_repair_progress.erase(job_id)

	if job:
		Game.state.money += job.reward_money
		SkillProgression.add_exp(job.required_skill, job.reward_exp)
		Game.state.npc_cooldowns[job.npc_id] = Game.state.day + NPC_JOB_COOLDOWN_DAYS
		Game.state.job_cooldowns[job_id] = Game.state.day + JOB_REPEAT_COOLDOWN_DAYS

	job_completed.emit(job_id)

## Debug: borra todos los encargos (reservados, en curso o esperando
## retiro), sin pagar ni penalizar. Es solo para dejar el estado
## limpio al probar.
func clear_all_jobs() -> void:
	Game.state.active_jobs.clear()
	Game.state.pending_pickups.clear()
	Game.state.job_repair_progress.clear()
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
	Game.state.job_repair_progress.erase(job_id)
	job_expired.emit(job_id)

	if job:
		MessagesCenter.send(
			"Cliente molesto",
			"El cliente de \"%s\" se cansó de esperar y se llevó el auto a otro lado." % job.title
		)
