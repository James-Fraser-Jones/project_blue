extends KinematicBody

var walk_speed = 1.8 #m/s
var run_speed = 6.7 #m/s
var gravity = -9.8
var mouse_sensitivity = 0.002  # radians/pixel
var velocity = Vector3()
var jump_impulse = 6

func _physics_process(delta):
	velocity.y += gravity * delta
	var desired_velocity = get_input() * run_speed
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity = move_and_slide(velocity, Vector3.UP, true)
	
func get_input():
	var input_dir = Vector3()
	if Input.is_action_pressed("move_forward"):
		input_dir += -$Camera.global_transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir += $Camera.global_transform.basis.z
	if Input.is_action_pressed("strafe_left"):
		input_dir += -$Camera.global_transform.basis.x
	if Input.is_action_pressed("strafe_right"):
		input_dir += $Camera.global_transform.basis.x
	input_dir = input_dir.normalized()
	return input_dir

func _input(event):
	if event.is_action_pressed("jump"):
		velocity.y = jump_impulse
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera.rotation.x = clamp($Camera.rotation.x, -1.2, 1.2)
