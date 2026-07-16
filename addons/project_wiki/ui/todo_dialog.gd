@tool
extends ConfirmationDialog
## Dialog for creating and editing a todo. Emits `saved` with the task data
## (id 0 means a new task) and `delete_requested` with the task id.

signal saved(data: Dictionary)
signal delete_requested(id: int)

const DocsStore := preload("res://addons/project_wiki/docs_store.gd")

var _task_id := 0
var _title_edit: LineEdit
var _category_edit: LineEdit
var _category_menu: MenuButton
var _urgency_option: OptionButton
var _status_option: OptionButton
var _description_edit: TextEdit
var _delete_button: Button


func _init() -> void:
	title = "Todo"
	ok_button_text = "Save"
	min_size = Vector2i(480, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	vbox.add_child(_make_field_label("Title"))
	_title_edit = LineEdit.new()
	_title_edit.placeholder_text = "What needs doing?"
	vbox.add_child(_title_edit)
	register_text_enter(_title_edit)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var category_box := VBoxContainer.new()
	category_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_box.add_child(_make_field_label("Category"))
	var category_row := HBoxContainer.new()
	_category_edit = LineEdit.new()
	_category_edit.placeholder_text = "e.g. Code, Art, Audio"
	_category_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_row.add_child(_category_edit)
	_category_menu = MenuButton.new()
	_category_menu.text = "▾"
	_category_menu.get_popup().index_pressed.connect(_on_category_picked)
	category_row.add_child(_category_menu)
	category_box.add_child(category_row)
	row.add_child(category_box)

	var urgency_box := VBoxContainer.new()
	urgency_box.add_child(_make_field_label("Urgency"))
	_urgency_option = OptionButton.new()
	for urgency in DocsStore.URGENCIES:
		_urgency_option.add_item(urgency)
	urgency_box.add_child(_urgency_option)
	row.add_child(urgency_box)

	var status_box := VBoxContainer.new()
	status_box.add_child(_make_field_label("Status"))
	_status_option = OptionButton.new()
	for status in DocsStore.STATUSES:
		_status_option.add_item(status)
	status_box.add_child(_status_option)
	row.add_child(status_box)

	vbox.add_child(_make_field_label("Description"))
	_description_edit = TextEdit.new()
	_description_edit.custom_minimum_size = Vector2(440, 150)
	_description_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(_description_edit)

	_delete_button = add_button("Delete", true, "delete")

	confirmed.connect(_on_confirmed)
	custom_action.connect(_on_custom_action)


func open_new(status: String, categories: Array) -> void:
	_task_id = 0
	title = "New Todo"
	_delete_button.visible = false
	_title_edit.text = ""
	_category_edit.text = ""
	_urgency_option.selected = DocsStore.URGENCIES.find("Medium")
	_status_option.selected = maxi(0, DocsStore.STATUSES.find(status))
	_description_edit.text = ""
	_fill_category_menu(categories)
	popup_centered()
	_title_edit.call_deferred("grab_focus")


func open_edit(task: Dictionary, categories: Array) -> void:
	_task_id = int(task.get("id", 0))
	title = "Edit Todo"
	_delete_button.visible = true
	_title_edit.text = str(task.get("title", ""))
	_category_edit.text = str(task.get("category", ""))
	_urgency_option.selected = maxi(0, DocsStore.URGENCIES.find(str(task.get("urgency", "Medium"))))
	_status_option.selected = maxi(0, DocsStore.STATUSES.find(str(task.get("status", "Todo"))))
	_description_edit.text = str(task.get("description", ""))
	_fill_category_menu(categories)
	popup_centered()
	_title_edit.call_deferred("grab_focus")


func _on_confirmed() -> void:
	var task_title := _title_edit.text.strip_edges()
	if task_title == "":
		task_title = "Untitled"
	saved.emit({
		"id": _task_id,
		"title": task_title,
		"category": _category_edit.text.strip_edges(),
		"urgency": DocsStore.URGENCIES[_urgency_option.selected],
		"status": DocsStore.STATUSES[_status_option.selected],
		"description": _description_edit.text.strip_edges(),
	})


func _on_custom_action(action: StringName) -> void:
	if action == &"delete":
		hide()
		delete_requested.emit(_task_id)


func _on_category_picked(index: int) -> void:
	_category_edit.text = _category_menu.get_popup().get_item_text(index)


func _fill_category_menu(categories: Array) -> void:
	var popup := _category_menu.get_popup()
	popup.clear()
	for category in categories:
		popup.add_item(str(category))
	_category_menu.disabled = categories.is_empty()


func _make_field_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color(1, 1, 1, 0.6)
	return label
