@tool
extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var time_since_start = GameState.TIME
	var hours = (GameState.TIME)
	var minutes = (int((GameState.TIME - int(GameState.TIME)) * 60))

	var in_game_hours = (int(hours) % 24) + 14
	var in_game_minutes = int((GameState.TIME - int(GameState.TIME)) * 60)
	var in_game_hours_12 = ((in_game_hours + 11) % 12 + 1)
	var am_pm = "AM" if in_game_hours < 12 else "PM"


	var str_hours = str(in_game_hours_12)
	var str_minutes = str(in_game_minutes)

	if int(in_game_hours_12) < 10:
		str_hours = "0" + str_hours
	if int(minutes) < 10:
		str_minutes = "0" + str_minutes


	$Label.text = str_hours + " : " + str_minutes +" " + am_pm
