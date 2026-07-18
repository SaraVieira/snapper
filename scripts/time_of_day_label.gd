extends Node

const DEFAULT_SIZE = 2.833
@onready var green = $Stamina/Green
@onready var yellow = $Stamina/Yellow
@onready var red = $Stamina/Red


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.player_stamina_changed.connect(_on_player_stamina_changed)

func _on_player_stamina_changed(stamina: int) -> void:
	var size = DEFAULT_SIZE * (stamina / 100.0)
	var sprites = [green, yellow, red]

	for n in sprites:
		n.scale.x = size

	if stamina > 60:
		green.visible = true
		yellow.visible = false
		red.visible = false
	elif stamina > 30:
		green.visible = false
		yellow.visible = true
		red.visible = false
	else:
		green.visible = false
		yellow.visible = false
		red.visible = true




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var minutes = (int((GameState.TIME - int(GameState.TIME)) * 60))

	var in_game_hours = (int(GameState.TIME) % 24)
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
