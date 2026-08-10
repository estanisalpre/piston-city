extends Marker2D

## Casa de un NPC (ver NpcRoster) — a las 20:00 (hora fija, ver
## NpcDirector.HEAD_HOME_HOUR) el NPC corta la patrulla y camina hasta
## acá con pathfinding real; al llegar se lo deja de mostrar (modo
## "at_home") hasta wake_hour, que sí es por NPC — para que no salgan
## todos a la misma hora.
##
## Para usarlo: agregá este script a un Marker2D bajo CityMap.tscn >
## Map > Homes (armá ese contenedor si no existe todavía, un Node2D
## simple, hermano de WanderRoutes). Completá npc_id con el mismo id
## que usa NpcRoster.ALL, y wake_hour con la hora en la que se despierta
## este NPC en particular.

@export var npc_id: String = ""
@export_range(0.0, 23.75, 0.25) var wake_hour: float = 6.5
