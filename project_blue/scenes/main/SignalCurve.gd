extends Curve

func add_point(position: Vector2, left_tangent: float = 0, right_tangent: float = 0, left_mode: int = 0, right_mode: int = 0) -> int:
	print("Heck Yeah Boi")
	return .add_point(position, left_tangent, right_tangent, left_mode, right_mode)

func set_point_offset(index: int, offset: float) -> int:
	print("Hokey Bokey!")
	return .set_point_offset(index, offset)

func set_point_value(index: int, y: float) -> void:
	print("Hokey Cokey!")
	.set_point_value(index, y)

func set_point_left_tangent(index: int, tangent: float) -> void:
	print("hey now you rockstar")
	.set_point_left_tangent(index, tangent)
