extends Node2D

@onready var canvas = $CanvasModulate;
@onready var sun = $PointLight2D
@export var gradient: GradientTexture1D;
var startSunPosition: float = 375.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	canvas.color = gradient.gradient.sample(GameState.TIME_IN_SIN)
	sun.position = Vector2(startSunPosition + delta * 35, sun.position.y)
