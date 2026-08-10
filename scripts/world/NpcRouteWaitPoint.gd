extends Marker2D

## Punto de ruta donde el NPC se queda parado un rato antes de seguir
## camino (ej. un café) — solo aplica durante la rutina normal; si lo
## llaman por un encargo, lo ignora y va derecho al taller.
##
## Para usarlo: agregá este script a cualquier Marker2D hijo de una
## ruta (en CityMap.tscn > WanderRoutes > RouteX) y poné cuántos
## minutos de juego querés que se quede. Un punto sin este script
## vale 0 (no espera).

@export var wait_minutes: float = 0.0
