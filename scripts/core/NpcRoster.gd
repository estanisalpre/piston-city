extends RefCounted
class_name NpcRoster

## Lista de los NPCs que existen en el mundo. Agregá un id acá por
## cada NPC nuevo que armes (con su ruta propia) — es lo único que
## hace falta tocar en código para sumar uno; el resto (ruta del día,
## encargos asignados) se resuelve solo. Ver NpcDirector.

const ALL := [
	"npc_01",
	"npc_02",
	"npc_03",
]

## Qué atlas de sprite usa cada NPC — mismo script (Client.gd) y misma
## grilla (96x192, 3x6, frames de 32x32) para todos, solo cambia el
## dibujo. Al sumar un NPC nuevo, agregalo acá con su propio atlas.
const TEXTURES := {
	"npc_01": "res://assets/sprites/npcs/mario/atlas_npc_mario.png",
	"npc_02": "res://assets/sprites/npcs/atlas_npc_v1.png",
	"npc_03": "res://assets/sprites/npcs/atlas_npc_v2.png",
}

## Nombre para mostrar (ej. en la app de Trabajos del celular). Al sumar
## un NPC nuevo, agregalo acá también.
const NAMES := {
	"npc_01": "Mario",
	"npc_02": "Rocío",
	"npc_03": "Jhon",
}

static func get_texture(npc_id: String) -> Texture2D:
	var path: String = TEXTURES.get(npc_id, TEXTURES.values()[0])
	return load(path)

static func get_display_name(npc_id: String) -> String:
	return NAMES.get(npc_id, npc_id)
