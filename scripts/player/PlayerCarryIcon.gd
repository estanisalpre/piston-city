extends Sprite2D

## Ícono flotante arriba de la cabeza del jugador mientras carga una
## pieza (ver PlayerCarry) — puramente visual, no decide nada, solo
## refleja lo que diga el autoload.

func _ready() -> void:
	visible = false
	PlayerCarry.carry_changed.connect(_on_carry_changed)

func _on_carry_changed(_part_id: String, icon: Texture2D) -> void:
	texture = icon
	visible = icon != null
