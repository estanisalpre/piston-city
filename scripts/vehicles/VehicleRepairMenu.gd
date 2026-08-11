extends Node2D

## Conecta la interacción con el auto (click derecho, ver
## VehicleInteraction — hoy reusa NpcInteraction.tscn, el detector de
## cercanía+click es genérico) al RadialMenu. Reusable: completá
## Categories (árbol de RadialMenuItem) e Interaction Path desde el
## Inspector — sumar una categoría/acción nueva no toca este script.

@export var categories: Array[RadialMenuItem] = []
@export var interaction_path: NodePath

## Secuencia de teclas para aflojar las tuercas (ver
## ButtonSequenceMinigame) — ajustable acá sin tocar código.
@export var loosen_bolts_sequence: Array[String] = ["B", "C", "B"]

## part_id que pasa a cargar el jugador (ver PlayerCarry) al terminar
## el minijuego, y el ícono que se le ve arriba de la cabeza mientras
## la lleva. Tiene que coincidir con el Part Id de la PartStorageZone
## correspondiente en el garage para poder depositarla ahí.
@export var removed_part_id: String = "neumatico"
@export var carried_part_icon: Texture2D

@onready var interaction: Area2D = get_node(interaction_path)

## El auto siempre instancia este script como hijo suyo directo (ver
## JobVehicle.gd) — de ahí sacamos el job_id para guardar el progreso
## en Game.state.job_repair_progress, y que sobreviva un guardado (no
## puede vivir solo en una variable de este nodo: el auto se recrea de
## cero al recargar la partida, ver JobEncounterSpawner).
@onready var vehicle: Node = get_parent()

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	var radial_menu := get_tree().get_first_node_in_group("radial_menu")
	radial_menu.open(categories)

	var action_id: String = await radial_menu.action_chosen
	_handle_action(action_id)

func _handle_action(action_id: String) -> void:
	match action_id:
		"quitar_rueda":
			_start_loosen_bolts()

func _start_loosen_bolts() -> void:
	if _repair_stage() != "":
		var lines: Array[String] = ["Ya le sacaste la rueda a este auto."]
		var dialogue := get_tree().get_first_node_in_group("dialogue_modal")
		dialogue.show_lines(lines)
		return

	if PlayerCarry.is_carrying():
		var lines: Array[String] = ["Ya tenés algo en las manos — dejalo en algún lado primero."]
		var dialogue := get_tree().get_first_node_in_group("dialogue_modal")
		dialogue.show_lines(lines)
		return

	var minigame := get_tree().get_first_node_in_group("button_sequence_minigame")
	minigame.start(loosen_bolts_sequence)

	var success: bool = await minigame.finished
	if success:
		PlayerCarry.carry(removed_part_id, carried_part_icon)
		Game.state.job_repair_progress[vehicle.job_id] = "wheel_removed"

func _repair_stage() -> String:
	return Game.state.job_repair_progress.get(vehicle.job_id, "")
