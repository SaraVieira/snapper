extends Node2D
@onready var ui: Node2D = $CanvasLayer/Ui

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_spawn_level()
	GameState.changed_scene.connect(on_change_scene, CONNECT_DEFERRED)


# Control-rooted levels (the battle) need a CanvasLayer parent, otherwise their
# anchors resolve against a Node2D's empty rect and everything collapses to 0x0.
func _spawn_level() -> void:
	for n in $CurrentLevel.get_children():
		n.queue_free()

	var scene = GameState.currentLevel.scene.instantiate()
	if scene is Control:
		var layer := CanvasLayer.new()
		layer.layer = -1  # below Ui and FadeLayer so the transition still covers it
		layer.add_child(scene)
		$CurrentLevel.add_child(layer)
	else:
		$CurrentLevel.add_child(scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ui.visible = GameState.showUI

func on_change_scene() -> void:
	var tween = create_tween()
	tween.tween_property($FadeLayer/Fade, "material:shader_parameter/progress", 1.0, 0.35)
	await tween.finished

	_spawn_level()
	$FadeLayer/Fade.material.set_shader_parameter("fade_color", GameState.currentLevel.fade)

	tween = create_tween()
	tween.tween_property($FadeLayer/Fade, "material:shader_parameter/progress", 0.0, 0.35)
	await tween.finished
	GameState.is_changing_scene = false
