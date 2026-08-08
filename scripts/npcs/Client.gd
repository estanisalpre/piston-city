extends CharacterBody2D

## NPC genérico de cliente (ver docs/habilidades-y-escuela.md sección 8).
## Sabe: caminar hacia un punto puntual (walk_to), patrullar sin parar
## entre los puntos de un recorrido (start_route_wandering), y esperar
## parado a que el jugador se acerque (wait_for_player) — el spawn, el
## diálogo y el resto del flujo del encargo se conectan desde afuera.

const WALK_SPEED := 40.0
const ARRIVAL_DISTANCE := 2.0
const PLAYER_APPROACH_DISTANCE := 32.0

## Cuánto antes de la hora de retiro corta la patrulla y vuelve al
## punto 0 del recorrido (la puerta del taller) — ver
## _should_return_to_workshop.
const APPROACH_WINDOW_MINUTES := 10.0

signal arrived
signal player_approached

## Con qué encargo se relaciona este cliente mientras patrulla — lo
## setea CityWandererSpawner. Sirve para guardar/recordar su progreso
## (Game.state.wanderer_progress) y para saber cuándo volver al taller.
@export var job_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _target_position := Vector2.ZERO
var _walking := false

var _route_points: Array[Vector2] = []
var _route_index := 0
var _route_direction := 1  # 1 = hacia el final del recorrido, -1 = hacia el punto 0 (la puerta)
var _route_returning := false
var _patrolling := false

var _waiting_for_player := false

func walk_to(point: Vector2) -> void:
	_target_position = point
	_walking = true

## Se queda parado hasta que el jugador entre en PLAYER_APPROACH_DISTANCE
## píxeles — recién ahí emite player_approached. Pensado para que el
## NPC del garage nunca dependa de que el jugador ya esté parado en un
## punto exacto: lo espera, sin importar cuándo aparezcas.
func wait_for_player() -> void:
	_walking = false
	_waiting_for_player = true
	_play_idle()

func _check_player_proximity() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return

	if global_position.distance_to(player.global_position) <= PLAYER_APPROACH_DISTANCE:
		_waiting_for_player = false
		player_approached.emit()

## Patrulla sin parar entre "points" (el punto 0 es siempre la puerta
## del taller): va del primero al último y vuelve, en bucle, para
## siempre — pensado para el cliente mientras su auto se está
## reparando (ver CityWandererSpawner). "start_index"/"start_direction"
## permiten retomar un recorrido ya empezado (al volver a entrar al
## CityMap). Nunca se mezcla con walk_to() suelto: un NPC o hace un
## encargo puntual, o patrulla, no las dos cosas.
func start_route_wandering(points: Array[Vector2], start_index: int, start_direction: int) -> void:
	if points.size() < 2:
		return

	_route_points = points
	_route_index = clampi(start_index, 0, points.size() - 1)
	_route_direction = start_direction
	_route_returning = false
	_patrolling = true

	arrived.connect(_on_route_arrived)
	walk_to(_route_points[_route_index])

func _on_route_arrived() -> void:
	if not _patrolling:
		return

	if _route_returning and _route_index == 0:
		queue_free()  # llegó a la puerta del taller, entra y desaparece
		return

	_report_progress()

	if not _route_returning and _should_return_to_workshop():
		_route_returning = true
		_route_direction = -1

	if _route_returning:
		if _route_index == 0:
			queue_free()
			return
		_walk_to_route_index(_route_index - 1)
		return

	var next_index := _route_index + _route_direction
	if next_index >= _route_points.size():
		_route_direction = -1
		next_index = _route_points.size() - 2
	elif next_index < 0:
		_route_direction = 1
		next_index = 1

	_walk_to_route_index(next_index)

func _walk_to_route_index(index: int) -> void:
	_route_index = index
	walk_to(_route_points[index])

func _report_progress() -> void:
	var progress: Dictionary = Game.state.wanderer_progress.get(job_id, {})
	progress["index"] = _route_index
	progress["dir"] = _route_direction
	Game.state.wanderer_progress[job_id] = progress
	Game.state.wanderer_updated_at[job_id] = TimeManager.get_total_minutes()

## Si falta poco (o ya pasó) para que lo estén esperando de vuelta en
## el taller, corta la patrulla y vuelve al punto 0.
func _should_return_to_workshop() -> bool:
	if not Game.state.pending_pickups.has(job_id):
		return false

	var arrival: float = Game.state.pending_pickups[job_id]
	return TimeManager.get_total_minutes() >= arrival - APPROACH_WINDOW_MINUTES

func _physics_process(_delta: float) -> void:
	if _waiting_for_player:
		_check_player_proximity()

	if not _walking:
		return

	var to_target := _target_position - global_position
	if to_target.length() <= ARRIVAL_DISTANCE:
		_walking = false
		velocity = Vector2.ZERO
		_play_idle()
		arrived.emit()
		return

	velocity = to_target.normalized() * WALK_SPEED
	move_and_slide()
	_play_walk(velocity)

func _play_walk(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animation_player.play("walk_right" if direction.x > 0 else "walk_left")
	else:
		animation_player.play("walk_down" if direction.y > 0 else "walk_up")

func _play_idle() -> void:
	var current := animation_player.current_animation
	if current.is_empty():
		return

	var idle_anim: String = current.replace("walk_", "idle_")
	if animation_player.has_animation(idle_anim):
		animation_player.play(idle_anim)
