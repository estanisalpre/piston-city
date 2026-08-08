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

## Suma EXP a una habilidad, sin pasarse del tope del nivel siguiente
## (la EXP sobrante se pierde hasta que el jugador compre el nivel en la Escuela).
static func add_exp(skill_id: String, amount: int) -> void:
	var current_level: int = Game.state.skill_levels.get(skill_id, 1)
	var cap := exp_to_next_level(current_level)
	if cap == 0:
		return

	var current_exp: int = Game.state.skill_exp.get(skill_id, 0)
	Game.state.skill_exp[skill_id] = min(current_exp + amount, cap)
