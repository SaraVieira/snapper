extends Node2D

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
