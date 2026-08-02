extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var dialog_box: Control = %DialogBox

@export var frames: SpriteFrames
@export var char_name: String
@export var is_interactable: bool
@export var text: String;

var player_is_in_chat_zone = false

func _ready() -> void:

	if frames: 
		animated_sprite_2d.sprite_frames = frames

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("talk") and player_is_in_chat_zone:
		GameState.start_chatting(text)
	
	if Input.is_action_just_pressed("escape") or Input.is_action_just_pressed("enter"):
		GameState.stop_chatting()
		


func _on_npc_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") && is_interactable:
		player_is_in_chat_zone = true;
		print("hello")



func _on_npc_player_exited(body: Node2D) -> void:
	if body.is_in_group("player") && is_interactable:
		player_is_in_chat_zone = false;
		GameState.stop_chatting()
		print("goodbye")
