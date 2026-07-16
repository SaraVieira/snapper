extends Node2D

@onready var canvas = $CanvasModulate;
@onready var sun = $Sun
@onready var moon = $Moon
@export var gradient: GradientTexture1D;
var startSunPosition: float = 375.0
var endSunPosition: float = -55.0
var sunMaxEnergy: float = 0.2
var moonMaxEnergy: float = 0.5

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	var t = fmod(GameState.TIME, 24.0) / 24.0
	var brightness = (sin((t - 0.25) * TAU) + 1.0) / 2.0
	canvas.color = gradient.gradient.sample(brightness)

	var day_progress = clamp((t - 0.25) * 2.0, 0.0, 1.0)
	sun.position.x = lerp(startSunPosition, endSunPosition, day_progress)
	sun.energy = sunMaxEnergy * brightness

	moon.energy = moonMaxEnergy * (1.0 - brightness)

	$GPUParticles2D.emitting = GameState.is_night()
	moon.enabled = GameState.is_night()
