@tool
extends PanelContainer
## A single todo card. Click to edit, drag onto a column (or another card,
## to insert before it) to move.

const URGENCY_COLORS := {
	"Low": Color(0.45, 0.75, 0.5),
	"Medium": Color(0.85, 0.75, 0.35),
	"High": Color(0.95, 0.6, 0.3),
	"Critical": Color(0.9, 0.35, 0.35),
}

const CATEGORY_COLORS := [
	Color(0.55, 0.7, 0.95),
	Color(0.75, 0.6, 0.9),
	Color(0.5, 0.85, 0.8),
	Color(0.95, 0.7, 0.75),
	Color(0.7, 0.85, 0.55),
	Color(0.9, 0.65, 0.5),
	Color(0.6, 0.8, 0.9),
	Color(0.85, 0.8, 0.6),
]

var task: Dictionary = {}
var board = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Click to edit  ·  drag to move"

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.07)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var title := Label.new()
	title.text = str(task.get("title", ""))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var description := str(task.get("description", ""))
	if description != "":
		var preview := Label.new()
		preview.text = description.split("\n")[0]
		preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		preview.add_theme_font_size_override("font_size", 12)
		preview.modulate = Color(1, 1, 1, 0.55)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(preview)

	var tags := HBoxContainer.new()
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tags.add_theme_constant_override("separation", 4)
	vbox.add_child(tags)

	var category := str(task.get("category", "")).strip_edges()
	if category != "":
		tags.add_child(_make_tag(category, _category_color(category)))
	var urgency := str(task.get("urgency", "Medium"))
	tags.add_child(_make_tag(urgency, URGENCY_COLORS.get(urgency, Color(0.6, 0.6, 0.6))))


func _gui_input(event: InputEvent) -> void:
	# A release only reaches the card when no drag started, so a plain click
	# opens the editor while drags keep working.
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		accept_event()
		if board != null:
			board.open_edit_dialog(task)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(8)
	preview.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = str(task.get("title", ""))
	preview.add_child(label)
	set_drag_preview(preview)
	return {"type": "project_wiki_todo", "id": int(task.get("id", -1))}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary \
			and data.get("type") == "project_wiki_todo" \
			and int(data.get("id", -1)) != int(task.get("id", -1))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if board != null:
		board.move_task(int(data["id"]), str(task.get("status", "Todo")), int(task.get("id", -1)))


func _make_tag(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	label.add_theme_stylebox_override("normal", style)
	return label


func _category_color(category: String) -> Color:
	return CATEGORY_COLORS[abs(category.to_lower().hash()) % CATEGORY_COLORS.size()]
