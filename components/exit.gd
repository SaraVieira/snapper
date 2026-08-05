class_name LevelExit extends Area2D

@export_enum("SUBWAY", "PARK", "CITY") var target_level: String

@export var target_spawn: StringName = &""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.change_scene(target_level, target_spawn)
