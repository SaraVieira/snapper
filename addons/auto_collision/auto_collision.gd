@tool
extends EditorPlugin

const TileProcessing = preload("./TileProcessing.gd")

const BATCH_SIZE = 32

var _tile_processing
var _settings_dialog: ConfirmationDialog
var _progress_dialog: AcceptDialog
var _progress_bar: ProgressBar
var _progress_label: Label
var _current_tile_set: TileSet
var _current_settings = {}
var _generation_result = {}

func _enter_tree():
	if Engine.is_editor_hint():
		var command_palette = EditorInterface.get_command_palette()
		var command_callable = Callable(self, "_auto_collision")
		command_palette.add_command("Generate Tile Collisions", "auto_collision/auto_collision", command_callable)
		add_tool_menu_item("Generate Tile Collisions", command_callable)

func _exit_tree():
	if Engine.is_editor_hint():
		remove_tool_menu_item("Generate Tile Collisions")
		if _tile_processing != null:
			_tile_processing.stop()

func _auto_collision():
	var tileset_path = EditorInterface.get_current_path()
	var tile_set = load(tileset_path)
	if tile_set is TileSet:
		var physics_layers_count = tile_set.get_physics_layers_count()
		if physics_layers_count == 0:
			var confirmation_dialog = ConfirmationDialog.new()
			confirmation_dialog.title = "Create physics layer?"
			confirmation_dialog.ok_button_text = "Yes"
			confirmation_dialog.cancel_button_text = "No"
			confirmation_dialog.dialog_text = "The TileSet has no physics layer (for collision). Should one be created?"
			confirmation_dialog.confirmed.connect(_create_physics_layer_and_continue.bind(tile_set))
			EditorInterface.popup_dialog_centered(confirmation_dialog)
		else:
			_show_generate_dialog(tile_set)
	else:
		printerr("Resource \"" + tileset_path + "\" is not a TileSet.")

func _create_physics_layer_and_continue(tile_set: TileSet):
	_create_physics_layer(tile_set)
	_show_generate_dialog(tile_set)

func _create_physics_layer(tile_set: TileSet):
	tile_set.add_physics_layer(0)

func _show_generate_dialog(tile_set: TileSet):
	_settings_dialog = ConfirmationDialog.new()
	_settings_dialog.title = "Generate Tile Collisions"
	_settings_dialog.ok_button_text = "Generate"
	_settings_dialog.cancel_button_text = "Cancel"

	var root = VBoxContainer.new()
	root.custom_minimum_size = Vector2(360, 0)
	_settings_dialog.add_child(root)

	var straight_line_for_diagonals_check_box = CheckBox.new()
	straight_line_for_diagonals_check_box.text = "Straight line for diagonals"
	straight_line_for_diagonals_check_box.tooltip_text = "Apply the straight line for diagonals optimization."
	straight_line_for_diagonals_check_box.button_pressed = true
	root.add_child(straight_line_for_diagonals_check_box)

	var overwrite_check_box = CheckBox.new()
	overwrite_check_box.text = "Overwrite existing collisions"
	overwrite_check_box.tooltip_text = "Replace collision polygons on tiles that already have them."
	overwrite_check_box.button_pressed = false
	root.add_child(overwrite_check_box)

	var alpha_row = HBoxContainer.new()
	root.add_child(alpha_row)

	var alpha_label = Label.new()
	alpha_label.text = "Alpha threshold"
	alpha_label.tooltip_text = "Pixels with alpha at or above this value are treated as solid."
	alpha_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alpha_row.add_child(alpha_label)

	var alpha_threshold_spin_box = SpinBox.new()
	alpha_threshold_spin_box.tooltip_text = alpha_label.tooltip_text
	alpha_threshold_spin_box.min_value = 0.0
	alpha_threshold_spin_box.max_value = 1.0
	alpha_threshold_spin_box.step = 0.05
	alpha_threshold_spin_box.value = 0.4
	alpha_threshold_spin_box.custom_minimum_size = Vector2(96, 0)
	alpha_row.add_child(alpha_threshold_spin_box)

	_settings_dialog.confirmed.connect(func():
		_start_auto_collision_generation(tile_set, {
			alpha_threshold = alpha_threshold_spin_box.value,
			overwrite = overwrite_check_box.button_pressed,
			straight_line_for_diagonals = straight_line_for_diagonals_check_box.button_pressed
		})
	)

	EditorInterface.popup_dialog_centered(_settings_dialog)

func _start_auto_collision_generation(tile_set: TileSet, settings: Dictionary):
	_current_tile_set = tile_set
	_current_settings = settings
	_generation_result = {
		changed = 0,
		generated_points = 0,
		processed = 0,
		skipped = 0,
		total = _count_tiles(tile_set)
	}

	_show_progress_dialog()
	print(
		"Generating collision for " + str(_generation_result.total) + " tiles" +
		"; straight line for diagonals " + ("enabled" if settings.straight_line_for_diagonals else "disabled") +
		"; overwrite " + ("enabled" if settings.overwrite else "disabled") + "."
	)
	_process_generation.call_deferred()

func _count_tiles(tile_set: TileSet) -> int:
	var total = 0
	for index in tile_set.get_source_count():
		var source_id = tile_set.get_source_id(index)
		var tile_set_source = tile_set.get_source(source_id)
		if tile_set_source is TileSetAtlasSource:
			total += tile_set_source.get_tiles_count()
	return total

func _show_progress_dialog():
	_progress_dialog = AcceptDialog.new()
	_progress_dialog.title = "Generating Tile Collisions"
	_progress_dialog.get_ok_button().hide()
	_progress_dialog.close_requested.connect(func(): pass)

	var root = VBoxContainer.new()
	root.custom_minimum_size = Vector2(360, 0)
	_progress_dialog.add_child(root)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = max(_generation_result.total, 1)
	_progress_bar.value = 0
	root.add_child(_progress_bar)

	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_progress_label)

	_update_progress_dialog()
	EditorInterface.popup_dialog_centered(_progress_dialog)

func _process_generation():
	if _tile_processing == null:
		_tile_processing = TileProcessing.new()

	var batch_processed = 0
	for source_index in _current_tile_set.get_source_count():
		var source_id = _current_tile_set.get_source_id(source_index)
		var tile_set_source = _current_tile_set.get_source(source_id)
		if not tile_set_source is TileSetAtlasSource:
			continue

		var image = tile_set_source.texture.get_image()
		for tile_index in tile_set_source.get_tiles_count():
			var tile_id = tile_set_source.get_tile_id(tile_index)
			if tile_set_source.has_tile(tile_id):
				var tile_result = _tile_processing.process_tile(
					tile_set_source,
					tile_id,
					image,
					_current_settings
				)
				_generation_result.changed += 1 if tile_result.changed else 0
				_generation_result.generated_points += tile_result.generated_points
				_generation_result.skipped += 1 if tile_result.skipped else 0
			_generation_result.processed += 1
			batch_processed += 1

			if batch_processed >= BATCH_SIZE:
				_update_progress_dialog()
				await get_tree().process_frame
				batch_processed = 0

	_update_progress_dialog()
	_finish_generation()

func _update_progress_dialog():
	if _progress_bar != null:
		_progress_bar.value = _generation_result.processed
	if _progress_label != null:
		_progress_label.text = str(_generation_result.processed) + " / " + str(_generation_result.total) + " tiles"

func _finish_generation():
	if _current_tile_set != null:
		ResourceSaver.save(_current_tile_set)
	print(
		"Generated collision for " + str(_generation_result.changed) + "/" + str(_generation_result.total) + " tiles" +
		("; skipped " + str(_generation_result.skipped) + " existing collision tiles" if _generation_result.skipped else "") +
		"; " + str(_generation_result.generated_points) + " generated polygon points" +
		"; straight line for diagonals " + ("enabled" if _current_settings.straight_line_for_diagonals else "disabled") +
		"; overwrite " + ("enabled" if _current_settings.overwrite else "disabled") + "."
	)
	if _progress_dialog != null:
		_progress_dialog.hide()
		_progress_dialog.queue_free()
