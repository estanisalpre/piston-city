extends Node2D

## La "computadora" del garage — click derecho (ver Interaction Path,
## reusa NpcInteraction.tscn) abre el modal del marketplace. No sabe
## nada de qué se puede vender ni de precios, eso vive en
## MarketplaceManager/SellCatalog.

@export var interaction_path: NodePath

@onready var interaction: Area2D = get_node(interaction_path)

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	var modal := get_tree().get_first_node_in_group("marketplace_modal")
	modal.open()
