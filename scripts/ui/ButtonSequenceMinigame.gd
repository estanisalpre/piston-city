extends CanvasLayer

## Minijuego genérico de secuencia de botones — abrí con
## start(sequence, background) y esperá finished(success). Cada
## elemento de "sequence" es el nombre de una tecla tal cual se
## muestra en pantalla (ej. "B", "C"); hay que tocarlas en ese orden.
## Equivocarse reinicia la secuencia desde el principio, sin ninguna
## otra penalidad. Reusable — no sabe nada de tuercas ni de autos, eso
## vive en quien lo abra (ver VehicleRepairMenu).

signal finished(success: bool)

@onready var background_rect: TextureRect = $Background
@onready var prompts_container: HBoxContainer = $Prompts

var _sequence: Array[String] = []
var _index := 0

func _ready() -> void:
	add_to_group("button_sequence_minigame")
	hide()
	set_process_unhandled_key_input(false)

func start(sequence: Array[String], background: Texture2D = null) -> void:
	_sequence = sequence
	_index = 0
	background_rect.texture = background
	_render_prompts()
	show()
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var pressed_key := OS.get_keycode_string(event.keycode).to_upper()

	if pressed_key == _sequence[_index]:
		_index += 1
		if _index >= _sequence.size():
			_finish(true)
		else:
			_render_prompts()
	else:
		_index = 0
		_render_prompts()

func _finish(success: bool) -> void:
	set_process_unhandled_key_input(false)
	hide()
	finished.emit(success)

func _render_prompts() -> void:
	for child in prompts_container.get_children():
		child.queue_free()

	for i in _sequence.size():
		var label := Label.new()
		label.text = _sequence[i]
		label.modulate = Color.GREEN if i < _index else Color.WHITE
		prompts_container.add_child(label)
