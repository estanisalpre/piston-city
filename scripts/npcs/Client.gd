extends CharacterBody2D

## NPC genérico de cliente (ver docs/habilidades-y-escuela.md sección 8).
## Tiene dos formas de moverse, que nunca se mezclan:
##
## - "Local": walk_to()/wait_for_player(), para las coreografías
##   puntuales dentro del garage (caminar hasta el auto, esperar al
##   jugador). El propio Client calcula el movimiento cuadro a cuadro.
## - "Espejo": mirror_npc(), para cuando lo estás viendo caminar por la
##   ciudad. El movimiento real lo calcula NpcDirector todo el tiempo
##   (exista o no este Node) — acá solo se copia su posición y se
##   elige la animación según hacia dónde se mueve.

const WALK_SPEED := 40.0
const ARRIVAL_DISTANCE := 2.0
const PLAYER_APPROACH_DISTANCE := 32.0

signal arrived
signal player_approached

## Con qué encargo se relaciona este cliente ahora mismo (si tiene) —
## lo setea quien lo instancia. Solo informativo/lectura para quien lo
## necesite mostrar.
@export var job_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _target_position := Vector2.ZERO
var _walking := false
var _waiting_for_player := false

var _mirroring_npc_id := ""
var _mirror_last_position := Vector2.ZERO

## Cambia el dibujo sin tocar nada de la animación — todos los atlas de
## NpcRoster comparten la misma grilla (3x6, frames de 32x32).
func set_appearance(texture: Texture2D) -> void:
	sprite.texture = texture

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

## Este Node se limita a mostrar dónde dice NpcDirector que está
## npc_id — nunca decide el movimiento por su cuenta. Ver
## CityWandererSpawner.
func mirror_npc(npc_id: String) -> void:
	_mirroring_npc_id = npc_id
	_mirror_last_position = NpcDirector.get_position(npc_id)
	global_position = _mirror_last_position

## Corta el modo espejo para pasar a control local (walk_to/wait_for_player)
## — se usa cuando NpcDirector dice que el NPC ya llegó y se quedó
## quieto, así de acá en más lo maneja este Node (por ejemplo para
## esperar al jugador, que el modo espejo no chequea).
func stop_mirroring() -> void:
	_mirroring_npc_id = ""

func _sync_mirrored_position() -> void:
	var new_position: Vector2 = NpcDirector.get_position(_mirroring_npc_id)
	var movement: Vector2 = new_position - _mirror_last_position

	global_position = new_position
	_mirror_last_position = new_position

	if movement.length() > 0.01:
		_play_walk(movement)
	else:
		_play_idle()

func _physics_process(_delta: float) -> void:
	if _mirroring_npc_id != "":
		_sync_mirrored_position()
		return

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
