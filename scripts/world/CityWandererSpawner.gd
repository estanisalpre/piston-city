extends Node2D

## Si hay algún encargo en curso o esperando retiro, hace aparecer a un
## cliente patrullando entre los puntos de un recorrido (ver
## "routes_path": un contenedor con un Node2D hijo por cada recorrido
## posible, cada uno con sus propios Marker2D hijos en el orden en que
## se camina — el punto 0 siempre es "anchor_point_path", la puerta del
## taller). Mientras el jugador anda por la ciudad, el cliente va y
## vuelve por ese recorrido sin parar.
##
## No es el mismo Node que el cliente del garage (ver JobEncounterSpawner):
## acá se recrea cada vez que se entra al mapa. Para que se sienta como
## que "siguió su vida" mientras no lo veías, no lo devuelve al mismo
## punto exacto — calcula (con fórmula cerrada, sin iterar paso a paso)
## dónde habría quedado el rebote ida-y-vuelta según el tiempo que pasó.
##
## Si el NPC de ese encargo está en medio de un encuentro real dentro
## del garage (Game.state.npc_busy_in_garage), no se crea una copia acá
## — el cliente es uno solo en todo el mapa.

## Velocidad de caminata — tiene que coincidir con WALK_SPEED de
## Client.gd, se usa solo para estimar el avance simulado.
const WALK_SPEED := 40.0

@export var routes_path: NodePath
@export var anchor_point_path: NodePath
@export var client_scene: PackedScene

func _ready() -> void:
	var anchor: Node2D = get_node(anchor_point_path)
	var routes := _collect_routes(anchor)

	if routes.is_empty():
		return

	for job_id in Game.state.active_jobs.keys():
		if Game.state.active_jobs[job_id] != JobsManager.RESERVED:
			_spawn_wanderer(job_id, routes)

	for job_id in Game.state.pending_pickups.keys():
		_spawn_wanderer(job_id, routes)

## routes: nombre del recorrido -> Array[Vector2] de puntos (el punto 0
## siempre es la puerta del taller).
func _collect_routes(anchor: Node2D) -> Dictionary:
	var routes := {}
	var container: Node = get_node(routes_path)

	for route_node in container.get_children():
		var points: Array[Vector2] = [anchor.global_position]
		for point_node in route_node.get_children():
			points.append(point_node.global_position)

		if points.size() >= 2:
			routes[route_node.name] = points

	return routes

func _spawn_wanderer(job_id: String, routes: Dictionary) -> void:
	if Game.state.npc_busy_in_garage.has(job_id):
		return  # ya está en un encuentro real dentro del garage — no duplicar

	var route_name := _resolve_route_name(job_id, routes)
	var points: Array[Vector2] = routes[route_name]

	var progress: Dictionary = Game.state.wanderer_progress.get(job_id, {})
	var start_index: int = progress.get("index", 0)
	var start_dir: int = progress.get("dir", 1)

	var last_update: float = Game.state.wanderer_updated_at.get(job_id, TimeManager.get_total_minutes())
	var elapsed_minutes := TimeManager.get_total_minutes() - last_update
	var elapsed_seconds := elapsed_minutes  # 1 minuto de juego == 1 segundo real en este proyecto

	var resolved := _advance_bounce(points, start_index, start_dir, elapsed_seconds)

	var client: CharacterBody2D = client_scene.instantiate()
	client.job_id = job_id
	add_child(client)
	client.global_position = points[resolved.index]

	Game.state.wanderer_progress[job_id] = {
		"route": route_name, "index": resolved.index, "dir": resolved.dir,
	}
	Game.state.wanderer_updated_at[job_id] = TimeManager.get_total_minutes()

	client.start_route_wandering(points, resolved.index, resolved.dir)

## Si ya lo habíamos visto en un recorrido válido, sigue en ese mismo.
## Si no (primera vez, o el recorrido ya no existe), elige uno al azar.
func _resolve_route_name(job_id: String, routes: Dictionary) -> String:
	var progress: Dictionary = Game.state.wanderer_progress.get(job_id, {})
	var remembered: String = progress.get("route", "")

	if routes.has(remembered):
		return remembered

	var names := routes.keys()
	return names[randi() % names.size()]

## Fórmula cerrada del rebote ida-y-vuelta entre los puntos del
## recorrido — evita iterar paso a paso (los puntos pueden estar a
## cualquier distancia, no son celdas de tamaño fijo).
func _advance_bounce(points: Array[Vector2], start_index: int, start_dir: int, elapsed_seconds: float) -> Dictionary:
	var point_count := points.size()
	if point_count < 2:
		return {"index": 0, "dir": 1}

	var period := 2 * (point_count - 1)
	var seconds_per_step := _average_step_seconds(points)
	var steps := int(elapsed_seconds / seconds_per_step)

	var virtual_pos := start_index if start_dir == 1 else (period - start_index)
	virtual_pos = ((virtual_pos + steps) % period + period) % period

	if virtual_pos < point_count:
		return {"index": virtual_pos, "dir": 1}

	return {"index": period - virtual_pos, "dir": -1}

func _average_step_seconds(points: Array[Vector2]) -> float:
	var total_distance := 0.0
	for i in points.size() - 1:
		total_distance += points[i].distance_to(points[i + 1])

	var average_distance := total_distance / (points.size() - 1)
	return max(average_distance / WALK_SPEED, 0.1)
