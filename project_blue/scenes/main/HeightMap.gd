tool
extends Node

#spawn parameters
export var size: Vector2 = Vector2.ONE*255
export(float, 1, 4) var res = 1 setget run_res

#noise parameters
export var seeed: int = 42 setget run_seed
#export(float, 0.01, 1.5) var zoom = 0.3 setget run_zoom
#export var origin: Vector2 = Vector2.ZERO setget run_origin

#export(float, -1, 1) var thresh = 0 setget run_thresh
#export var invert: bool = false setget run_invert

#commands
#export var spawn : bool setget run_spawn
#export var delete : bool setget run_delete

#global variables
var noise = OpenSimplexNoise.new()
var res_vec: Vector2 = Vector2.ONE * res
#var zoom_vec: Vector2 = Vector2.ONE * zoom

#create a new mesh
export var create_mesh : bool setget run_create_mesh
#position the vertices at the correct x,z points in 3D space
export var transform_mesh : bool setget run_transform_mesh
#position the vertices at the correct y points in 3D space, based on noise sampling
export var bump_mesh : bool setget run_bump_mesh

func _ready():
	run_seed(seeed)

func run_seed(s):
	seeed = s
	noise.set_seed(s)

func run_res(r):
	res = r
	res_vec = Vector2.ONE * res

func run_create_mesh(_b):
	$TerrainMesh.mesh = surface_tool_plane(size)

func run_transform_mesh(_b):
	pass
	
func run_bump_mesh(_b):
	pass

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

func surface_tool_triangle() -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(Vector3(1, 0, 1))
	st.add_vertex(Vector3(0, 0, 1))
	st.add_vertex(Vector3(1, 0, 0))
	st.generate_normals()
	st.index()
	return st.commit()

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
	var normal = (c - a).cross(b - a)
	return -normal if flip else normal
