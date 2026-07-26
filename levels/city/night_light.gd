extends PointLight2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not GameState.is_night():
		self.enabled = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not GameState.is_night():
		self.enabled = false
	else:
		self.enabled = true
