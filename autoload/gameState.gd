extends Node

signal player_stamina_changed(stamina: int)
signal player_died()
signal changed_scene()
signal hour_changed(hour: int)
signal day_started
signal night_started


const DAY_START_HOUR := 6
const NIGHT_START_HOUR := 18
var LEVELS = {
	  "PARK": { "scene": preload("res://levels/park/park.tscn"), "fade": Color("2e5e40") },
	  "CITY": { "scene": preload("res://levels/city/city.tscn"), "fade": Color("3d3d4e") },
}
var currentLevel = LEVELS["CITY"]
var player_stamina := 100

@export var hours_per_second := 1.0

var TIME: float
var _last_hour: int = -1

func change_scene(scene: String) -> void:
	if LEVELS.has(scene):
		currentLevel = LEVELS[scene]
		changed_scene.emit()
	else:
		push_warning("Unknown level: " + scene)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var user_time = Time.get_time_dict_from_system()
	TIME =  user_time.hour + user_time.minute / 60.0



func _process(delta: float) -> void:
	if(player_stamina <= 0):
		player_died.emit()

	TIME += delta * hours_per_second
	var current_hour = hour()
	if current_hour != _last_hour:
		_last_hour = current_hour

		player_stamina = clamp(player_stamina - 4, 0, 100)
		player_stamina_changed.emit(player_stamina)

		hour_changed.emit(current_hour)
		if current_hour == DAY_START_HOUR:
			day_started.emit()
		elif current_hour == NIGHT_START_HOUR:
			night_started.emit()


func hour() -> int:
	return int(TIME) % 24


func is_night() -> bool:
	return hour() < DAY_START_HOUR or hour() >= NIGHT_START_HOUR
