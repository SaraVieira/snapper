@tool
extends EditorPlugin

const MainPanel := preload("res://addons/project_wiki/ui/main_panel.gd")

var _main_panel: Control


func _enter_tree() -> void:
	_main_panel = MainPanel.new()
	# The editor main screen is a VBoxContainer, so the panel must expand via
	# size flags — anchors are ignored inside containers.
	_main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(_main_panel)
	_make_visible(false)


func _exit_tree() -> void:
	if is_instance_valid(_main_panel):
		_main_panel.queue_free()
	_main_panel = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_main_panel):
		_main_panel.visible = visible


func _get_plugin_name() -> String:
	return "Project Wiki"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(&"TextFile", &"EditorIcons")
