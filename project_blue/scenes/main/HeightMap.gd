tool
extends Node

#mesh parameters
export var size: Vector2 = Vector2.ONE*25 setget run_size
export(float, 0.1, 4) var res = 1 setget run_res
export(float, 0, 200) var height_scale = 50 setget run_height_scale

#height curve parameters
export var height_curve: Curve
export var height_curve_polling: bool = true
export var height_curve_poll_rate: float = 0.1

#base noise parameters
export var noise_seed: int = 42 setget run_noise_seed
export var octaves: int = 3 setget run_octaves
export var period: float = 64 setget run_period
export var persistence: float = 0.5 setget run_persistence
export var lacunarity: float = 2 setget run_lacunarity

#custom noise parameters
export(float, 0.01, 3) var zoom = 0.3 setget run_zoom
export var origin: Vector2 = Vector2.ZERO setget run_origin

#commands
export var create_mesh: bool setget run_create_mesh

#global variables
var noise = OpenSimplexNoise.new()
var res_vec: Vector2 = Vector2.ONE * res
var zoom_vec: Vector2 = Vector2.ONE * zoom
var height_curve_acc: float = 0.0
var height_curve_data: Array

#callback functions
func _ready():
	noise.set_seed(noise_seed)
	noise.set_octaves(octaves)
	noise.set_period(period)
	noise.set_persistence(persistence)
	noise.set_lacunarity(lacunarity)
	height_curve_data = get_curve_data(height_curve)

func _process(delta):
	if height_curve_polling:
		var new_acc: float = fmod(height_curve_acc + delta, height_curve_poll_rate)
		if new_acc < height_curve_acc:
			var new_curve_data = get_curve_data(height_curve)
			if !is_same_curve(height_curve_data, new_curve_data):
				if create_mesh:
					generate()
				height_curve_data = new_curve_data
		height_curve_acc = new_acc

#heavy lifting functions
func get_noise_map(cell_num: Vector2, cell_size: Vector2, origin: Vector2, centre_point: Vector2) -> Array:
	var noise_map: Array = []
	noise_map.resize(cell_num.x + 1)
	for x in range(0, cell_num.x + 1):
		var noise_row: Array = []
		noise_row.resize(cell_num.y + 1)
		for y in range(0, cell_num.y + 1):
			var noise_point = origin + Vector2(x, y)*cell_size
			var zoomed_noise_point = (noise_point - centre_point)/zoom_vec + centre_point
			noise_row[y] = noise.get_noise_2dv(zoomed_noise_point)
		noise_map[x] = noise_row
	return noise_map

func get_mesh(cell_num: Vector2, cell_size: Vector2, noise_map: Array) -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var val
	for x in range(0, cell_num.x):
		for y in range(0, cell_num.y):
			#first triangle
			val = (noise_map[x][y] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x * cell_size.x, height_curve.interpolate_baked(val) * height_scale, y * cell_size.y))
			val = (noise_map[x+1][y] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3((x+1) * cell_size.x, height_curve.interpolate_baked(val) * height_scale, y * cell_size.y))
			val = (noise_map[x][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x * cell_size.x, height_curve.interpolate_baked(val) * height_scale, (y+1) * cell_size.y))
			
			#second triangle
			val = (noise_map[x][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x * cell_size.x, height_curve.interpolate_baked(val) * height_scale, (y+1) * cell_size.y))
			val = (noise_map[x+1][y] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3((x+1) * cell_size.x, height_curve.interpolate_baked(val) * height_scale, y * cell_size.y))
			val = (noise_map[x+1][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3((x+1) * cell_size.x, height_curve.interpolate_baked(val) * height_scale, (y+1) * cell_size.y))
	st.index()
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	
	var material: SpatialMaterial = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	return mesh

func get_mesh_arr(cell_num: Vector2, cell_size: Vector2, noise_map: Array) -> Mesh:
	#set up arraymesh arrays
	var mesh = ArrayMesh.new()
	var arrays = []
	var vertices = PoolVector3Array()
	var colors = PoolColorArray()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()
	
	#resize arrays
	arrays.resize(ArrayMesh.ARRAY_MAX)
	var vertex_num: int = (cell_num.x + 1)*(cell_num.y + 1)
	vertices.resize(vertex_num)
	colors.resize(vertex_num)
	normals.resize(vertex_num)
	indices.resize(cell_num.x * cell_num.y * 6) #2 triangles per cell, 3 indices per triangle
	
	#add positions and colors per point
	for y in range(0, cell_num.y + 1):
		for x in range(0, cell_num.x + 1):
			var index = x + y * (cell_num.x + 1)
			var val = (noise_map[x][y] + 1)/2
			vertices[index] = Vector3(x * cell_size.x, height_curve.interpolate_baked(val) * height_scale, y * cell_size.y)
			colors[index] = Color.from_hsv(val,1,1)
	
	#add normals and indices per cell
	for y in range(0, cell_num.y):
		for x in range(0, cell_num.x):
			#get cell indices
			var cell_index = x + y * cell_num.x
			var index_index = cell_index * 6
			#get point indices
			var top_left = x + y * (cell_num.x + 1)
			var top_right = (x+1) + y * (cell_num.x + 1)
			var bottom_left = x + (y+1) * (cell_num.x + 1)
			var bottom_right = (x+1) + (y+1) * (cell_num.x + 1)
			
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
	
	#commit to mesh
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_COLOR] = colors
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	#add vertex color material
	var material: SpatialMaterial = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	
	return mesh

func generate():
	var cell_num: Vector2 = (size*res_vec).floor() 		#how many squares total
	var corrected_res: Vector2 = cell_num/size 			#how many cells fit into a unit
	var cell_size: Vector2 = Vector2.ONE/corrected_res 	#how big each cell is
	var centre_point: Vector2 = origin + size/2 		#center point of all the block
	var noise_map: Array = get_noise_map(cell_num, cell_size, origin, centre_point)
	$TerrainMesh.mesh = get_mesh_arr(cell_num, cell_size, noise_map)
	
#getter setters
func run_size(s):
	size = s
	if create_mesh:
		generate()

func run_res(r):
	res = r
	res_vec = Vector2.ONE * res
	if create_mesh:
		generate()
		
func run_height_scale(h):
	height_scale = h
	if create_mesh:
		generate()

func run_noise_seed(s):
	noise_seed = s
	noise.set_seed(noise_seed)
	if create_mesh:
		generate()
		
func run_octaves(o):
	octaves = o
	noise.set_octaves(octaves)
	if create_mesh:
		generate()
		
func run_period(p):
	period = p
	noise.set_period(period)
	if create_mesh:
		generate()
		
func run_persistence(p):
	persistence = p
	noise.set_persistence(persistence)
	if create_mesh:
		generate()
		
func run_lacunarity(l):
	lacunarity = l
	noise.set_lacunarity(lacunarity)
	if create_mesh:
		generate()
	
func run_zoom(z):
	zoom = z
	zoom_vec = Vector2.ONE * zoom
	if create_mesh:
		generate()
	
func run_origin(o):
	origin = o
	if create_mesh:
		generate()
	
func run_create_mesh(b):
	create_mesh = b
	if create_mesh:
		generate()
	else:
		$TerrainMesh.mesh = null

#utility functions
func is_same_curve(pos: Array, pos2: Array) -> bool:
	if pos.size() != pos2.size():
		return false
	for i in range(0, pos.size()):
		if pos[i] != pos2[i]:
			return false
	return true

func get_curve_data(curve: Curve) -> Array:
	var data: Array
	for i in range(0, curve.get_point_count()):
		data.append(curve.get_point_position(i))
		data.append(curve.get_point_left_tangent(i))
		data.append(curve.get_point_right_tangent(i))
	return data

func get_normal(a: Vector3, b: Vector3, c: Vector3, flip: bool = false) -> Vector3:
	var normal = (c - a).cross(b - a).normalized()
	return -normal if flip else normal
	
#examples
func surface_tool_plane(size: Vector2) -> Mesh:
	var val_grid: Array = []
	for x in range(0, size.x + 1):
		var val_row: Array = []
		for y in range(0, size.y + 1):
			val_row.append(noise.get_noise_2d(x, y))
		val_grid.append(val_row)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var scale = 100
	var val
	for x in range(0, size.x):
		for y in range(0, size.y):
			#first triangle
			val = (val_grid[x][y] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x, val * scale, y))
			val = (val_grid[x+1][y] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x+1, val * scale, y))
			val = (val_grid[x][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x, val * scale, y+1))
			
			#second triangle
			val = (val_grid[x][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x, val * scale, y+1))
			val = (val_grid[x+1][y] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x+1, val * scale, y))
			val = (val_grid[x+1][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x+1, val * scale, y+1))
	st.generate_normals()
	st.index()
	var mesh: ArrayMesh = st.commit()
	var material: SpatialMaterial = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	return mesh

func array_mesh_triangle() -> Mesh:
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	var v0 = Vector3(1, 0, 1)
	var v1 = Vector3(0, 0, 1)
	var v2 = Vector3(1, 0, 0)
	var normal = get_normal(v0, v1, v2)
	vertices.append(v0)
	vertices.append(v1)
	vertices.append(v2)
	normals.append(normal)
	normals.append(normal)
	normals.append(normal)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
