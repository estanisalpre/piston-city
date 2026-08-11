extends Node2D

## Mientras el jugador esté cargando una pieza (ver PlayerCarry),
## resalta en el piso, siguiendo el mouse, la celda de 32x32 donde
## caería si soltás ahí — verde si está libre, rojo si no se puede
## (fuera de rango, o algo bloqueando esa celda). PlayerCarry usa
## is_cell_free()/get_cell_center() antes de soltar en el piso, así
## nunca queda desincronizado con lo que ves en pantalla.
##
## Bloquea por dos capas de colisión a la vez: capa 1 (paredes/muebles
## reales, la misma que ya usan todos los tilesets — automático, no
## hace falta tocar nada) y capa 2 (zonas que vos marques a mano con un
## CollisionShape2D propio, para bloquear lugares que no
## necesariamente son sólidos para el jugador pero no querés que se
## pueda tirar algo ahí — ej. justo frente a una estantería).

const CELL_SIZE := 32.0
const MAX_DROP_DISTANCE := 64.0
const BLOCKED_MASK := 0b11  # capa 1 + capa 2

@onready var highlight: ColorRect = $Highlight

func _ready() -> void:
	add_to_group("floor_placement_cursor")
	visible = false
	highlight.size = Vector2(CELL_SIZE, CELL_SIZE)
	PlayerCarry.carry_changed.connect(_on_carry_changed)

func _on_carry_changed(part_id: String, _icon: Texture2D) -> void:
	visible = part_id != ""

func _process(_delta: float) -> void:
	if not visible:
		return

	var cell_center := get_cell_center()
	highlight.global_position = cell_center - Vector2(CELL_SIZE, CELL_SIZE) / 2.0
	highlight.color = Color(0, 1, 0, 0.35) if is_cell_free() else Color(1, 0, 0, 0.35)

func get_cell_center() -> Vector2:
	var mouse_pos := get_global_mouse_position()
	return (mouse_pos / CELL_SIZE).floor() * CELL_SIZE + Vector2(CELL_SIZE, CELL_SIZE) / 2.0

func is_cell_free() -> bool:
	return _is_within_range() and _is_cell_clear()

func _is_within_range() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return true
	return player.global_position.distance_to(get_cell_center()) <= MAX_DROP_DISTANCE

## Un rectángulo casi del tamaño de la celda, no un punto exacto en el
## centro — muchos tiles de pared solo tienen colisión en una tira
## angosta (no ocupan el tile completo), así que un punto puede caer
## justo afuera y dar "libre" por error. Revisa capas 1 y 2 (Area2D o
## StaticBody2D, cualquiera de las dos sirve) a la vez.
func _is_cell_clear() -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(CELL_SIZE, CELL_SIZE) * 0.9

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, get_cell_center())
	query.collision_mask = BLOCKED_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var space_state := get_world_2d().direct_space_state
	return space_state.intersect_shape(query, 1).is_empty()
