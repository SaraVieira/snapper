extends Node

signal player_stamina_changed(stamina: int)
signal player_died()
signal changed_scene()
signal battle_started(cat_data: CatData)
signal battle_ended()
signal hour_changed(hour: int)
signal day_started
signal night_started



const DAY_START_HOUR := 6
const NIGHT_START_HOUR := 18
const MAX_STAMINA := 100
const STAMINA_PER_HOUR := 4
var LEVELS = {
	  "SUBWAY": {"scene": preload("res://levels/subway/subway.tscn"), "fade": Color("696969ff")},
	  "PARK": { "scene": preload("res://levels/park/park.tscn"), "fade": Color("2e5e40") },
	  "CITY": { "scene": preload("res://levels/city/city.tscn"), "fade": Color("3d3d4e") }
}
var currentLevel = LEVELS["SUBWAY"]
var player_stamina := MAX_STAMINA
var _player_dead := false
var is_attacking := false

@export var hours_per_second := 1.0

var TIME: float
var _last_hour: int = -1

var is_changing_scene := false
var is_battling := false


func change_scene(scene: String) -> void:
	if is_changing_scene or is_battling:
		return

	if LEVELS.has(scene):
		is_changing_scene = true
		currentLevel = LEVELS[scene]
		changed_scene.emit()
	else:
		push_warning("Unknown level: " + scene)


## A battle is an overlay on top of the live overworld, not a level swap — World
## pauses the tree and puts battle.tscn on its own CanvasLayer, so the level the
## player was standing in is still there when the battle ends.
func start_battle(cat_data: CatData) -> void:
	if is_battling or is_changing_scene:
		return

	is_battling = true
	battle_started.emit(cat_data)


func end_battle() -> void:
	if not is_battling:
		return

	is_battling = false
	battle_ended.emit()


## The only way stamina should change. Emits player_died once on the transition
## to zero rather than continuously while at zero, and re-arms if it comes back.
func set_stamina(value: int) -> void:
	var clamped := clampi(value, 0, MAX_STAMINA)
	if clamped == player_stamina:
		return

	player_stamina = clamped
	player_stamina_changed.emit(player_stamina)

	if player_stamina > 0:
		_player_dead = false
	elif not _player_dead:
		_player_dead = true
		player_died.emit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var user_time = Time.get_time_dict_from_system()
	TIME =  user_time.hour + user_time.minute / 60.0



func _process(delta: float) -> void:
	TIME += delta * hours_per_second
	var current_hour = hour()
	if current_hour != _last_hour:
		_last_hour = current_hour

		set_stamina(player_stamina - STAMINA_PER_HOUR)

		hour_changed.emit(current_hour)
		if current_hour == DAY_START_HOUR:
			day_started.emit()
		elif current_hour == NIGHT_START_HOUR:
			night_started.emit()


func hour() -> int:
	return int(TIME) % 24


func is_night() -> bool:
	return hour() < DAY_START_HOUR or hour() >= NIGHT_START_HOUR
