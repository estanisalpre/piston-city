extends Marker2D

## Negocio de un NPC "de historia" (ej. Pedro y la gomería) — a su
## wake_hour (ver NpcHome.gd) el NPC camina derecho hacia acá en vez de
## tomar una ruta random, y queda invisible ("at_work") hasta
## close_hour. De ahí en más se comporta como cualquier NPC: toma una
## ruta random hasta que le toque volver a casa (NpcDirector.HEAD_HOME_HOUR).
##
## Para usarlo: agregá este script a un Marker2D bajo CityMap.tscn >
## Map > Workplaces (armá ese contenedor si no existe, hermano de
## Homes/WanderRoutes). Completá npc_id con el mismo id que usa
## NpcRoster.ALL (debe ser un id que también tenga su NpcHome — sin
## casa, este NPC no entra al ciclo de día/noche en absoluto).

@export var npc_id: String = ""
@export_range(0.0, 23.75, 0.25) var open_hour: float = 8.0
@export_range(0.0, 23.75, 0.25) var close_hour: float = 17.0
