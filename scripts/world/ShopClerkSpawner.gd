extends Node2D

## Muestra al NPC de este local (ej. npc_01 en la gomería) en el
## mostrador — o caminando desde la entrada — mientras esta escena esté
## cargada. Nunca decide el movimiento: solo refleja lo que diga
## NpcDirector (mismo patrón que CityWandererSpawner/JobEncounterSpawner).
## Si no estás mirando esta escena en el momento justo en que entra o
## sale, simplemente no lo ves aparecer/desaparecer — la caminata ya se
## simuló sola en NpcDirector.

const VISIBLE_MODES := ["entering_workplace", "at_work", "leaving_workplace"]

@export var npc_id: String = ""
@export var client_scene: PackedScene

var _instance: CharacterBody2D = null

## Si ya forzamos "mirando abajo" para este pasaje por el mostrador —
## sin esto, cada frame parado ahí volvería a intentar pisar la
## animación (inofensivo, pero innecesario).
var _faced_counter := false

func _process(_delta: float) -> void:
	var mode := NpcDirector.get_mode(npc_id)
	var should_show: bool = VISIBLE_MODES.has(mode)

	if should_show and _instance == null:
		_instance = client_scene.instantiate()
		add_child(_instance)
		_instance.set_appearance(NpcRoster.get_texture(npc_id))
		_instance.mirror_npc(npc_id)
		_faced_counter = false
	elif not should_show and _instance != null:
		_instance.queue_free()
		_instance = null
		_faced_counter = false

	if mode == "at_work":
		if _instance and not _faced_counter:
			_instance.animation_player.play("idle_down")
			_faced_counter = true
	else:
		_faced_counter = false
