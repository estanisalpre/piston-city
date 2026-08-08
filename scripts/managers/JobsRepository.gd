extends RefCounted
class_name JobsRepository

## Única puerta de entrada a la lista de encargos. La app de Trabajos
## (celular) nunca debe leer una lista hardcodeada propia: siempre pasa
## por acá. El día que los encargos vengan de otro lado (generados,
## servidor, etc.) solo se cambia esta clase.

static func get_all_jobs() -> Array[JobData]:
	var jobs: Array[JobData] = []

	var oil_check := JobData.new()
	oil_check.id = "mecanica_revision_basica"
	oil_check.title = "Revisión básica de aceite"
	oil_check.description = "Medir el nivel de aceite del motor y rellenar si es necesario."
	oil_check.required_skill = SkillIds.MECANICA_GENERAL
	oil_check.required_level = 1
	oil_check.reward_money = 150
	oil_check.reward_exp = 20
	jobs.append(oil_check)

	var full_paint := JobData.new()
	full_paint.id = "pintura_completa_carroceria"
	full_paint.title = "Pintura completa de carrocería"
	full_paint.description = "Pintar el vehículo completo con acabado profesional uniforme."
	full_paint.required_skill = SkillIds.PINTURA
	full_paint.required_level = 4
	full_paint.reward_money = 2000
	full_paint.reward_exp = 150
	jobs.append(full_paint)

	return jobs

static func is_job_available(job: JobData) -> bool:
	var player_level: int = Game.state.skill_levels.get(job.required_skill, 1)
	return player_level >= job.required_level
