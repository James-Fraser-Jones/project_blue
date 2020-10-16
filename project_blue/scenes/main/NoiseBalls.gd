tool
extends Node

#export(NodePath) var proc_chunk_path

#spawn parameters
export var size: Vector3 = Vector3.ONE*10
export(float, 1, 4) var res = 1 setget run_res
export var trans: Vector3 = Vector3.ZERO setget run_trans

#noise parameters
export var seeed: int = 42 setget run_seed
export(float, 0.01, 1.5) var zoom = 0.3 setget run_zoom
export var origin: Vector3 = Vector3.ZERO setget run_origin

#circle hiding paramters
export var cull: bool = true setget run_cull
export(float, -1, 1) var thresh = 0 setget run_thresh
export var invert: bool = false setget run_invert

#commands
export var spawn : bool setget run_spawn
export var delete : bool setget run_delete
#export var mesh: bool setget run_mesh

#global variables
var ball = preload("res://scenes/ball/Ball.tscn")
var noise = OpenSimplexNoise.new()
var res_vec: Vector3 = Vector3.ONE * res
var zoom_vec: Vector3 = Vector3.ONE * zoom
var ball_num: Vector3 = Vector3.ZERO
var corners: Array

func _ready():
	run_seed(seeed)

#utility functions
func hire_child():
	add_child(ball.instance())

func fire_child():
	var child = get_child(0)
	remove_child(child)
	child.queue_free()

#heavy lifting functions
func move_dots():
	var gap_num: Vector3 = Vector3.ONE / res_vec
	var child_count: int = get_child_count()
	for z in range(0, ball_num.z):
		for y in range(0, ball_num.y):
			for x in range(0, ball_num.x):
				var index = x + y*ball_num.x + z*ball_num.y*ball_num.x
				if index < child_count:
					var cur_child: Sprite3D = get_child(index)
					var pos = Vector3(x,y,z) * gap_num + trans
					cur_child.transform.origin = pos

func get_color():
	var ball_num: Vector3 = (size * res_vec + Vector3.ONE).floor()
	var child_count: int = get_child_count()
	corners = []
	for z in range(0, ball_num.z):
		var corner_square: Array = []
		for y in range(0, ball_num.y):
			var corner_row: Array = []
			for x in range(0, ball_num.x):
				var index = x + y*ball_num.x + z*ball_num.y*ball_num.x
				if index < child_count:
					var cur_child: Sprite3D = get_child(index)
					var val = clamp(noise.get_noise_3dv((Vector3(x,y,z) + origin) / zoom_vec) + thresh, -1, 1) #-1 - 1
					cur_child.modulate = Color.from_hsv((val + 1)/4,1,1)
					if cull:
						if invert:
							cur_child.modulate.a = 1 if (cur_child.modulate.h * 4 - 1) > 0 else 0
						else:
							cur_child.modulate.a = 1 if (cur_child.modulate.h * 4 - 1) < 0 else 0
					corner_row.append(val)
			corner_square.append(corner_row)
		corners.append(corner_square)

#setters
func run_res(r):
	res = r
	res_vec = Vector3.ONE * res

func run_trans(t):
	trans = t
	move_dots()

func run_seed(s):
	seeed = s
	noise.seed = s
	get_color()

func run_zoom(z):
	zoom = z
	zoom_vec = Vector3.ONE * zoom
	get_color()
	
func run_origin(o):
	origin = o
	get_color()

func run_cull(c):
	cull = c
	get_color()
	
func run_thresh(s):
	thresh = s
	get_color()
			
func run_invert(b):
	invert = b
	get_color()

#command setters
func run_spawn(k):
	ball_num = (size * res_vec + Vector3.ONE).floor()
	var diff = ball_num.x*ball_num.y*ball_num.z - get_child_count()
	if diff > 0:
		for i in range(0, diff):
			hire_child()
	elif diff < 0:
		for i in range(0, -diff):
			fire_child()
	move_dots()
	get_color()

func run_delete(k):
	while get_child_count() > 0:
		fire_child()

#func run_mesh(m):
#	if !proc_chunk_path.is_empty():
#		var proc_chunk: Node = get_node(proc_chunk_path)
#		proc_chunk.big_mesh(corners)
