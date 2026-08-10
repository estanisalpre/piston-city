extends Node2D

## Mostrador de cualquier local (gomería, y a futuro los que sean) —
## conecta la interacción con el NPC (ver NpcInteraction) al menú de
## opciones y de ahí al PurchaseModal genérico. Reusable: completá
## Shop Title, Buy Option Label, Items (un ShopItem por producto) y Npc
## Interaction Path desde el Inspector — no hace falta tocar código
## para un local nuevo.

@export var shop_title: String = "Comprar"
@export var buy_option_label: String = "Comprar"
@export var items: Array[ShopItem] = []
@export var npc_interaction_path: NodePath

@onready var npc_interaction: Area2D = get_node(npc_interaction_path)

func _ready() -> void:
	npc_interaction.interacted.connect(_on_npc_interacted)

func _on_npc_interacted() -> void:
	var options_modal := get_tree().get_first_node_in_group("options_modal")
	var options: Array[String] = [buy_option_label]
	options_modal.show_options(options)

	var choice: String = await options_modal.option_chosen

	if choice == buy_option_label:
		var purchase_modal := get_tree().get_first_node_in_group("purchase_modal")
		purchase_modal.open(shop_title, items)
