extends Node2D

var DIALOG_BOX = preload("uid://bisv7lleko3tx")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.connect("chat_started", _on_chat_start)
	GameState.connect("chat_ended", _on_chat_end)

func _on_chat_start(dialog: String):
		var instance = DIALOG_BOX.instantiate()
		add_child(instance)
		instance.set_text(dialog)


func _on_chat_end() -> void:
	get_node("DialogBox").queue_free()
