extends Node2D

@onready var canvas = $CanvasModulate;
@onready var sun = $PointLight2D
@export var gradient: GradientTexture1D;
var startSunPosition: float = 375.0
var endSunPosition: float = -55.0
var sunMaxEnergy: float = 0.44

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var t = fmod(GameState.TIME, 24.0) / 24.0
	var brightness = (sin((t - 0.25) * TAU) + 1.0) / 2.0
	canvas.color = gradient.gradient.sample(brightness)

	# 0.0 at 6 AM, 1.0 at 6 PM; parked at an edge overnight while faded out
	var day_progress = clamp((t - 0.25) * 2.0, 0.0, 1.0)
	sun.position.x = lerp(startSunPosition, endSunPosition, day_progress)
	sun.energy = sunMaxEnergy * brightness
	
