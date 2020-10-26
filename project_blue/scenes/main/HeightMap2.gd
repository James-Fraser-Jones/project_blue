tool
extends Node

export var noise_layers: Array = []
export var height_layers: Array = []
export var noise_seed: int = 42 setget run_noise_seed
export var period_scale: float = 64.0
export var default_height: float = 100.0

export(float, EXP, 0.1, 100) var scale = 100.0 #scale entire terrain x,z
export(int, 1.0, 200.0) var resolution = 25.0 #sqrt of total cells
export var center_mesh: bool = true #whether to subtract half the scale from x and z
export var material: Material

export var add_layer: bool setget run_add_layer
export var reset_layers: bool setget run_reset_layers
export var create_mesh: bool #setget run_create_mesh
export var poll_rate: float = 0.5

var poll_acc: float = 0.0

func _process(delta):
	var new_acc: float = fmod(poll_acc + delta, poll_rate)
	if new_acc < poll_acc:
		if create_mesh:
			generate()
	poll_acc = new_acc
func run_noise_seed(s):
	noise_seed = s
	for i in range(0, noise_layers.size()):
		noise_layers[i].seed = noise_seed
func run_add_layer(_s):
	var new_noise = OpenSimplexNoise.new()
	new_noise.seed = noise_seed
	noise_layers.append(new_noise)
	height_layers.append(default_height)
func run_reset_layers(_s):
	noise_layers = []
	height_layers = []
	run_add_layer(false)

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

func get_normal(a: Vector3, b: Vector3, c: Vector3, flip: bool = false) -> Vector3:
	var normal = (c - a).cross(b - a).normalized()
	return -normal if flip else normal
	
func get_mesh_surface():
	var surface = []
	var vertices = PoolVector3Array()
	var colors = PoolColorArray()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()
	
	var vertex_num: int = pow(resolution + 1, 2)
	var cell_num: int = pow(resolution, 2)
	var cell_size: float = 1/float(resolution)
	
	#resize arrays
	vertices.resize(vertex_num)
	colors.resize(vertex_num)
	normals.resize(vertex_num)
	indices.resize(cell_num * 6) #2 triangles per cell, 3 indices per triangle
	surface.resize(ArrayMesh.ARRAY_MAX)
	
	#get noise, add positions and colors per vertex
	for y in range(0, resolution + 1):
		for x in range(0, resolution + 1):
			var noise: float = 0.0
			for i in range(0, noise_layers.size()):
				noise += noise_layers[i].get_noise_2d(x * cell_size * period_scale, y * cell_size * period_scale) * height_layers[i]
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
	
	#return surface
	surface[ArrayMesh.ARRAY_VERTEX] = vertices
	surface[ArrayMesh.ARRAY_COLOR] = colors
	surface[ArrayMesh.ARRAY_NORMAL] = normals
	surface[ArrayMesh.ARRAY_INDEX] = indices
	return surface
