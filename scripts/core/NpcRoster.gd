extends RefCounted
class_name NpcRoster

## Lista de los NPCs que existen en el mundo. Agregá un id acá por
## cada NPC nuevo que armes (con su ruta propia) — es lo único que
## hace falta tocar en código para sumar uno; el resto (ruta del día,
## encargos asignados) se resuelve solo. Ver NpcDirector.

## 50 npc_ids reservados para poder ir armando rutas de a poco (ver
## NpcDirector._load_routes) — con menos rutas que NPCs, los que no
## entran en ninguna ruta libre simplemente no se muestran todavía
## (quedan sin inicializar), no rompen nada.
const ALL := [
	"npc_01", "npc_02", "npc_03", "npc_04", "npc_05",
	"npc_06", "npc_07", "npc_08", "npc_09", "npc_10",
	"npc_11", "npc_12", "npc_13", "npc_14", "npc_15",
	"npc_16", "npc_17", "npc_18", "npc_19", "npc_20",
	"npc_21", "npc_22", "npc_23", "npc_24", "npc_25",
	"npc_26", "npc_27", "npc_28", "npc_29", "npc_30",
	"npc_31", "npc_32", "npc_33", "npc_34", "npc_35",
	"npc_36", "npc_37", "npc_38", "npc_39", "npc_40",
	"npc_41", "npc_42", "npc_43", "npc_44", "npc_45",
	"npc_46", "npc_47", "npc_48", "npc_49", "npc_50",
]

## Qué atlas de sprite usa cada NPC — mismo script (Client.gd) y misma
## grilla (96x192, 3x6, frames de 32x32) para todos, solo cambia el
## dibujo. Al sumar un NPC nuevo, agregalo acá con su propio atlas.
const TEXTURES := {
	"npc_01": "res://assets/sprites/npcs/atlas_npc_v1.png",
	"npc_02": "res://assets/sprites/npcs/atlas_npc_v2.png",
}

## Nombre para mostrar (ej. en la app de Trabajos del celular). Al sumar
## un NPC nuevo, agregalo acá también.
const NAMES := {
	"npc_01": "Martín",
	"npc_02": "Rocío",
}

static func get_texture(npc_id: String) -> Texture2D:
	var path: String = TEXTURES.get(npc_id, TEXTURES.values()[0])
	return load(path)

static func get_display_name(npc_id: String) -> String:
	return NAMES.get(npc_id, npc_id)
