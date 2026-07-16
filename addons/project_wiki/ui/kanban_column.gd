@tool
extends VBoxContainer
## One status column of the kanban board. Acts as the drop target for cards
## dragged onto empty column space (appends to the end of the column).

const KanbanCard := preload("res://addons/project_wiki/ui/kanban_card.gd")

var status := "Todo"
var board = null

var _header: Label
var _cards_box: VBoxContainer


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)

	_header = Label.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.modulate = Color(1, 1, 1, 0.7)
	inner.add_child(_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.add_child(scroll)

	_cards_box = VBoxContainer.new()
	_cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_cards_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_cards_box)

	var add_button := Button.new()
	add_button.text = "+ Add"
	add_button.flat = true
	add_button.pressed.connect(func() -> void:
		if board != null:
			board.open_new_dialog(status)
	)
	inner.add_child(add_button)

	_update_header(0)


func set_cards(column_tasks: Array) -> void:
	for child in _cards_box.get_children():
		child.queue_free()
	for task in column_tasks:
		var card := KanbanCard.new()
		card.task = task
		card.board = board
		_cards_box.add_child(card)
	_update_header(column_tasks.size())


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == "project_wiki_todo"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if board != null:
		board.move_task(int(data["id"]), status, -1)


func _update_header(count: int) -> void:
	_header.text = "%s  ·  %d" % [status.to_upper(), count]
