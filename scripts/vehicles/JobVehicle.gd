extends Node2D

## Representación del auto de un encargo mientras está en el garage
## (ver docs/habilidades-y-escuela.md sección 8, y sistema-vehiculos.md
## para el sistema de piezas modulares). El cuerpo y cada pieza
## desmontable (ver VehiclePartInteraction) son capas separadas — el
## fade de aparecer/irse afecta a todas por igual, sin importar cuántas
## tenga este auto en particular.

## Pasos de opacidad del "aparecer"/"irse" — a propósito discretos (no
## un lerp continuo), para que se vea entrecortado en vez de un fundido liso.
const FADE_STEPS := [0.0, 0.4, 0.15, 0.75, 0.35, 1.0]
const FADE_STEP_SECONDS := 0.07

@export var job_id: String = ""

func _ready() -> void:
	_set_alpha(0.0)

## Al restaurar una partida guardada, el auto ya estaba ahí — se
## muestra directo, sin animación de aparición.
func show_parked() -> void:
	_set_alpha(1.0)

func play_arrival_fade() -> void:
	for step_alpha in FADE_STEPS:
		_set_alpha(step_alpha)
		await get_tree().create_timer(FADE_STEP_SECONDS).timeout

## Cuando se completan todas las piezas requeridas de la tanda actual
## (ver JobData.required_slots) y todavía quedan tandas por hacer (ver
## JobData.repair_rounds) — lo llama VehiclePartInteraction al instalar
## la última pieza que faltaba.
func has_more_rounds(job: JobData) -> bool:
	return _current_round(job.id) < job.repair_rounds - 1

## Gira el auto (mismo parpadeo entrecortado que aparecer/irse, ver
## FADE_STEPS) para mostrar el otro lado, y resetea el progreso de
## required_slots para que haya que volver a cambiarlas ahí — sin arte
## nuevo: al espejar el auto entero, el cuerpo y las piezas hijas
## (posición y sprite) quedan del otro lado solos.
func advance_round(job: JobData) -> void:
	for i in FADE_STEPS.size():
		_set_alpha(FADE_STEPS[i])
		if i == 0:
			scale.x *= -1
		await get_tree().create_timer(FADE_STEP_SECONDS).timeout

	Game.state.job_repair_progress[_round_key(job.id)] = str(_current_round(job.id) + 1)
	for slot_id in job.required_slots:
		Game.state.job_repair_progress.erase("%s:%s" % [job.id, slot_id])

	for child in get_children():
		if child.has_method("refresh_visual"):
			child.refresh_visual()

func _current_round(for_job_id: String) -> int:
	return int(Game.state.job_repair_progress.get(_round_key(for_job_id), "0"))

func _round_key(for_job_id: String) -> String:
	return "%s:round" % for_job_id

## El cliente se lo lleva — mismo efecto entrecortado pero al revés,
## y se autodestruye al terminar.
func play_departure_fade() -> void:
	var steps := FADE_STEPS.duplicate()
	steps.reverse()

	for step_alpha in steps:
		_set_alpha(step_alpha)
		await get_tree().create_timer(FADE_STEP_SECONDS).timeout

	queue_free()

func _set_alpha(alpha: float) -> void:
	for sprite in _get_sprites(self):
		sprite.modulate.a = alpha

func _get_sprites(node: Node) -> Array:
	var sprites: Array = []
	for child in node.get_children():
		if child is Sprite2D:
			sprites.append(child)
		sprites.append_array(_get_sprites(child))
	return sprites
