tool
extends Node

export var noise_layers: Array = []
export var height_layers: Array = []
export var width_layers: Array = []
export var default_layer_height: float = 1.0
export var noise_seed: int = 42 setget run_noise_seed
export var period_scale: float = 64.0

export(float, EXP, 0.1, 100) var scale = 100.0 #scale entire terrain
export(int, 1.0, 200.0) var resolution = 25.0 setget run_resolution #sqrt of total cells
export var center_mesh: bool = true #whether to subtract half the scale from x and z
export var material: Material

export var add_layer: bool setget run_add_layer
export var reset_layers: bool setget run_reset_layers
export var create_mesh: bool
export var poll_rate: float = 0.5

var poll_acc: float = 0.0

var vertices: PoolVector3Array
var colors: PoolColorArray
var normals: PoolVector3Array
var indices: PoolIntArray

#callbacks
func _ready():
	create_arrays()
func _process(delta):
	if create_mesh:
		var new_acc: float = fmod(poll_acc + delta, poll_rate)
		if new_acc < poll_acc:
			generate()
		poll_acc = new_acc		

#settergetters	
func run_noise_seed(s):
	noise_seed = s
	for i in range(0, noise_layers.size()):
		noise_layers[i].seed = noise_seed
func run_add_layer(_s):
	var new_noise = OpenSimplexNoise.new()
	new_noise.seed = noise_seed
	new_noise.octaves = 1
	noise_layers.append(new_noise)
	height_layers.append(default_layer_height)
	width_layers.append(Vector2(-1, 1))
func run_reset_layers(_s):
	noise_layers = []
	height_layers = []
	width_layers = []
	run_add_layer(false)
func run_resolution(s):
	resolution = s
	resize_arrays()

#heavylifters
func generate():
	var mesh = ArrayMesh.new()
	var surface: Array = get_mesh_surface()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	if material:
		mesh.surface_set_material(0, material)
	else:
		var material: SpatialMaterial = SpatialMaterial.new()
		material.vertex_color_use_as_albedo = true
		mesh.surface_set_material(0, material)
	$TerrainMesh.mesh = mesh

func get_mesh_surface():
	var surface = []
	surface.resize(ArrayMesh.ARRAY_MAX)
	update_arrays(null)
	surface[ArrayMesh.ARRAY_VERTEX] = vertices
	surface[ArrayMesh.ARRAY_COLOR] = colors
	surface[ArrayMesh.ARRAY_NORMAL] = normals
	surface[ArrayMesh.ARRAY_INDEX] = indices
	return surface

func update_arrays(_s):
	var vertex_num: int = pow(resolution + 1, 2)
	var cell_num: int = pow(resolution, 2)
	var cell_size: float = 1/float(resolution)
	
	#get noise, add positions and colors per vertex
	for y in range(0, resolution + 1):
		for x in range(0, resolution + 1):
			var noise: float = 0.0
			for i in range(0, noise_layers.size()):
				var raw_noise = noise_layers[i].get_noise_2d(x * cell_size * period_scale, y * cell_size * period_scale)
				if raw_noise >= width_layers[i].x and raw_noise <= width_layers[i].y:
					var final_noise = ((raw_noise + 1)/2) * height_layers[i] * scale
					noise += final_noise
			var index = x + y * (resolution + 1)
			vertices[index] = Vector3(x * cell_size * scale, noise, y * cell_size * scale)
			colors[index] = Color.from_hsv(fposmod(noise/scale, 1),1,1)
	
	#add normals and indices per cell
	for y in range(0, resolution):
		for x in range(0, resolution):
			
			#get cell indices
			var cell_index = x + y * resolution
			var index_index = cell_index * 6
			
			#get point indices
			var top_left = x + y * (resolution + 1)
			var top_right = (x+1) + y * (resolution + 1)
			var bottom_left = x + (y+1) * (resolution + 1)
			var bottom_right = (x+1) + (y+1) * (resolution + 1)
			
			#first triangle indices
			indices[index_index] = top_left
			indices[index_index + 1] = bottom_right
			indices[index_index + 2] = bottom_left
			
			#second triangle indices
			indices[index_index + 3] = bottom_right
			indices[index_index + 4] = top_left
			indices[index_index + 5] = top_right
			
			#first triangle normals
			var normal1: Vector3 = get_normal(vertices[top_left], vertices[bottom_right], vertices[bottom_left])
			normals[top_left] += normal1
			normals[bottom_right] += normal1
			normals[bottom_left] += normal1
			
			#second triangle normals
			var normal2: Vector3 = get_normal(vertices[bottom_right], vertices[top_left], vertices[top_right])
			normals[bottom_right] += normal2
			normals[top_left] += normal2
			normals[top_right] += normal2
	
	#normalize normals
	for i in range(0, vertex_num):
		normals[i] = normals[i].normalized()

func get_normal(a: Vector3, b: Vector3, c: Vector3, flip: bool = false) -> Vector3:
	var normal = (c - a).cross(b - a).normalized()
	return -normal if flip else normal

func resize_arrays():
	var vertex_num: int = pow(resolution + 1, 2)
	var cell_num: int = pow(resolution, 2)
	vertices.resize(vertex_num)
	colors.resize(vertex_num)
	normals.resize(vertex_num)
	indices.resize(cell_num * 6)
	
func create_arrays():
	if !vertices: vertices = PoolVector3Array()
	if !colors: colors = PoolColorArray()
	if !normals: normals = PoolVector3Array()
	if !indices: indices = PoolIntArray()

#c and d are end points of original range (i.e. corner values [-1, 1])
#a and b are end points of new range (i.e. local-space co-ordinates across relevant axis [0, 1])
#x is the target value of the original range (i.e. 0)
#returns target value of the new range (i.e. coordinate across that edge)
func interp(a: float, b: float, c: float, d: float, x: float) -> float:
	return a + (b-a)*abs(x-c)/abs(d-c)
