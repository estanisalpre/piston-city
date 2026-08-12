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

## job_id -> momento (minuto absoluto de juego) en el que se pidió el
## retiro ("Avisar al vendedor"). Un job_id presente acá ya no está en
## active_jobs — el pago recién ocurre cuando el NPC llega de verdad
## (ver JobsManager.finish_pickup). El NPC empieza a caminar de vuelta
## enseguida (ver NpcDirector) — este valor es solo informativo, ya no
## se usa para calcular cuándo llega.
@export var pending_pickups: Dictionary[String, float] = {}

## Bandeja de mensajes (reclamos de clientes, etc). Cada entrada:
## {"title": String, "body": String, "day": int, "read": bool}.
## Ver MessagesCenter.
@export var messages: Array[Dictionary] = []

## npc_id -> día (Game.state.day) a partir del cual ese NPC vuelve a
## ofrecer trabajos nuevos en el celular — se pone al completar un
## retiro (ver JobsManager.finish_pickup). No afecta ningún trabajo ya
## en curso, solo cuáles aparecen como "Disponibles".
@export var npc_cooldowns: Dictionary[String, int] = {}

## job_id -> día a partir del cual ESE encargo puntual vuelve a
## aparecer como disponible (para cualquier NPC) — se pone al completar
## un retiro. Mucho más largo que npc_cooldowns (~1 año de juego): no
## tiene sentido que el mismo cliente pida cambiar los mismos
## neumáticos cada semana.
@export var job_cooldowns: Dictionary[String, int] = {}

## Stock de piezas del taller: part_id (String libre, ej. "neumatico")
## -> cantidad total (sumando todos los lugares donde esté guardada).
## Nunca es mochila del jugador — todo lo comprado entra directo acá.
## Ver PartsInventory.
@export var parts: Dictionary[String, int] = {}

## zone_id (String libre, ej. "tire_shelf") -> array de lugares físicos
## de esa estantería, en orden — cada lugar guarda "" (vacío) o el
## part_id que tiene puesto. Un mismo mueble puede tener mezclados
## neumáticos nuevos y usados: el lugar que ocupó el primero no se
## pisa con el segundo, cada uno tiene su propio lugar hasta que se
## saca de ahí. Ver PartsInventory.deposit_in_zone/get_slots.
@export var storage_slots: Dictionary[String, Array] = {}

## Piezas tiradas en el piso de algún mapa (ver PlayerCarry) — para que
## sigan ahí después de guardar/cargar, en vez de desaparecer. Cada
## entrada: {"id": int, "map_path": String, "position": Vector2,
## "part_id": String, "icon": Texture2D}. "map_path" es el mapa donde
## se tiró (no aparece en otro mapa) y "id" es único, para poder
## sacarla de acá cuando el jugador la vuelve a levantar sin
## confundirla con otra igual tirada al lado.
@export var dropped_parts: Array[Dictionary] = []
@export var next_dropped_part_id: int = 0

## Ventas hechas desde la computadora del marketplace, todavía sin
## pagar — el pago nunca es instantáneo, se acredita al día siguiente
## a las 08:00 (ver MarketplaceManager). Cada entrada: {"amount": int,
## "pay_day": int} (Game.state.day en el que corresponde pagar).
@export var pending_sales: Array[Dictionary] = []

## job_id -> en qué paso de la reparación quedó ese encargo puntual
## (String libre, ej. "" = todavía no arrancó, "wheel_removed" = ya le
## sacó la rueda vieja). Vive en Game.state (no en el nodo del auto en
## la escena) justamente para que sobreviva un guardado/cargado — ver
## VehicleRepairMenu.
@export var job_repair_progress: Dictionary[String, String] = {}

## npc_id -> snapshot de NpcDirector en el momento de guardar
## ({route, index, dir, position, mode, job_id, wait_remaining}) — sin
## importar en qué modo estaba (patrullando, camino al taller, de
## franco, lo que sea), así el mundo sigue exactamente desde ahí al
## recargar en vez de resetear a todos a "patrol" desde cero. Untyped a
## propósito (los valores no son todos del mismo tipo) — ver
## NpcDirector.capture_snapshot() / _restore_or_init_npc().
@export var npc_snapshots: Dictionary = {}

## Lo llama SaveManager.debug_reset_everything() — vuelve cada campo a
## su valor de partida nueva, EN ESTE MISMO objeto (nunca reemplazando
## Game.state por uno nuevo): HUD y otros ya tienen conectadas señales
## como money_changed a esta instancia puntual — reemplazarla por un
## GameState.new() las deja escuchando a un objeto que ya nadie usa.
func reset() -> void:
	var fresh := GameState.new()

	money = fresh.money
	owned_vehicles = fresh.owned_vehicles
	selected_vehicle = fresh.selected_vehicle
	day = fresh.day
	time_of_day = fresh.time_of_day
	current_map_path = fresh.current_map_path
	player_position = fresh.player_position
	skill_levels = fresh.skill_levels
	skill_exp = fresh.skill_exp
	active_jobs = fresh.active_jobs
	pending_pickups = fresh.pending_pickups
	messages = fresh.messages
	npc_cooldowns = fresh.npc_cooldowns
	job_cooldowns = fresh.job_cooldowns
	parts = fresh.parts
	storage_slots = fresh.storage_slots
	dropped_parts = fresh.dropped_parts
	next_dropped_part_id = fresh.next_dropped_part_id
	pending_sales = fresh.pending_sales
	job_repair_progress = fresh.job_repair_progress
	npc_snapshots = fresh.npc_snapshots
