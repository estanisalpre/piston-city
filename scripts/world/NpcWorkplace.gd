extends Marker2D

## Negocio de un NPC "de historia" (ej. Pedro y la gomería) — a su
## wake_hour (ver NpcHome.gd) el NPC camina derecho hacia acá en vez de
## tomar una ruta random. De close_hour en más se comporta como
## cualquier NPC: toma una ruta random hasta que le toque volver a casa
## (NpcDirector.HEAD_HOME_HOUR).
##
## Para usarlo: agregá este script a un Marker2D bajo CityMap.tscn >
## Map > Workplaces (armá ese contenedor si no existe, hermano de
## Homes/WanderRoutes). Completá npc_id con el mismo id que usa
## NpcRoster.ALL (debe ser un id que también tenga su NpcHome — sin
## casa, este NPC no entra al ciclo de día/noche en absoluto).
##
## Interior opcional (ej. mostrador de la gomería): si completás
## Interior Scene Path, NpcDirector simula también la caminata de
## "entrar al local y pararse en el mostrador" (mismo mecanismo que
## entering_garage/waiting_at_door para los encargos) — buscando, en esa
## escena, un nodo con el nombre de Interior Entrance Marker Name (por
## donde entra caminando) y otro con Counter Marker Name (donde se
## para). Sin esto configurado, el NPC sigue yendo directo a "trabajar"
## (invisible) al llegar a la puerta, como hasta ahora.

@export var npc_id: String = ""
@export_range(0.0, 23.75, 0.25) var open_hour: float = 8.0
@export_range(0.0, 23.75, 0.25) var close_hour: float = 17.0

@export_file("*.tscn") var interior_scene_path: String = ""
@export var interior_entrance_marker_name: String = "ShopEntrance"
@export var counter_marker_name: String = "Counter"
