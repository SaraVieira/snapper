extends StaticBody2D

@export var data: CatData

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trigger: Area2D = $Area2D

func _ready() -> void:
	apply_data()


## Pushes `data` onto the nodes. Called again by battle.gd, which swaps in the
## CatData of whichever cat the player actually touched.
func apply_data() -> void:
	if data and data.overworld_frames:
		sprite.sprite_frames = data.overworld_frames
	sprite.play("idle")


## The battle screen reuses this scene as a portrait, and the overworld is still
## alive underneath during a battle — so strip the physics, or the portrait sits
## in the world as an invisible wall that can start a second battle.
func enter_battle_mode() -> void:
	collision_layer = 0
	collision_mask = 0
	trigger.monitoring = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.start_battle(data)
