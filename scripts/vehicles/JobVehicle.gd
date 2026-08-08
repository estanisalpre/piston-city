extends Node2D

## Representación mínima del auto de un encargo mientras está en el
## garage (ver docs/habilidades-y-escuela.md sección 8). Por ahora es
## solo un sprite estático posicionado en un lugar de estacionamiento —
## el sistema de piezas/compartimentos se suma en un paso aparte.

## Pasos de opacidad del "aparecer"/"irse" — a propósito discretos (no
## un lerp continuo), para que se vea entrecortado en vez de un fundido liso.
const FADE_STEPS := [0.0, 0.4, 0.15, 0.75, 0.35, 1.0]
const FADE_STEP_SECONDS := 0.07

@export var job_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.modulate.a = 0.0

## Al restaurar una partida guardada, el auto ya estaba ahí — se
## muestra directo, sin animación de aparición.
func show_parked() -> void:
	sprite.modulate.a = 1.0

func play_arrival_fade() -> void:
	for step_alpha in FADE_STEPS:
		sprite.modulate.a = step_alpha
		await get_tree().create_timer(FADE_STEP_SECONDS).timeout

## El cliente se lo lleva — mismo efecto entrecortado pero al revés,
## y se autodestruye al terminar.
func play_departure_fade() -> void:
	var steps := FADE_STEPS.duplicate()
	steps.reverse()

	for step_alpha in steps:
		sprite.modulate.a = step_alpha
		await get_tree().create_timer(FADE_STEP_SECONDS).timeout

	queue_free()
