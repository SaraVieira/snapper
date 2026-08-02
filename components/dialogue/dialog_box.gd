extends Control

@onready var rich_text_label: RichTextLabel = %dialogue


# Called when the node enters the scene tree for the first time.
func set_text(dialog: String) -> void:
	rich_text_label.text = dialog


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
