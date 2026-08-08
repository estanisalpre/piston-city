extends Resource
class_name GameState

signal money_changed(amount: int)

@export var money := 50000:
	set(value):
		money = value
		money_changed.emit(money)

@export var owned_vehicles : Array[String] = []

@export var selected_vehicle := ""

@export var day := 1

@export var time_of_day := 480.0

## "" significa "partida nueva" — Main.gd usa esto para saber si tiene que
## restaurar la última ubicación o dejar el spawn por defecto (la cama).
@export var current_map_path := ""

@export var player_position := Vector2.ZERO

## Nivel actual de cada habilidad (1 a 5). Todas empiezan en 1 —
## ver docs/habilidades-y-escuela.md para qué desbloquea cada nivel.
@export var skill_levels: Dictionary[String, int] = {
	SkillIds.LAVADO: 1,
	SkillIds.MECANICA_GENERAL: 1,
	SkillIds.DESMANTELADOR: 1,
	SkillIds.TORQUE_HP: 1,
	SkillIds.PINTURA: 1,
	SkillIds.NEUMATICOS: 1,
	SkillIds.ELECTRICIDAD: 1,
	SkillIds.MOTOR: 1,
	SkillIds.TRANSMISION_CHASIS: 1,
	SkillIds.TASACION: 1,
}

## EXP acumulada de cada habilidad hacia su próximo nivel. Se resetea a 0
## cuando el nivel se compra en la Escuela. Ver SkillProgression.gd.
@export var skill_exp: Dictionary[String, int] = {
	SkillIds.LAVADO: 0,
	SkillIds.MECANICA_GENERAL: 0,
	SkillIds.DESMANTELADOR: 0,
	SkillIds.TORQUE_HP: 0,
	SkillIds.PINTURA: 0,
	SkillIds.NEUMATICOS: 0,
	SkillIds.ELECTRICIDAD: 0,
	SkillIds.MOTOR: 0,
	SkillIds.TRANSMISION_CHASIS: 0,
	SkillIds.TASACION: 0,
}

## Trabajos aceptados y todavía no entregados: job_id -> día límite
## (Game.state.day en el que vencen). Si un job_id no está acá, está
## disponible para aceptar. Ver JobsManager.
@export var active_jobs: Dictionary[String, int] = {}

## job_id -> minuto absoluto de juego (día*1440 + time_of_day) en el
## que el NPC/auto de la entrega van a aparecer en el garage. Se borra
## apenas se dispara ese encuentro. Ver JobsManager/JobEncounterSpawner.
@export var scheduled_deliveries: Dictionary[String, float] = {}

## job_id -> minuto absoluto de juego en el que el cliente viene a
## retirar el auto ya terminado (respeta el horario del taller, ver
## JobsManager._compute_pickup_arrival). Un job_id presente acá ya no
## está en active_jobs — el pago recién ocurre cuando el NPC llega.
@export var pending_pickups: Dictionary[String, float] = {}

## job_id -> {"route": String, "index": int, "dir": int} — en qué
## recorrido de patrulla (ver CityWandererSpawner) está el cliente de
## ese encargo, en qué punto del recorrido, y para qué lado camina.
## Ver Client.gd.
@export var wanderer_progress: Dictionary[String, Dictionary] = {}

## job_id -> minuto absoluto de juego en el que wanderer_progress[job_id]
## fue verdad por última vez. Al volver a entrar al CityMap, se usa
## para "adelantar" la caminata simulada el tiempo que pasó mientras no
## se veía — así se siente que deambuló solo, no que quedó pausado.
@export var wanderer_updated_at: Dictionary[String, float] = {}

## job_id -> true mientras el NPC de ese encargo está en medio de un
## encuentro real dentro del garage (entrega o retiro). Mientras esté
## acá, CityWandererSpawner no debe crear una copia deambulando en la
## ciudad — el NPC es uno solo. Ver JobEncounterSpawner.
@export var npc_busy_in_garage: Dictionary[String, bool] = {}

## Bandeja de mensajes (reclamos de clientes, etc). Cada entrada:
## {"title": String, "body": String, "day": int, "read": bool}.
## Ver MessagesCenter.
@export var messages: Array[Dictionary] = []
