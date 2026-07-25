extends Control

@onready var red: ColorRect = $red
@onready var yellow: ColorRect = $yellow
@onready var green: ColorRect = $green
@onready var label: Label = $label
@onready var hit: Label = $HIT
var red_value: float = 0.0
var yellow_value: float = 0.0
var green_value: float = 0.0
var active_color;
var hasAttacked: bool = false


func set_shader_parameter(color_rect: ColorRect, parameter_name: String, value) -> void:
	var material = color_rect.get_material()
	if material is ShaderMaterial:
		material.set_shader_parameter(parameter_name, value)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_color = red;
	hit.visible = false;
	set_shader_parameter(red, "Color", Color("red"))
	set_shader_parameter(yellow, "Color", Color("yellow"))
	set_shader_parameter(green, "Color", Color("green"))

	set_shader_parameter(red, "FloatParameter", 0.0)
	set_shader_parameter(yellow, "FloatParameter", 0.0)
	set_shader_parameter(green, "FloatParameter", 0.0)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var value = pingpong(Time.get_ticks_msec() / 500.0, 1.0)

	if(not hasAttacked): set_shader_parameter(active_color, "FloatParameter", value)

	if Input.is_action_just_pressed("attack") and active_color == red:
		red_value = value
		active_color = yellow
	elif Input.is_action_just_pressed("attack") and active_color == yellow:
		yellow_value = value
		active_color = green
	elif Input.is_action_just_pressed("attack") and active_color == green and not hasAttacked:
		hasAttacked = true
		green_value = value
		attack()

func attack() -> void:
	var allValue =  (red_value + green_value + yellow_value) / 3
	var hit_success = randf() < allValue
	hit.visible = true

	if hit_success:
		hit.text = "Hit!"
		await (get_tree().create_timer(1.0)).timeout
		hit.visible = false
	else:
		hit.text = "Miss!"
		await (get_tree().create_timer(1.0)).timeout
		hit.visible = false
	await (get_tree().create_timer(1.0)).timeout
	BattleSignals.emit_signal("on_sound_result", hit_success)
