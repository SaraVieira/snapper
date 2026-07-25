class_name CatData
extends Resource


@export_group("Identity")

@export var id: StringName = &""
@export var display_name: String = "Cat"


@export_group("Art")
@export var overworld_frames: SpriteFrames
@export var battle_portrait: SpriteFrames

@export_group("Trust")

@export_range(0, 100) var starting_trust: int = 0
@export_range(10, 100) var trust_to_photo: int = 60
@export_range(-100, 0) var flee_threshold: int = -20


@export_group("Temperament")

@export_range(0.0, 1.0) var skittish: float = 0.5
@export_range(0.0, 1.0) var food_drive: float = 0.5
@export_range(0.0, 1.0) var curiosity: float = 0.5
@export_range(0.0, 1.0) var touch_tolerance: float = 0.5


@export_group("Quirks")

@export_enum("pet", "hand", "treats", "sound", "sit") var favourite: String = "treats"

@export_enum("pet", "hand", "treats", "sound", "sit") var hates: String = "sound"

@export var nocturnal: bool = false


func gain_for(action: String) -> int:
	var base := 0.0
	match action:
		"pet":
			base = 8.0 + 14.0 * touch_tolerance
		"hand":
			base = 6.0 + 10.0 * curiosity
		"treats":
			base = 5.0 + 18.0 * food_drive
		"sound":
			base = 4.0 + 12.0 * curiosity
		"sit":
			base = 3.0 + 9.0 * skittish
	if action == favourite:
		base *= 2.0
	return int(round(base))


func penalty_for(action: String) -> int:
	if action == "sit":
		return 0
	var base := 4.0 + 12.0 * skittish
	if action == "pet":
		base *= 1.5  # touching a cat that isn't ready is the worst outcome
	return int(round(-base))

func hated_penalty() -> int:
	return int(round(-(6.0 + 10.0 * skittish)))


func is_available(action: String, current_trust: int) -> bool:
	match action:
		"photo":
			return current_trust >= trust_to_photo
		"pet":
			return current_trust >= int(40.0 * skittish)
		_:
			return true
