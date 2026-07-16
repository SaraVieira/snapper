@tool
extends VBoxContainer
## The kanban board view. Owns the task list (the single source of truth in
## memory) and persists it to docs/todos.md after every change.
##
## Task dictionaries: {id, title, status, category, urgency, description}

const DocsStore := preload("res://addons/project_wiki/docs_store.gd")
const KanbanColumn := preload("res://addons/project_wiki/ui/kanban_column.gd")
const TodoDialog := preload("res://addons/project_wiki/ui/todo_dialog.gd")

var tasks: Array = []

var _next_id := 1
var _columns := {}
var _dialog: ConfirmationDialog


func _ready() -> void:
	add_theme_constant_override("separation", 8)

	var toolbar := HBoxContainer.new()
	add_child(toolbar)

	var add_button := Button.new()
	add_button.text = "+ Add Todo"
	add_button.pressed.connect(func() -> void: open_new_dialog("Todo"))
	toolbar.add_child(add_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	var hint := Label.new()
	hint.text = "Saved to docs/todos.md  ·  click a card to edit, drag to move"
	hint.modulate = Color(1, 1, 1, 0.45)
	toolbar.add_child(hint)

	var columns_box := HBoxContainer.new()
	columns_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns_box.add_theme_constant_override("separation", 8)
	add_child(columns_box)

	for status in DocsStore.STATUSES:
		var column := KanbanColumn.new()
		column.status = status
		column.board = self
		columns_box.add_child(column)
		_columns[status] = column

	_dialog = TodoDialog.new()
	add_child(_dialog)
	_dialog.saved.connect(_on_dialog_saved)
	_dialog.delete_requested.connect(_on_dialog_delete)

	refresh()


## Reloads the board from docs/todos.md. Safe to call at any time because
## every in-memory change is written to disk immediately.
func refresh() -> void:
	tasks = []
	_next_id = 1
	for task in DocsStore.load_todos():
		task["id"] = _next_id
		_next_id += 1
		tasks.append(task)
	_rebuild()


func categories() -> Array:
	var seen := {}
	for task in tasks:
		var category := str(task.get("category", "")).strip_edges()
		if category != "":
			seen[category] = true
	var out := seen.keys()
	out.sort()
	return out


func open_new_dialog(status: String) -> void:
	_dialog.open_new(status, categories())


func open_edit_dialog(task: Dictionary) -> void:
	_dialog.open_edit(task, categories())


func move_task(id: int, new_status: String, before_id: int) -> void:
	if id == before_id:
		return
	var index := _find_task(id)
	if index == -1:
		return
	var task: Dictionary = tasks[index]
	tasks.remove_at(index)
	var insert_at := tasks.size()
	if before_id != -1:
		var before_index := _find_task(before_id)
		if before_index != -1:
			insert_at = before_index
	task["status"] = new_status
	tasks.insert(insert_at, task)
	_save_and_rebuild()


func _on_dialog_saved(data: Dictionary) -> void:
	if int(data.get("id", 0)) == 0:
		data["id"] = _next_id
		_next_id += 1
		tasks.append(data)
	else:
		var index := _find_task(int(data["id"]))
		if index == -1:
			return
		var task: Dictionary = tasks[index]
		for key in ["title", "status", "category", "urgency", "description"]:
			task[key] = data[key]
	_save_and_rebuild()


func _on_dialog_delete(id: int) -> void:
	var index := _find_task(id)
	if index == -1:
		return
	tasks.remove_at(index)
	_save_and_rebuild()


func _save_and_rebuild() -> void:
	DocsStore.save_todos(tasks)
	_rebuild()


func _rebuild() -> void:
	for status in _columns:
		var column_tasks := tasks.filter(
			func(task: Dictionary) -> bool: return str(task.get("status", "")) == status
		)
		_columns[status].set_cards(column_tasks)


func _find_task(id: int) -> int:
	for i in tasks.size():
		if int(tasks[i].get("id", -1)) == id:
			return i
	return -1
