const LinesToPolygonsConverter = preload ("./LinesToPolygonsConverter.gd")

var _task_queue = []
var _mutex: Mutex
var _threads = []

func start():
	if len(_threads) == 0:
		_mutex = Mutex.new()
		var processor_count = OS.get_processor_count()
		var number_of_threads = max(1, processor_count - 4)
		for i in range(number_of_threads):
			var thread = Thread.new()
			var semaphore = Semaphore.new()
			var data = {
				semaphore = semaphore,
				exit = false
			}
			_threads.append({
				thread = thread,
				data = data
			})
			thread.start(_thread_main.bind(data), Thread.PRIORITY_LOW)

func stop():
	for thread in _threads:
		thread.data.exit = true
		thread.data.semaphore.post()

	for thread in _threads:
		thread.thread.wait_to_finish()

func queue_task(task):
	_mutex.lock()
	_task_queue.push_back(task)
	_mutex.unlock()
	for thread in _threads:
		thread.data.semaphore.post()

func _thread_main(data):
	while true:
		data.semaphore.wait()

		if data.exit:
			break

		_mutex.lock()
		var task = _task_queue.pop_front()
		_mutex.unlock()

		if task != null:
			var tile_id = task.tile_id
			var image = task.image
			var tile_set_source = task.tile_set_source

			var tile_data = tile_set_source.get_tile_data(tile_id, 0)
			if tile_data.get_collision_polygons_count(0) == 0:
				var tile_texture_region = tile_set_source.get_tile_texture_region(tile_id, 0)
				var tile_image = image.get_region(tile_texture_region)
				var polygons = _find_polygons(tile_image, {
					alpha_threshold = 0.4,
					straight_line_for_diagonals = true
				})
				for polygon_index in range(len(polygons)):
					var polygon = polygons[polygon_index]
					var polygon2 = polygon.map(func(point): return Vector2(point[0] - 0.5 * tile_texture_region.size[0], point[1] - 0.5 * tile_texture_region.size[1]))
					tile_data.call_deferred("add_collision_polygon", 0)
					tile_data.call_deferred("set_collision_polygon_points", 0, polygon_index, PackedVector2Array(polygon2))

func process_tile(tile_set_source: TileSetAtlasSource, tile_id: Vector2i, image: Image, settings: Dictionary) -> Dictionary:
	var tile_data = tile_set_source.get_tile_data(tile_id, 0)
	var existing_collision_polygons_count = tile_data.get_collision_polygons_count(0)
	if existing_collision_polygons_count > 0 and not settings.overwrite:
		return {
			changed = false,
			generated_points = 0,
			skipped = true
		}

	var tile_texture_region = tile_set_source.get_tile_texture_region(tile_id, 0)
	var tile_image = image.get_region(tile_texture_region)
	var polygons = _find_polygons(tile_image, settings)

	if existing_collision_polygons_count > 0:
		for polygon_index in range(existing_collision_polygons_count - 1, -1, -1):
			tile_data.remove_collision_polygon(0, polygon_index)

	if polygons.is_empty():
		return {
			changed = existing_collision_polygons_count > 0,
			generated_points = 0,
			skipped = false
		}

	var generated_points = 0
	for polygon_index in range(len(polygons)):
		var polygon = polygons[polygon_index]
		generated_points += len(polygon)
		var polygon_points = polygon.map(func(point): return Vector2(point[0] - 0.5 * tile_texture_region.size[0], point[1] - 0.5 * tile_texture_region.size[1]))
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, polygon_index, PackedVector2Array(polygon_points))

	return {
		changed = true,
		generated_points = generated_points,
		skipped = false
	}

func _find_polygons(image: Image, settings: Dictionary):
	var pixels = Array()
	pixels.resize(image.get_height())
	for index in range(len(pixels)):
		var row = Array()
		row.resize(image.get_width())
		pixels[index] = row

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			pixels[y][x] = pixel.a >= settings.alpha_threshold

	var pixel_types = Array()
	pixel_types.resize(image.get_height())
	for index in range(len(pixel_types)):
		var row = Array()
		row.resize(image.get_width())
		pixel_types[index] = row

	for row_index in range(len(pixels)):
		for column_index in range(len(pixels[0])):
			if pixels[row_index][column_index]:
				var type = 0
				if row_index >= 1:
					if pixels[row_index - 1][column_index]:
						type |= (1 << 3)
				if column_index <= image.get_width() - 2:
					if pixels[row_index][column_index + 1]:
						type |= (1 << 2)
				if row_index <= image.get_height() - 2:
					if pixels[row_index + 1][column_index]:
						type |= (1 << 1)
				if column_index >= 1:
					if pixels[row_index][column_index - 1]:
						type |= (1 << 0)

				pixel_types[row_index][column_index] = type

	var all_lines = []
	for row_index in range(len(pixel_types)):
		for column_index in range(len(pixel_types[0])):
			if pixels[row_index][column_index]:
				var type = pixel_types[row_index][column_index]
				var lines
				if type == 0b0000:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b0001:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)]
					]
				elif type == 0b0010:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b0011:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)]
					]
				elif type == 0b0100:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b0101:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
					]
				elif type == 0b0110:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b0111:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)]
					]
				elif type == 0b1000:
					lines = [
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b1001:
					lines = [
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)]
					]
				elif type == 0b1010:
					lines = [
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b1011:
					lines = [
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)]
					]
				elif type == 0b1100:
					lines = [
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b1101:
					lines = [
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)]
					]
				elif type == 0b1110:
					lines = [
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b1111:
					lines = []
				all_lines.append_array(lines)

	var lines_to_polygons_converter = LinesToPolygonsConverter.new()
	var polygons = lines_to_polygons_converter.convert(all_lines)
	polygons = _optimize_polygons(polygons, settings.straight_line_for_diagonals)

	return polygons

func _optimize_polygons(polygons, straight_line_for_diagonals: bool):
	var optimized = polygons.map(Callable(self, "_optimize_polygon"))
	if straight_line_for_diagonals:
		optimized = optimized.map(Callable(self, "_simplify_straight_line_for_diagonals_polygon"))
	return optimized.filter(func(polygon): return len(polygon) >= 3)

func _optimize_polygon(polygon):
	var optimized = polygon.duplicate()
	var index = 0

	while index < len(optimized) and len(optimized) >= 3:
		var p1 = optimized[index]
		var p2 = optimized[(index + 1) % len(optimized)]
		var p3 = optimized[(index + 2) % len(optimized)]
		if _is_collinear(p1, p2, p3):
			optimized.remove_at((index + 1) % len(optimized))
			if index >= len(optimized):
				index = 0
		else:
			index += 1

	return optimized

func _is_collinear(a, b, c) -> bool:
	return (b[0] - a[0]) * (c[1] - b[1]) == (b[1] - a[1]) * (c[0] - b[0])

func _simplify_straight_line_for_diagonals_polygon(polygon):
	if len(polygon) <= 4:
		return polygon

	var simplified = []
	var index = 0

	while index < len(polygon):
		var diagonal_run_length = _find_diagonal_run_length(polygon, index, 1.0)
		simplified.append(polygon[index])
		if diagonal_run_length > 0:
			index += diagonal_run_length
		else:
			index += 1

	return _remove_adjacent_duplicates(simplified)

func _find_diagonal_run_length(polygon, start_index: int, epsilon: float) -> int:
	var min_diagonal_run_segments = 4
	var max_diagonal_step_segment_length = 2
	var horizontal_direction = 0
	var vertical_direction = 0
	var previous_orientation = ""
	var length = 0
	var best_length = 0

	while start_index + length + 1 < len(polygon):
		var current = polygon[start_index + length]
		var next = polygon[start_index + length + 1]
		var dx = next[0] - current[0]
		var dy = next[1] - current[1]
		var orientation = "horizontal" if dx != 0 else "vertical"
		var segment_length = abs(dx) + abs(dy)

		if dx != 0 and dy != 0:
			break
		if segment_length == 0 or segment_length > max_diagonal_step_segment_length or orientation == previous_orientation:
			break

		if orientation == "horizontal":
			if horizontal_direction != 0 and horizontal_direction != dx:
				break
			horizontal_direction = dx
		else:
			if vertical_direction != 0 and vertical_direction != dy:
				break
			vertical_direction = dy

		length += 1
		previous_orientation = orientation

		if (
			length >= min_diagonal_run_segments and
			horizontal_direction != 0 and
			vertical_direction != 0 and
			_is_within_diagonal_tolerance(polygon, start_index, length, epsilon)
		):
			best_length = length

	return best_length

func _is_within_diagonal_tolerance(polygon, start_index: int, length: int, epsilon: float) -> bool:
	var start = polygon[start_index]
	var end = polygon[start_index + length]
	var epsilon_squared = epsilon * epsilon

	for index in range(start_index + 1, start_index + length):
		if _point_to_segment_distance_squared(polygon[index], start, end) > epsilon_squared:
			return false

	return true

func _point_to_segment_distance_squared(point, line_start, line_end) -> float:
	var length_squared = _point_distance_squared(line_start, line_end)
	if length_squared == 0:
		return _point_distance_squared(point, line_start)

	var projected = (
		(point[0] - line_start[0]) * (line_end[0] - line_start[0]) +
		(point[1] - line_start[1]) * (line_end[1] - line_start[1])
	) / length_squared
	var clamped = clamp(projected, 0.0, 1.0)
	var closest = Vector2(
		line_start[0] + clamped * (line_end[0] - line_start[0]),
		line_start[1] + clamped * (line_end[1] - line_start[1])
	)

	return _point_distance_squared(point, closest)

func _point_distance_squared(a, b) -> float:
	return pow(a[0] - b[0], 2) + pow(a[1] - b[1], 2)

func _remove_adjacent_duplicates(polygon):
	var deduplicated = []
	for index in range(len(polygon)):
		if polygon[index] != polygon[(index + len(polygon) - 1) % len(polygon)]:
			deduplicated.append(polygon[index])
	return [] if len(deduplicated) == 1 else deduplicated
