extends Node2D

## Muestra en el CityMap a cualquier NPC (ver NpcRoster) cuyo estado en
## NpcDirector diga que está caminando por la ciudad (patrullando, yendo
## al taller, yendo a o volviendo de su casa) — nunca decide el
## movimiento por su cuenta, solo instancia un Client por cada uno y lo
## deja en modo "espejo" (ver Client.mirror_npc).
##
## Si un NPC ya entró al garage (modos "entering_garage" o
## "waiting_at_door"), no se muestra acá — eso lo maneja
## JobEncounterSpawner. Tampoco si está "at_home" o "off_duty" — esos
## dos son a propósito invisibles en cualquier mapa. Así nunca hay dos
## copias del mismo NPC en el mapa a la vez.

const VISIBLE_MODES := ["patrol", "to_workshop", "to_home", "to_route", "to_work"]

@export var client_scene: PackedScene

var _instances: Dictionary = {}  # npc_id (String) -> Client instance

func _process(_delta: float) -> void:
	_sync_instances()

func _sync_instances() -> void:
	for npc_id in NpcRoster.ALL:
		var should_show: bool = VISIBLE_MODES.has(NpcDirector.get_mode(npc_id))

		if should_show and not _instances.has(npc_id):
			_spawn_instance(npc_id)
		elif not should_show and _instances.has(npc_id):
			_instances[npc_id].queue_free()
			_instances.erase(npc_id)

func _spawn_instance(npc_id: String) -> void:
	var client: CharacterBody2D = client_scene.instantiate()
	add_child(client)
	client.set_appearance(NpcRoster.get_texture(npc_id))
	client.set_debug_id(npc_id)
	client.job_id = NpcDirector.get_job_id(npc_id)
	client.mirror_npc(npc_id)
	_instances[npc_id] = client
