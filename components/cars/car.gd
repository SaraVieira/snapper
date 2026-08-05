@tool

extends Node2D

@export_enum("BusPink","Orange","Bus","green","gray","blue","red") var car: String
@export var speed: float = 1.0
@export_enum("Left", "Right") var direction: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	z_index = 1
	if not car:
		car = "Bus"
	if not direction:
		direction = "Right"

	if(direction == "Left"):
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false

	match car:
		"BusPink":
			$Sprite.texture = preload("res://assets/cars/bu-pinks.png")
		"Orange":
			$Sprite.texture = preload("res://assets/cars/orange.png")
		"Bus":
			$Sprite.texture = preload("res://assets/cars/bus.png")
		"green":
			$Sprite.texture = preload("res://assets/cars/green.png")
		"gray":
			$Sprite.texture = preload("res://assets/cars/gray.png")
		"blue":
			$Sprite.texture = preload("res://assets/cars/blue.png")
		"red":
			$Sprite.texture = preload("res://assets/cars/red.png")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	if(direction == "Left"):
		position.x -= speed * delta
	else:
		position.x += speed * delta

	if(position.x < -2000 or position.x > 2000):
		queue_free()
