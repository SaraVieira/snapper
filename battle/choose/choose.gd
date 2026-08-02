extends Control

const COLS := 3

var active_index := 0
var option_keys

## action -> bool. Filled in by setup(); locked options fade and are skipped.
var locked := {}


func _ready() -> void:
	var parent = get_parent()
	if "ACTIONS" in parent:
		option_keys = parent.ACTIONS
	else:
		push_warning("BattleChoose should be a child of Battle; using defaults")
		option_keys = ["pet", "hand", "treats", "sound", "sit", "photo"]
	update_active_option()


## Called by battle.gd right after add_child(), every time the menu comes back.
func setup(data: CatData, current_trust: int) -> void:
	for action in option_keys:
		locked[action] = not data.is_available(action, current_trust)
		_container(action).modulate.a = 0.35 if locked[action] else 1.0

	_move(0)


func _is_locked(action: String) -> bool:
	return locked.get(action, false)


func _move(step: int) -> void:
	var n: int = option_keys.size()
	var dir := -1 if step < 0 else 1
	var i: int = (active_index + step + n * 2) % n

	for _attempt in n:
		if not _is_locked(option_keys[i]):
			active_index = i
			update_active_option()
			return
		i = (i + dir + n) % n


func _process(delta: float) -> void:
	# Walking away is only allowed from the menu — not mid-minigame.
	if Input.is_action_just_pressed("back"):
		GameState.end_battle()
		return

	if Input.is_action_just_pressed("enter") and not _is_locked(option_keys[active_index]):
		BattleSignals.emit_signal("on_menu_option_selected", option_keys[active_index])

	if Input.is_action_just_pressed("left"):
		_move(-1)
	elif Input.is_action_just_pressed("right"):
		_move(1)

	if Input.is_action_just_pressed("up"):
		_move(-COLS)
	elif Input.is_action_just_pressed("down"):
		_move(COLS)


func _container(action: String) -> HBoxContainer:
	return get_node("GridContainer/" + action.capitalize() + "Container")


func update_active_option() -> void:
	for i in option_keys.size():
		_container(option_keys[i]).get_node("active_container/active").visible = i == active_index
