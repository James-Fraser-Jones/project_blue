tool
extends Node

export var enable_tool: bool = false

export var noise: OpenSimplexNoise
export var height_curve: Curve
export var scale_y: float = 1.0

export(float, EXP, 0.1, 10000.0) var scale_xyz = 500.0
export(int, EXP, 1.0, 500.0) var resolution = 500.0 setget run_resolution #per-axis

export var scale_period: float = 64.0
export var center_mesh: bool = true
export var island_mesh: bool = true
export var island_start_radius: float = 0.8
export var material: Material

export var create_mesh: bool setget run_create_mesh

var vertices: PoolVector3Array
var colors: PoolColorArray
var normals: PoolVector3Array
var indices: PoolIntArray

#setter functions are called on initialization (loading or every save for tool scripts)
#setter functions will be called with set values for exported vars or default values for
#primitive types or null for reference types
#if a set value on an exported variable is different from the default then the setter will
#be called twice with the currently set value (not sure why)

func _ready():
	create_arrays()
	resize_arrays()

func run_resolution(s):
	if enable_tool:
		resolution = s
		resize_arrays()

func run_create_mesh(s):
	if enable_tool:
		generate()

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
	update_arrays()
	surface[ArrayMesh.ARRAY_VERTEX] = vertices
	surface[ArrayMesh.ARRAY_COLOR] = colors
	surface[ArrayMesh.ARRAY_NORMAL] = normals
	surface[ArrayMesh.ARRAY_INDEX] = indices
	return surface

func update_arrays():
	var vertex_num: int = pow(resolution + 1, 2)
	var cell_num: int = pow(resolution, 2)
	var cell_size: float = 1/float(resolution)
	
	#get noise, add positions and colors per vertex
	for y in range(0, resolution + 1):
		for x in range(0, resolution + 1):
			var raw_noise_val = (noise.get_noise_2d(x * cell_size * scale_period, y * cell_size * scale_period) + 1)/2
			
			var island_scale = 1
			if island_mesh:
				var radius = resolution / 2
				var distance = (Vector2(x, y) - Vector2.ONE * radius).length()
				var radius_scale = distance/radius
				if radius_scale < island_start_radius:
					pass
				elif radius_scale < 1:
					island_scale = 1 - ((radius_scale - island_start_radius)/(1-island_start_radius))
				else:
					island_scale = 0
			var noise_val = height_curve.interpolate_baked(raw_noise_val) * scale_y * island_scale
			var index = x + y * (resolution + 1)
			var c = 0.5 if center_mesh else 0
			vertices[index] = Vector3(x * cell_size - c, noise_val, y * cell_size - c) * scale_xyz
			colors[index] = Color.from_hsv(fposmod(raw_noise_val, 1),1,1)
	
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
	if vertex_num != vertices.size():
		vertices.resize(vertex_num)
		colors.resize(vertex_num)
		normals.resize(vertex_num)
		var cell_num: int = pow(resolution, 2)
		indices.resize(cell_num * 6)
	
func create_arrays():
	if vertices == null: vertices = PoolVector3Array()
	if colors == null: colors = PoolColorArray()
	if normals == null: normals = PoolVector3Array()
	if indices == null: indices = PoolIntArray()
