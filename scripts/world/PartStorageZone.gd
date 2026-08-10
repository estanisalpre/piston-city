extends Area2D

## Zona de almacenamiento de un tipo de pieza en el taller — marca dónde
## "vive" cada part_id (ver PartsInventory) para que el jugador la
## busque ahí cuando la necesite. Reusable: instanciar
## PartStorageZone.tscn en cualquier lugar del taller y completar Part
## Id desde el Inspector.
##
## Todavía no hace nada más por sí sola — agarrar la pieza y llevarla
## al auto es el próximo paso, que va a leer player_in_range/part_id
## desde acá. Mismo patrón que DoorTrigger/BedTrigger.

@export var part_id: String = ""

var player_in_range := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
