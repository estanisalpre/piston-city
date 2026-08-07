extends ColorRect

const MAX_DISTORTION := 0.05

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# TEMPORAL: desconectado para probar si el shader distorsiona algo, sin que
	# TimeManager pise el valor de prueba puesto en el .tscn.
	# TimeManager.heat_strength_changed.connect(_on_heat_strength_changed)

func _on_heat_strength_changed(strength: float) -> void:
	material.set_shader_parameter("strength", strength * MAX_DISTORTION)
