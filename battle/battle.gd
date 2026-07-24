extends Control


@onready var hand_ui: Node2D = $Pet;
@onready var treats_ui: Node2D = $Pet;
@onready var sound_ui: Node2D = $Pet;
@onready var sit_ui: Node2D = $Pet;
@onready var photo_ui: Node2D = $Pet;


var ACTIONS := ["pet", "hand", "treats", "sound", "sit", "photo"]
@onready var STATES = {
	"choose": { "active": true, "cooldown": 0.0, "ui": $BattleChoose },
	"pet": { "active": false, "cooldown": 0.0, "ui": $Pet },
	"hand": { "active": false, "cooldown": 0.0, "ui": hand_ui },
	"treats": { "active": false, "cooldown": 0.0, "ui": treats_ui },
	"sound": { "active": false, "cooldown": 0.0, "ui": sound_ui },
	"sit": { "active": false, "cooldown": 0.0, "ui": sit_ui },
	"photo": { "active": false, "cooldown": 0.0, "ui": photo_ui },
}

func _ready() -> void:
	STATES["choose"].ui.visible = true;




func _on_battle_choose_option_selected(option_action: String) -> void:
	STATES[option_action]["active"] = true
	STATES[option_action]["ui"].visible = true
	STATES["choose"].ui.visible = false;
	STATES["choose"]["active"] = false;


func _on_pet_attack_result(hit_success: bool) -> void:

	var current_action = ""
	for action in STATES.keys():
		if STATES[action]["active"]:
			current_action = action
			break

	STATES[current_action]["active"] = false
	STATES[current_action]["ui"].visible = false
	STATES["choose"].ui.visible = true;
