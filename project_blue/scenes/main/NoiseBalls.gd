tool
extends Node

#we can definitely handle 4000 objects so: (size*rez)^3 = 4000

#spawn parameters
export var size: Vector3 = Vector3.ONE*10
export(float, 1, 4) var res = 1 setget run_res
export var trans: Vector3 = Vector3.ZERO
export var spawn : bool setget run_spawn

#color parameters
export var seeed: int = 42 setget run_seed
export(float, EXP, 0.01, 10) var zoom = 0.1 setget run_zoom
export var origin: Vector3 = Vector3.ZERO
export var color : bool setget run_color

#threshold parameters
export(float, -1, 1) var thresh = 0 setget run_thresh
export var invert: bool = false setget run_invert
export var reset: bool setget run_reset

export var delete : bool setget run_delete

var scene = preload("res://scenes/ball/Ball.tscn") # Will load when parsing the script.
var noise = OpenSimplexNoise.new()
var res_vec: Vector3 = Vector3.ONE * res
var zoom_vec: Vector3 = Vector3.ONE * zoom

func run_res(r):
	res = r
	res_vec = Vector3.ONE * res

func run_spawn(k):
	spawn = false
	var ball_num: Vector3 = (size * res_vec + Vector3.ONE).floor()
	var diff = ball_num.x*ball_num.y*ball_num.z - get_child_count()
	if diff > 0:
		for i in range(0, diff):
			hire_child()
	elif diff < 0:
		for i in range(0, -diff):
			fire_child()
	var gap_num: Vector3 = Vector3.ONE / res_vec
	for z in range(0, ball_num.z):
		for y in range(0, ball_num.y):
			for x in range(0, ball_num.x):
				var index = x + y*ball_num.x + z*ball_num.y*ball_num.x
				var cur_child: Sprite3D = get_child(index)
				var pos = Vector3(x,y,z) * gap_num + trans
				cur_child.transform.origin = pos

func run_seed(s):
	seeed = s
	noise.seed = s
	run_reset(false)
	run_color(false)

func run_zoom(z):
	zoom = z
	zoom_vec = Vector3.ONE * zoom
	run_color(false)

func run_color(k):
	color = false
	var ball_num: Vector3 = (size * res_vec + Vector3.ONE).floor()
	for z in range(0, ball_num.z):
		for y in range(0, ball_num.y):
			for x in range(0, ball_num.x):
				var index = x + y*ball_num.x + z*ball_num.y*ball_num.x
				var cur_child: Sprite3D = get_child(index)
				var val = noise.get_noise_3dv(Vector3(x,y,z) / zoom_vec + origin) #-1 - 1
				cur_child.modulate = Color.from_hsv((val + 1)/2,1,1)
			
func run_thresh(s):
	thresh = s
	for child in get_children():
		if invert:
			child.modulate.a = 1 if (child.modulate.h * 2 - 1) > thresh else 0
		else:
			child.modulate.a = 1 if (child.modulate.h * 2 - 1) < thresh else 0
			
func run_invert(b):
	invert = b
	run_thresh(thresh)
	
func run_reset(b):
	for child in get_children():
		child.modulate.a = 1

func run_delete(k):
	delete = false
	while get_child_count() > 0:
		fire_child()

func hire_child():
	add_child(scene.instance())

func fire_child():
	var child = get_child(0)
	remove_child(child)
	child.queue_free()


