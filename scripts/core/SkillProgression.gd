extends RefCounted
class_name SkillProgression

## Tabla única de progresión de habilidades. Ver docs/habilidades-y-escuela.md
## sección 2 — valores provisorios, se rebalancean con la economía real.
## Índice 0 = umbral para pasar de nivel 1 a 2, índice 1 = nivel 2 a 3, etc.
const EXP_THRESHOLDS := [100, 300, 700, 1500]
const LEVEL_UP_COST := [1500, 4000, 9000, 18000]

const MAX_LEVEL := 5

static func exp_to_next_level(current_level: int) -> int:
	if current_level >= MAX_LEVEL:
		return 0
	return EXP_THRESHOLDS[current_level - 1]

## Suma (o resta, con amount negativo) EXP a una habilidad, sin pasarse del
## tope del nivel siguiente ni bajar de 0
## (la EXP sobrante se pierde hasta que el jugador compre el nivel en la Escuela).
static func add_exp(skill_id: String, amount: int) -> void:
	var current_level: int = Game.state.skill_levels.get(skill_id, 1)
	var cap := exp_to_next_level(current_level)
	if cap == 0:
		return

	var current_exp: int = Game.state.skill_exp.get(skill_id, 0)
	Game.state.skill_exp[skill_id] = clampi(current_exp + amount, 0, cap)

## Fuerza el nivel de una habilidad sin pasar por el costo en dinero de la
## Escuela — pensado solo para la barra de debug.
static func debug_set_level(skill_id: String, level: int) -> void:
	Game.state.skill_levels[skill_id] = clampi(level, 1, MAX_LEVEL)
	Game.state.skill_exp[skill_id] = 0
