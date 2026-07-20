extends Node2D
var _transitioning = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for n in $CurrentLevel.get_children():
		n.queue_free()
	$CurrentLevel.add_child(GameState.currentLevel.scene.instantiate())
	GameState.changed_scene.connect(on_change_scene, CONNECT_DEFERRED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_change_scene() -> void:
	if _transitioning:
		return
	_transitioning = true

	var tween = create_tween()
	tween.tween_property($FadeLayer/Fade, "material:shader_parameter/progress", 1.0, 0.35)
	await tween.finished

	for n in $CurrentLevel.get_children():
		n.queue_free()
	$CurrentLevel.add_child(GameState.currentLevel.scene.instantiate())
	$FadeLayer/Fade.material.set_shader_parameter("fade_color", GameState.currentLevel.fade)

	tween = create_tween()
	tween.tween_property($FadeLayer/Fade, "material:shader_parameter/progress", 0.0, 0.35)
	await tween.finished
	_transitioning = false
