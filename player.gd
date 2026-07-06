extends CharacterBody2D


@export var SPEED = 50
@export var animation_tree: AnimationTree

var input_vector
var playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	playback = animation_tree["parameters/playback"]

func _physics_process(delta: float) -> void:
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED
	move_and_slide()
	select_animation()
	update_animation_params()
	
func select_animation():
	if velocity == Vector2.ZERO:
		playback.travel("Idle")
	else:
		playback.travel("Walk")
	
func update_animation_params():
	if input_vector == Vector2.ZERO:
		return 
		
	animation_tree["parameters/Idle/blend_position"] = input_vector	
	animation_tree["parameters/Walk/blend_position"] = input_vector	
