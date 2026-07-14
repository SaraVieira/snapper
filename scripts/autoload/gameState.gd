@tool
extends Node
@onready var TIME : float
@onready var TIME_IN_SIN: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	TIME += delta
	TIME_IN_SIN = (sin(TIME - PI/2) +1) /2
