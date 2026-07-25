extends Control

@onready var cat: Node2D = $cat

var ACTIONS := ["pet", "hand", "treats", "sound", "sit", "photo"]
@onready var STATES = {
	"choose": { "instance": null, "cooldown": 0.0, "ui": preload("res://battle/choose/choose.tscn") },
	"pet": { "instance": null, "cooldown": 0.0, "ui": preload("res://battle/pet/pet.tscn") },
	"hand": { "instance": null, "cooldown": 0.0, "ui": preload("res://battle/hand/hand.tscn") },
	"treats": { "instance": null, "cooldown": 0.0, "ui": preload("res://battle/treats/treats.tscn") },
	"sound": { "instance": null, "cooldown": 0.0, "ui": preload("res://battle/sound/sound.tscn") },
	"sit": { "instance": null, "cooldown": 0.0, "ui": preload("res://battle/sit/sit.tscn") },
	"photo": { "instance": null, "cooldown": 0.0, "ui": preload("res://battle/photo/photo.tscn") },
}

var current_action := ""

var trust := 0


func _show_choose() -> void:
	var inst = STATES["choose"]["ui"].instantiate()
	STATES["choose"]["instance"] = inst
	add_child(inst)
	inst.setup(cat.data, trust)

func _ready() -> void:
	trust = cat.data.starting_trust

	BattleSignals.connect("on_menu_option_selected", _on_battle_choose_option_selected)
	BattleSignals.connect("on_pet_result", _on_pet_result)
	BattleSignals.connect("on_sound_result", _on_sound_result)

	_show_choose()


func _on_battle_choose_option_selected(option_action: String) -> void:
	current_action = option_action

	var inst = STATES[option_action]["ui"].instantiate()
	STATES[option_action]["instance"] = inst
	add_child(inst)

	STATES["choose"]["instance"].queue_free()
	STATES["choose"]["instance"] = null


func change_scene_to_choose() -> void:
	if current_action == "":
		return

	STATES[current_action]["instance"].queue_free()
	STATES[current_action]["instance"] = null
	current_action = ""

	_show_choose()



func _apply_result(action: String, hit_success: bool) -> void:
	var delta := 0

	if action == cat.data.hates:
		# Fires on a hit too. This one can't be out-played.
		delta = cat.data.hated_penalty()
	elif hit_success:
		delta = cat.data.gain_for(action)
	else:
		delta = cat.data.penalty_for(action)

	trust = clampi(trust + delta, cat.data.flee_threshold, 100)
	print("%s: %s %+d -> trust %d" % [cat.data.display_name, action, delta, trust])


func _on_pet_result(hit_success: bool) -> void:
	_apply_result("pet", hit_success)
	change_scene_to_choose()


func _on_sound_result(hit_success: bool) -> void:
	_apply_result("sound", hit_success)
	change_scene_to_choose()
