extends Resource
class_name RadialMenuItem

## Un ítem del RadialMenu — Resource plano, sin lógica de Godot (mismo
## espíritu que ShopItem). Si "children" tiene elementos, elegirlo abre
## un nuevo nivel del radial con esos hijos (ej. "Neumáticos" ->
## "Quitar rueda"/"Poner rueda"); si está vacío, es una acción final y
## el radial emite su "id" y se cierra.

@export var id: String = ""
@export var label: String = ""
@export var icon: Texture2D
@export var children: Array[RadialMenuItem] = []
