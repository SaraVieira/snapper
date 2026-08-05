class_name Level extends Node2D


@export var SpawnPoints: Array[Marker2D] = []

@export var default_spawn: StringName = &""


func _ready() -> void:
	var spawn := _find_spawn(GameState.pending_spawn)
	if spawn == null:
		return

	var player := _find_player()
	if player:
		player.global_position = spawn.global_position


## Scoped to this level's own subtree. During a transition the outgoing level is
## still in the tree, so the "player" group briefly holds two nodes — and each
## level ships its own player instance.
func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		if is_ancestor_of(node):
			return node as Node2D

	return null


func _find_spawn(spawn_name: StringName) -> Marker2D:
	for wanted in [spawn_name, default_spawn]:
		if wanted == &"":
			continue
		for point in SpawnPoints:
			if point.name == wanted:
				return point
		push_warning("%s: no spawn point named '%s'" % [name, wanted])

	return SpawnPoints[0] if not SpawnPoints.is_empty() else null
