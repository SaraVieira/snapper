@tool
extends RefCounted
## Reads and writes everything the plugin stores, as plain markdown files
## inside the project's docs/ folder.
##
## Layout:
##   docs/todos.md            - the kanban board
##   docs/progress/DATE.md    - one daily progress entry per date (YYYY-MM-DD)
##   docs/wiki/**.md          - free-form wiki pages

const DOCS_DIR := "res://docs"
const TODOS_PATH := "res://docs/todos.md"
const PROGRESS_DIR := "res://docs/progress"
const WIKI_DIR := "res://docs/wiki"

const STATUSES := ["Todo", "In Progress", "Done"]
const URGENCIES := ["Low", "Medium", "High", "Critical"]


static func ensure_dirs() -> void:
	var root := DirAccess.open("res://")
	if root == null:
		return
	root.make_dir_recursive("docs/progress")
	root.make_dir_recursive("docs/wiki")


static func read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


static func write_file(path: String, content: String) -> bool:
	# Recreates docs/ if it was deleted while the editor is open.
	ensure_dirs()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var why := error_string(FileAccess.get_open_error())
		push_error("Project Wiki: could not write %s (%s)" % [path, why])
		return false
	file.store_string(content)
	return true


static func rescan_filesystem() -> void:
	# Makes new/deleted markdown files show up in the FileSystem dock.
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()


# --- Todos -------------------------------------------------------------------

static func load_todos() -> Array:
	ensure_dirs()
	if not FileAccess.file_exists(TODOS_PATH):
		return []
	return parse_todos(read_file(TODOS_PATH))


static func save_todos(tasks: Array) -> void:
	ensure_dirs()
	var existed := FileAccess.file_exists(TODOS_PATH)
	write_file(TODOS_PATH, serialize_todos(tasks))
	if not existed:
		rescan_filesystem()


## Parses todos.md into an array of task dictionaries:
## {title, status, category, urgency, description}
static func parse_todos(md: String) -> Array:
	var tasks: Array = []
	var status := "Todo"
	var pending: Dictionary = {}
	var desc := PackedStringArray()
	for line in md.replace("\r\n", "\n").split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("## "):
			_commit_task(tasks, pending, desc)
			pending = {}
			desc = PackedStringArray()
			status = _normalize_status(stripped.substr(3))
		elif stripped.begins_with("### "):
			_commit_task(tasks, pending, desc)
			desc = PackedStringArray()
			pending = {
				"title": stripped.substr(4).strip_edges(),
				"status": status,
				"category": "",
				"urgency": "Medium",
				"description": "",
			}
		elif pending.is_empty():
			continue
		elif stripped.begins_with("- Category:"):
			pending["category"] = stripped.substr(11).strip_edges()
		elif stripped.begins_with("- Urgency:"):
			pending["urgency"] = _normalize_urgency(stripped.substr(10).strip_edges())
		else:
			desc.append(line)
	_commit_task(tasks, pending, desc)
	return tasks


static func serialize_todos(tasks: Array) -> String:
	var out := "# Todos\n"
	for status in STATUSES:
		out += "\n## %s\n" % status
		for task in tasks:
			if str(task.get("status", "")) != status:
				continue
			out += "\n### %s\n" % str(task.get("title", "Untitled")).strip_edges()
			var category := str(task.get("category", "")).strip_edges()
			if category != "":
				out += "- Category: %s\n" % category
			out += "- Urgency: %s\n" % str(task.get("urgency", "Medium"))
			var description := str(task.get("description", "")).strip_edges()
			if description != "":
				out += "\n%s\n" % description
	return out


static func _commit_task(tasks: Array, pending: Dictionary, desc: PackedStringArray) -> void:
	if pending.is_empty():
		return
	pending["description"] = "\n".join(desc).strip_edges()
	tasks.append(pending)


static func _normalize_status(raw: String) -> String:
	match raw.strip_edges().to_lower():
		"todo", "to do", "backlog":
			return "Todo"
		"in progress", "in-progress", "doing":
			return "In Progress"
		"done", "complete", "completed":
			return "Done"
	return "Todo"


static func _normalize_urgency(raw: String) -> String:
	var lowered := raw.strip_edges().to_lower()
	for urgency in URGENCIES:
		if lowered == str(urgency).to_lower():
			return urgency
	return "Medium"


# --- Daily progress ----------------------------------------------------------

static func list_progress_dates() -> PackedStringArray:
	ensure_dirs()
	var out := PackedStringArray()
	var dir := DirAccess.open(PROGRESS_DIR)
	if dir == null:
		return out
	for file in dir.get_files():
		if file.get_extension() == "md":
			out.append(file.get_basename())
	out.sort()
	out.reverse()
	return out


static func progress_path(date: String) -> String:
	return PROGRESS_DIR + "/" + date + ".md"


# --- Wiki --------------------------------------------------------------------

static func list_wiki_files() -> PackedStringArray:
	ensure_dirs()
	var out := PackedStringArray()
	_scan_wiki_dir(WIKI_DIR, "", out)
	out.sort()
	return out


static func wiki_path(relative: String) -> String:
	return WIKI_DIR + "/" + relative


static func create_wiki_file(relative: String) -> bool:
	ensure_dirs()
	var base := relative.get_base_dir()
	if base != "":
		var root := DirAccess.open("res://")
		if root != null:
			root.make_dir_recursive("docs/wiki/" + base)
	var path := wiki_path(relative)
	if FileAccess.file_exists(path):
		return true
	var title := relative.get_file().get_basename().capitalize()
	var ok := write_file(path, "# %s\n" % title)
	if ok:
		rescan_filesystem()
	return ok


static func delete_wiki_file(relative: String) -> void:
	var dir := DirAccess.open(WIKI_DIR)
	if dir == null:
		return
	dir.remove(relative)
	rescan_filesystem()


static func _scan_wiki_dir(abs_dir: String, prefix: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(abs_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir():
			if not name.begins_with("."):
				_scan_wiki_dir(abs_dir + "/" + name, prefix + name + "/", out)
		elif name.get_extension() == "md":
			out.append(prefix + name)
		name = dir.get_next()
	dir.list_dir_end()
