extends Node
@onready var TIME : float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var user_time = Time.get_time_dict_from_system()
	TIME =  user_time.hour + user_time.minute / 60.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	TIME += delta
	
	
