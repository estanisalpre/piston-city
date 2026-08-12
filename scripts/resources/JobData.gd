extends Resource
class_name JobData

## DTO plano de un encargo. Sin lógica de Godot: solo datos.
## El acceso siempre pasa por JobsRepository, nunca se instancia
## una lista de JobData suelta en otro lado.

@export var id: String
@export var title: String
@export var description: String
@export var required_skill: String
@export var required_level: int = 1
@export var reward_money: int
@export var reward_exp: int

## Qué NPC trae este encargo (y, a futuro, con qué vehículo propio) —
## ver NpcRoster/NpcDirector. Siempre el mismo NPC para el mismo id de
## encargo.
@export var npc_id: String = ""

## Slots de VehiclePartInteraction (ver JobVehicle.tscn) que hay que
## dejar en estado "installed" antes de poder pedir el retiro. Vacío
## (default) = job sin piezas físicas que cambiar, se comporta como
## siempre. Ver JobsRepository / Jobs.gd::_on_request_pickup_pressed.
##
## También es la lista de qué piezas se pueden sacar del auto — una
## pieza que no está acá no se puede tocar (ver
## VehiclePartInteraction._is_required), sin importar el job: si este
## trabajo no la pide, no hay motivo para desarmarla.
@export var required_slots: Array[String] = []

## Subconjunto de required_slots que además se ve "dañado" en vez de
## la textura sana de siempre, mientras no se haya cambiado (ver
## VehiclePartInteraction.damaged_texture). Ej. una rueda desinflada.
@export var damaged_slots: Array[String] = []

## Cuántas "tandas" hay que completar de required_slots antes de poder
## avisar al vendedor. 1 (default) = una sola vez, como cualquier job de
## hoy. >1 es para trabajos como "Cambio de neumáticos": se repiten los
## mismos required_slots una vez por tanda, con un giro del auto entre
## tandas para mostrar el otro lado (ver JobVehicle.advance_round).
@export var repair_rounds: int = 1
