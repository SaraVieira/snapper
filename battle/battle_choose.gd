extends Control

signal option_selected(option_action: String)

const COLS := 3

var active_index := 0
var option_keys


func _ready() -> void:
	var parent = get_parent()
	if "ACTIONS" in parent:
		option_keys = parent.ACTIONS
	else:
		push_warning("BattleChoose should be a child of Battle; using defaults")
		option_keys = ["pet", "hand", "treats", "sound", "sit", "photo"]
	update_active_option()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("enter"):
		emit_signal("option_selected", option_keys[active_index])

	if Input.is_action_just_pressed("left"):
		active_index = (active_index - 1 + option_keys.size()) % option_keys.size()
		update_active_option()
	elif Input.is_action_just_pressed("right"):
		active_index = (active_index + 1) % option_keys.size()
		update_active_option()

	if Input.is_action_just_pressed("up"):
		active_index = (active_index - COLS + option_keys.size()) % option_keys.size()
		update_active_option()
	elif Input.is_action_just_pressed("down"):
		active_index = (active_index + COLS) % option_keys.size()
		update_active_option()


func _container(action: String) -> HBoxContainer:
	return get_node("GridContainer/" + action.capitalize() + "Container")


func update_active_option() -> void:
	for i in option_keys.size():
		_container(option_keys[i]).get_node("active_container/active").visible = i == active_index
