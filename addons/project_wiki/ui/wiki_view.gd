@tool
extends HSplitContainer
## Free-form markdown wiki stored in docs/wiki/. Pages can live in subfolders
## ("design/combat.md"). Edits auto-save a second after you stop typing, and
## a Preview toggle renders the markdown.

const DocsStore := preload("res://addons/project_wiki/docs_store.gd")
const Markdown := preload("res://addons/project_wiki/markdown.gd")

var _files: ItemList
var _editor: TextEdit
var _preview: RichTextLabel
var _path_label: Label
var _preview_button: Button
var _delete_button: Button
var _save_timer: Timer
var _new_dialog: ConfirmationDialog
var _new_name_edit: LineEdit
var _delete_dialog: ConfirmationDialog
var _current := ""
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

	var left_toolbar := HBoxContainer.new()
	left.add_child(left_toolbar)

	var new_button := Button.new()
	new_button.text = "+ New Page"
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(_on_new_pressed)
	left_toolbar.add_child(new_button)

	_delete_button = Button.new()
	_delete_button.text = "Delete"
	_delete_button.disabled = true
	_delete_button.pressed.connect(_on_delete_pressed)
	left_toolbar.add_child(_delete_button)

	_files = ItemList.new()
	_files.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_files.item_selected.connect(_on_file_selected)
	left.add_child(_files)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	add_child(right)

	var header := HBoxContainer.new()
	right.add_child(header)

	_path_label = Label.new()
	_path_label.text = "Select or create a page"
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_path_label)

	_preview_button = Button.new()
	_preview_button.text = "Preview"
	_preview_button.toggle_mode = true
	_preview_button.toggled.connect(_on_preview_toggled)
	header.add_child(_preview_button)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(_save_current)
	header.add_child(save_button)

	_editor = TextEdit.new()
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.placeholder_text = "Write anything about your game in markdown"
	_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_editor.editable = false
	_editor.text_changed.connect(_on_text_changed)
	right.add_child(_editor)

	_preview = RichTextLabel.new()
	_preview.bbcode_enabled = true
	_preview.selection_enabled = true
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview.visible = false
	_preview.meta_clicked.connect(func(meta: Variant) -> void: OS.shell_open(str(meta)))
	right.add_child(_preview)

	_save_timer = Timer.new()
	_save_timer.wait_time = 1.0
	_save_timer.one_shot = true
	_save_timer.timeout.connect(_save_current)
	add_child(_save_timer)

	_new_dialog = ConfirmationDialog.new()
	_new_dialog.title = "New Wiki Page"
	_new_dialog.ok_button_text = "Create"
	var new_box := VBoxContainer.new()
	var new_hint := Label.new()
	new_hint.text = "Page name (subfolders allowed, e.g. design/combat):"
	new_box.add_child(new_hint)
	_new_name_edit = LineEdit.new()
	_new_name_edit.placeholder_text = "my-page"
	_new_name_edit.custom_minimum_size.x = 320
	new_box.add_child(_new_name_edit)
	_new_dialog.add_child(new_box)
	_new_dialog.register_text_enter(_new_name_edit)
	_new_dialog.confirmed.connect(_on_new_confirmed)
	add_child(_new_dialog)

	_delete_dialog = ConfirmationDialog.new()
	_delete_dialog.title = "Delete Page"
	_delete_dialog.ok_button_text = "Delete"
	_delete_dialog.confirmed.connect(_on_delete_confirmed)
	add_child(_delete_dialog)

	visibility_changed.connect(func() -> void:
		if not visible:
			_save_current()
	)

	refresh()


func refresh() -> void:
	_save_current()
	var previous := _current
	_files.clear()
	var files := DocsStore.list_wiki_files()
	for file in files:
		_files.add_item(file)
	var index := files.find(previous)
	if index != -1:
		_files.select(index)
		_load_file(previous)
	else:
		_current = ""
		_loading = true
		_editor.text = ""
		_loading = false
		_editor.editable = false
		_delete_button.disabled = true
		_preview.text = ""
		_path_label.text = "Select or create a page"


func _on_new_pressed() -> void:
	_new_name_edit.text = ""
	_new_dialog.popup_centered()
	_new_name_edit.call_deferred("grab_focus")


func _on_new_confirmed() -> void:
	var page_name := _new_name_edit.text.strip_edges().replace("\\", "/")
	if page_name == "" or page_name.begins_with("/") or page_name.ends_with("/") \
			or page_name.contains(".."):
		return
	if not page_name.ends_with(".md"):
		page_name += ".md"
	_save_current()
	if DocsStore.create_wiki_file(page_name):
		_current = page_name
		refresh()
		_editor.grab_focus()


func _on_delete_pressed() -> void:
	if _current == "":
		return
	_delete_dialog.dialog_text = "Delete \"%s\"?\nThis cannot be undone." % _current
	_delete_dialog.popup_centered()


func _on_delete_confirmed() -> void:
	if _current == "":
		return
	_save_timer.stop()
	DocsStore.delete_wiki_file(_current)
	_current = ""
	refresh()


func _on_file_selected(index: int) -> void:
	_save_current()
	_load_file(_files.get_item_text(index))


func _on_text_changed() -> void:
	if _loading or _current == "":
		return
	_dirty = true
	_save_timer.start()


func _on_preview_toggled(pressed: bool) -> void:
	if pressed:
		_preview.text = Markdown.to_bbcode(_editor.text)
	_preview.visible = pressed
	_editor.visible = not pressed


func _load_file(relative: String) -> void:
	_current = relative
	_loading = true
	_editor.text = DocsStore.read_file(DocsStore.wiki_path(relative))
	_loading = false
	_dirty = false
	_editor.editable = true
	_delete_button.disabled = false
	_path_label.text = "docs/wiki/" + relative
	if _preview_button.button_pressed:
		_preview.text = Markdown.to_bbcode(_editor.text)


func _save_current() -> void:
	if _current == "" or not _dirty:
		return
	_save_timer.stop()
	if DocsStore.write_file(DocsStore.wiki_path(_current), _editor.text):
		_dirty = false
