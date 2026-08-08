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
