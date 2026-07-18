extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	on_change_scene()
	GameState.changed_scene.connect(on_change_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_change_scene() -> void:
	var new_scene_resource = load(GameState.currentLevel) # Load the new level from disk
	var new_scene_node = new_scene_resource.instantiate();
	for n in $CurrentLevel.get_children():
		$CurrentLevel.remove_child(n)
		n.queue_free()
	$CurrentLevel.add_child(new_scene_node)
