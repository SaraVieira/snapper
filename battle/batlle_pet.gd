extends Node2D

signal attack_result(hit_success: bool)

@onready var position_marker: ColorRect = $"Position Marker"

# RIGHT
@onready var green_r: Marker2D = $"Green R"
@onready var yellow_r: Marker2D = $"Yellow R"
@onready var red_r: Marker2D = $"Red R"
@onready var end_r: Marker2D = $"End R"


# LEFT
@onready var green_l: Marker2D = $"Green L"
@onready var yellow_l: Marker2D = $"Yellow L"
@onready var red_l: Marker2D = $"Red L"
@onready var end_l: Marker2D = $"End L"


@onready var hit: Label = $"HIT"

var direction = 1

var likelyness_to_hit: float = 0
var hit_success: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var marker_pos = position_marker.global_position.x
	var end_r_pos = end_r.global_position
	var end_l_pos = end_l.global_position

	if marker_pos >= end_r_pos.x:
		direction = -1
	elif marker_pos <= end_l_pos.x:
		direction = 1

	position_marker.global_position.x += direction * 100 * delta

	# on click space, stop the position marker and check if it is in the green zone
	if Input.is_action_just_pressed("attack"):
		GameState.is_attacking = true

		# direction = 0
		if marker_pos >= green_l.global_position.x and marker_pos <= green_r.global_position.x:
			likelyness_to_hit = 0.8
		elif marker_pos >= yellow_l.global_position.x and marker_pos <= yellow_r.global_position.x:
			likelyness_to_hit = 0.4
		elif marker_pos >= red_l.global_position.x and marker_pos <= red_r.global_position.x:
			likelyness_to_hit = 0.2
		else:
			likelyness_to_hit = 0.0


		await on_attack_result()
		GameState.is_attacking = false
		emit_signal("attack_result", hit_success)



func on_attack_result() -> void:
	hit_success = randf() < likelyness_to_hit
	

	hit.visible = true
	if hit_success:
		hit.text = "Hit!"
		await (get_tree().create_timer(1.0)).timeout
		hit.visible = false
	else:
		hit.text = "Miss!"
		await (get_tree().create_timer(1.0)).timeout
		hit.visible = false
