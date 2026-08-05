extends Node2D

const BATTLE := preload("res://battle/battle.tscn")

@onready var ui: Node2D = $CanvasLayer/Ui
@onready var battle_layer: CanvasLayer = $BattleLayer
@onready var fade: ColorRect = $FadeLayer/Fade

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_spawn_level()
	GameState.changed_scene.connect(on_change_scene, CONNECT_DEFERRED)
	# Deferred: both are emitted from inside a body_entered callback, and neither
	# pausing the tree nor freeing a level is safe mid-physics-flush.
	GameState.battle_started.connect(on_battle_started, CONNECT_DEFERRED)
	GameState.battle_ended.connect(on_battle_ended, CONNECT_DEFERRED)


# Control-rooted levels need a CanvasLayer parent, otherwise their
# anchors resolve against a Node2D's empty rect and everything collapses to 0x0.
func _spawn_level() -> void:
	for n in $CurrentLevel.get_children():
		# Detached before freeing: queue_free() only takes effect at the end of the
		# frame, which would leave the outgoing level in the tree — and in the
		# "player" group — while the incoming level runs _ready.
		$CurrentLevel.remove_child(n)
		n.queue_free()

	var scene = GameState.currentLevel.scene.instantiate()
	if scene is Control:
		var layer := CanvasLayer.new()
		layer.layer = -1  # below Ui and FadeLayer so the transition still covers it
		layer.add_child(scene)
		$CurrentLevel.add_child(layer)
	else:
		$CurrentLevel.add_child(scene)


## The tween is bound to Fade, which is PROCESS_MODE_ALWAYS, so transitions keep
## running while the tree is paused for a battle.
func _fade_to(progress: float) -> void:
	var tween := fade.create_tween()
	tween.tween_property(fade, "material:shader_parameter/progress", progress, 0.35)
	await tween.finished


func on_change_scene() -> void:
	await _fade_to(1.0)

	_spawn_level()
	fade.material.set_shader_parameter("fade_color", GameState.currentLevel.fade)

	await _fade_to(0.0)
	GameState.is_changing_scene = false


func on_battle_started(cat_data: CatData) -> void:
	# Pause before the fade, so the player can't keep walking into things during it.
	get_tree().paused = true
	fade.material.set_shader_parameter("fade_color", Color.BLACK)
	await _fade_to(1.0)

	var battle := BATTLE.instantiate()
	battle.setup(cat_data)
	battle_layer.add_child(battle)
	ui.visible = false

	await _fade_to(0.0)


func on_battle_ended() -> void:
	await _fade_to(1.0)

	for n in battle_layer.get_children():
		n.queue_free()
	ui.visible = true
	fade.material.set_shader_parameter("fade_color", GameState.currentLevel.fade)

	await _fade_to(0.0)
	# Unpause last: the overworld stays frozen until the player can see it again.
	get_tree().paused = false
