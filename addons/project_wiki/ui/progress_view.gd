@tool
extends HSplitContainer
## Daily progress log. One markdown file per day in docs/progress/,
## named YYYY-MM-DD.md. Entries auto-save a second after you stop typing.

const DocsStore := preload("res://addons/project_wiki/docs_store.gd")

const WEEKDAYS := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const MONTHS := ["January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"]

var _dates: ItemList
var _editor: TextEdit
var _date_label: Label
var _save_timer: Timer
var _current_date := ""
var _loading := false
var _dirty := false


func _exit_tree() -> void:
	# Covers disabling the plugin or quitting the editor mid-debounce.
	_save_current()


func _ready() -> void:
	split_offset = 240

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 200
	left.add_theme_constant_override("separation", 6)
	add_child(left)

	var add_button := Button.new()
	add_button.text = "+ Add Today's Progress"
	add_button.pressed.connect(_on_add_today)
	left.add_child(add_button)

	_dates = ItemList.new()
	_dates.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dates.item_selected.connect(_on_date_selected)
	left.add_child(_dates)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	add_child(right)

	var header := HBoxContainer.new()
	right.add_child(header)

	_date_label = Label.new()
	_date_label.text = "Select a day, or add today's progress"
	_date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_date_label)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(_save_current)
	header.add_child(save_button)

	_editor = TextEdit.new()
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.placeholder_text = "What did you get done today?"
	_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_editor.editable = false
	_editor.text_changed.connect(_on_text_changed)
	right.add_child(_editor)

	_save_timer = Timer.new()
	_save_timer.wait_time = 1.0
	_save_timer.one_shot = true
	_save_timer.timeout.connect(_save_current)
	add_child(_save_timer)

	visibility_changed.connect(func() -> void:
		if not visible:
			_save_current()
	)

	refresh()


func refresh() -> void:
	_save_current()
	var previous := _current_date
	_dates.clear()
	var dates := DocsStore.list_progress_dates()
	for date in dates:
		_dates.add_item(date)
	var index := dates.find(previous)
	if index != -1:
		_dates.select(index)
		_load_date(previous)
	else:
		_current_date = ""
		_loading = true
		_editor.text = ""
		_loading = false
		_editor.editable = false
		_date_label.text = "Select a day, or add today's progress"


func _on_add_today() -> void:
	_save_current()
	var today := Time.get_date_string_from_system()
	var path := DocsStore.progress_path(today)
	if not FileAccess.file_exists(path):
		DocsStore.write_file(path, "")
		DocsStore.rescan_filesystem()
	_current_date = today
	refresh()
	_editor.grab_focus()


func _on_date_selected(index: int) -> void:
	_save_current()
	_load_date(_dates.get_item_text(index))


func _on_text_changed() -> void:
	if _loading or _current_date == "":
		return
	_dirty = true
	_save_timer.start()


func _load_date(date: String) -> void:
	_current_date = date
	_loading = true
	_editor.text = DocsStore.read_file(DocsStore.progress_path(date))
	_loading = false
	_dirty = false
	_editor.editable = true
	_date_label.text = _pretty_date(date)


func _save_current() -> void:
	if _current_date == "" or not _dirty:
		return
	_save_timer.stop()
	if DocsStore.write_file(DocsStore.progress_path(_current_date), _editor.text):
		_dirty = false


func _pretty_date(date: String) -> String:
	var dict := Time.get_datetime_dict_from_datetime_string(date, true)
	if not (dict.has("weekday") and dict.has("day") and dict.has("month") and dict.has("year")):
		return date
	return "%s, %d %s %d" % [
		WEEKDAYS[int(dict["weekday"])],
		int(dict["day"]),
		MONTHS[int(dict["month"]) - 1],
		int(dict["year"]),
	]
