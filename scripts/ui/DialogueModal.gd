extends CanvasLayer

## Diálogo de una sola vía: el jugador nunca responde, solo avanza las
## líneas del NPC tocando el cartel (no en cualquier lado de la
## pantalla, no con teclado) hasta que se acaban.
## Ver docs/habilidades-y-escuela.md sección 8.

signal finished

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/MarginContainer/Label

var _lines: Array[String] = []
var _index := 0

func _ready() -> void:
	add_to_group("dialogue_modal")
	hide()
	panel.gui_input.connect(_on_panel_gui_input)

func show_lines(lines: Array[String]) -> void:
	if lines.is_empty():
		finished.emit()
		return

	_lines = lines
	_index = 0
	show()
	_show_current_line()

func _show_current_line() -> void:
	label.text = _lines[_index]

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _advance() -> void:
	_index += 1

	if _index >= _lines.size():
		hide()
		finished.emit()
	else:
		_show_current_line()
