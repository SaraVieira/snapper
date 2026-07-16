@tool
extends TabContainer
## Root control of the "Project Wiki" main screen tab.
## Hosts the three views: kanban board, daily progress and wiki.

const DocsStore := preload("res://addons/project_wiki/docs_store.gd")
const KanbanBoard := preload("res://addons/project_wiki/ui/kanban_board.gd")
const ProgressView := preload("res://addons/project_wiki/ui/progress_view.gd")
const WikiView := preload("res://addons/project_wiki/ui/wiki_view.gd")


func _ready() -> void:
	DocsStore.ensure_dirs()

	var board := KanbanBoard.new()
	board.name = "Board"
	add_child(board)

	var progress := ProgressView.new()
	progress.name = "Daily Progress"
	add_child(progress)

	var wiki := WikiView.new()
	wiki.name = "Wiki"
	add_child(wiki)

	visibility_changed.connect(_on_visibility_changed)
	tab_changed.connect(func(_tab: int) -> void: _refresh_current())


func _on_visibility_changed() -> void:
	if visible:
		_refresh_current()


func _refresh_current() -> void:
	var current := get_current_tab_control()
	if current != null and current.has_method("refresh"):
		current.refresh()
