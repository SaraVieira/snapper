extends StaticBody2D

@export var data: CatData

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if data and data.overworld_frames:
		sprite.sprite_frames = data.overworld_frames
	sprite.play("idle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print_debug("%s noticed you" % data.display_name)
