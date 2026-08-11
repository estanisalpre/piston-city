extends Area2D

## Detecta cuándo el jugador está cerca de un NPC fijo (ej. el de un
## mostrador) y avisa con una señal al hacer click derecho — no decide
## qué pasa después, eso lo maneja quien escuche la señal. Mismo patrón
## de cercanía que DoorTrigger, pero sin viajar a ningún lado. Reusable
## — instanciar como hijo/hermano del NPC y ajustar el CollisionShape2D
## para que cubra el radio de interacción.

signal interacted

var _player_in_range := false

func _ready() -> void:
	input_pickable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _player_in_range:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Sin esto, el mismo click también le llegaría a _unhandled_input
		# — ej. PlayerCarry lo interpretaría como "soltar la pieza que
		# cargo" al mismo tiempo que se abre este menú.
		get_viewport().set_input_as_handled()
		interacted.emit()
