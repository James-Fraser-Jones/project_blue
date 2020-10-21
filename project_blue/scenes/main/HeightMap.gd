tool
extends Node

#mesh parameters
export var size: Vector2 = Vector2.ONE*25 setget run_size
export(float, 0.1, 4) var res = 1 setget run_res
export(float, 0, 200) var height_scale = 50 setget run_height_scale
export var height_curve: CurveTexture setget run_height_curve

#base noise parameters
export var noise_seed: int = 42 setget run_noise_seed
export var octaves: int = 3 setget run_octaves
export var period: float = 64 setget run_period
export var persistence: float = 0.5 setget run_persistence
export var lacunarity: float = 2 setget run_lacunarity

#custom noise parameters
export(float, 0.01, 3) var zoom = 0.3 setget run_zoom
export var origin: Vector2 = Vector2.ZERO setget run_origin

export var create_mesh: bool setget run_create_mesh

#global variables
var noise = OpenSimplexNoise.new()
var res_vec: Vector2 = Vector2.ONE * res
var zoom_vec: Vector2 = Vector2.ONE * zoom

func _ready():
	noise.set_seed(noise_seed)
	noise.set_octaves(octaves)
	noise.set_period(period)
	noise.set_persistence(persistence)
	noise.set_lacunarity(lacunarity)
	height_curve = CurveTexture.new()
	height_curve.curve = Curve.new()
	height_curve.curve.add_point(Vector2.ZERO)
	height_curve.curve.add_point(Vector2.ONE)

func get_mesh():
	var cell_num: Vector2 = (size*res_vec).floor()
	var corrected_res: Vector2 = cell_num/size
	var cell_size: Vector2 = Vector2.ONE/corrected_res
	var centre_point: Vector2 = origin + size/2
	
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
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var val
	for x in range(0, cell_num.x):
		for y in range(0, cell_num.y):
			#first triangle
			val = (noise_map[x][y] + 1)/2
			
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x * cell_size.x, height_curve.curve.interpolate_baked(val) * height_scale, y * cell_size.y))
			val = (noise_map[x+1][y] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3((x+1) * cell_size.x, height_curve.curve.interpolate_baked(val) * height_scale, y * cell_size.y))
			val = (noise_map[x][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x * cell_size.x, height_curve.curve.interpolate_baked(val) * height_scale, (y+1) * cell_size.y))
			
			#second triangle
			val = (noise_map[x][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3(x * cell_size.x, height_curve.curve.interpolate_baked(val) * height_scale, (y+1) * cell_size.y))
			val = (noise_map[x+1][y] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3((x+1) * cell_size.x, height_curve.curve.interpolate_baked(val) * height_scale, y * cell_size.y))
			val = (noise_map[x+1][y+1] + 1)/2
			st.add_color(Color.from_hsv(val,1,1))
			st.add_vertex(Vector3((x+1) * cell_size.x, height_curve.curve.interpolate_baked(val) * height_scale, (y+1) * cell_size.y))
	st.index()
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var material: SpatialMaterial = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	$TerrainMesh.mesh = mesh
	
#getter setters
func run_size(s):
	size = s
	if create_mesh:
		get_mesh()

func run_res(r):
	res = r
	res_vec = Vector2.ONE * res
	if create_mesh:
		get_mesh()
		
func run_height_scale(h):
	height_scale = h
	if create_mesh:
		get_mesh()

func run_noise_seed(s):
	noise_seed = s
	noise.set_seed(noise_seed)
	if create_mesh:
		get_mesh()
		
func run_octaves(o):
	octaves = o
	noise.set_octaves(octaves)
	if create_mesh:
		get_mesh()
		
func run_period(p):
	period = p
	noise.set_period(period)
	if create_mesh:
		get_mesh()
		
func run_persistence(p):
	persistence = p
	noise.set_persistence(persistence)
	if create_mesh:
		get_mesh()
		
func run_lacunarity(l):
	lacunarity = l
	noise.set_lacunarity(lacunarity)
	if create_mesh:
		get_mesh()
	
func run_zoom(z):
	zoom = z
	zoom_vec = Vector2.ONE * zoom
	if create_mesh:
		get_mesh()
	
func run_origin(o):
	origin = o
	if create_mesh:
		get_mesh()
	
func run_create_mesh(b):
	create_mesh = b
	if create_mesh:
		get_mesh()
	else:
		$TerrainMesh.mesh = null

func run_height_curve(c):
	height_curve = c
	if create_mesh:
		get_mesh()

#utility functions
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
	
func get_normal(a: Vector3, b: Vector3, c: Vector3, flip: bool = false) -> Vector3:
	var normal = (c - a).cross(b - a).normalized()
	return -normal if flip else normal
