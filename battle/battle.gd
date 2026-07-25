extends Control


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



func _ready() -> void:
	STATES["choose"]["instance"] = STATES["choose"].ui.instantiate()
	add_child(STATES["choose"]["instance"])
	BattleSignals.connect("on_menu_option_selected", _on_battle_choose_option_selected)
	BattleSignals.connect("on_pet_result", _on_pet_on_pet_attack)
	BattleSignals.connect("on_sound_result", _on_sound_ui_on_sound_attack)

func _on_battle_choose_option_selected(option_action: String) -> void:
	STATES[option_action]["active"] = true
	STATES[option_action]["instance"] = STATES[option_action]["ui"].instantiate()
	add_child(STATES[option_action]["instance"])

	STATES["choose"]["instance"].queue_free()

func change_scene_to_choose() -> void:
	var current_action = ""
	print(current_action)
	for action in STATES.keys():
		if STATES[action]["instance"] != null:
			current_action = action
			break

	STATES[current_action]["instance"].queue_free()
	STATES["choose"]["instance"] = STATES["choose"]["ui"].instantiate()
	add_child(STATES["choose"]["instance"])


func _on_pet_on_pet_attack(hit_success: bool) -> void:
	change_scene_to_choose()


func _on_sound_ui_on_sound_attack(hit_success: bool) -> void:
	change_scene_to_choose()
