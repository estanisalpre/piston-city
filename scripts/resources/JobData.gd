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
