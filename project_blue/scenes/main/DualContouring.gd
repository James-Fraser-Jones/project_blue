tool
extends Node

export var enable_tool: bool = false

#mesh generation settings
export(float, EXP, 0.1, 10000.0) var scale = 500.0
export(int, EXP, 1.0, 500.0) var resolution = 500.0 setget run_resolution #per-axis
export var center_mesh: bool = true

export var noise: OpenSimplexNoise
export var material: Material

export var generate: bool setget run_generate

var vertices: PoolVector3Array
var colors: PoolColorArray
var normals: PoolVector3Array
var indices: PoolIntArray

func _ready():
	create_arrays()
	resize_arrays()
	
func run_resolution(s):
	if enable_tool:
		resolution = s
		resize_arrays()

func run_generate(_s):
	if enable_tool:
		var mesh = ArrayMesh.new()
		var surface: Array = get_mesh_surface()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
		if material:
			mesh.surface_set_material(0, material)
		else:
			var material: SpatialMaterial = SpatialMaterial.new()
			material.vertex_color_use_as_albedo = true
			mesh.surface_set_material(0, material)
		$DualMesh.mesh = mesh

func get_mesh_surface():
	var surface = []
	surface.resize(ArrayMesh.ARRAY_MAX)
	update_arrays()
	surface[ArrayMesh.ARRAY_VERTEX] = vertices
	surface[ArrayMesh.ARRAY_COLOR] = colors
	surface[ArrayMesh.ARRAY_NORMAL] = normals
	surface[ArrayMesh.ARRAY_INDEX] = indices
	return surface
	
func create_arrays():
	if vertices == null: vertices = PoolVector3Array()
	if colors == null: colors = PoolColorArray()
	if normals == null: normals = PoolVector3Array()
	if indices == null: indices = PoolIntArray()
	
func resize_arrays():
	var vertex_num: int = pow(resolution + 1, 2)
	if vertex_num != vertices.size():
		vertices.resize(vertex_num)
		colors.resize(vertex_num)
		normals.resize(vertex_num)
		var cell_num: int = pow(resolution, 2)
		indices.resize(cell_num * 6)

func update_arrays():
	pass
	
func get_normal(a: Vector3, b: Vector3, c: Vector3, flip: bool = false) -> Vector3:
	var normal = (c - a).cross(b - a).normalized()
	return -normal if flip else normal
