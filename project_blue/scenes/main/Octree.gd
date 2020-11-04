tool
extends Node

export var enable_tool: bool = false

#mesh generation settings
export(float, EXP, 0.1, 10000.0) var size = 1
export(int, 1, 7) var max_depth = 1
export var noise: OpenSimplexNoise
export var color_scale: float = 1
export var color_leaves_only: bool = false
export var color_leaf: Color

export var generate: bool setget run_generate
export var remove_mesh: bool setget run_remove_mesh

func run_generate(_s):
	if enable_tool:
		var arr_mesh = ArrayMesh.new()
		build_mesh(arr_mesh, size, Vector3.ZERO, max_depth)
		var mesh_instance = MeshInstance.new()
		mesh_instance.mesh = arr_mesh
		while get_child_count() > 0:
			fire_child()
		add_child(mesh_instance)

func fire_child():
	var child = get_child(0)
	remove_child(child)
	child.queue_free()

func run_remove_mesh(_s):
	if enable_tool:
		fire_child()

func build_mesh(arr_mesh: ArrayMesh, size: float, origin: Vector3, max_depth: int):
	#initialize arrays
	var vertices = PoolVector3Array()
	var colors = PoolColorArray()
	var indices: PoolIntArray = PoolIntArray([0,1,2,3,4,5,6,7,8,9,10,11,0,2,4,6,8,10,1,3,5,7,9,11,12,13,14,15,16,17])
	vertices.resize(12 + 6)
	colors.resize(12 + 6)
	
	var mid: float = size/2
	
	#add vertices
	vertices[0] = Vector3(0, -1, -1)*mid + origin
	vertices[1] = Vector3(0, 1, -1)*mid + origin
	vertices[2] = Vector3(0, -1, 1)*mid + origin
	vertices[3] = Vector3(0, 1, 1)*mid + origin
	vertices[4] = Vector3(-1, 0, -1)*mid + origin
	vertices[5] = Vector3(1, 0, -1)*mid + origin
	vertices[6] = Vector3(-1, 0, 1)*mid + origin
	vertices[7] = Vector3(1, 0, 1)*mid + origin
	vertices[8] = Vector3(-1, -1, 0)*mid + origin
	vertices[9] = Vector3(1, -1, 0)*mid + origin
	vertices[10] = Vector3(-1, 1, 0)*mid + origin
	vertices[11] = Vector3(1, 1, 0)*mid + origin
	
	vertices[12] = Vector3(-1, 0, 0)*mid + origin
	vertices[13] = Vector3(1, 0, 0)*mid + origin
	vertices[14] = Vector3(0, -1, 0)*mid + origin
	vertices[15] = Vector3(0, 1, 0)*mid + origin
	vertices[16] = Vector3(0, 0, -1)*mid + origin
	vertices[17] = Vector3(0, 0, 1)*mid + origin
	
	#add colors
	for i in range(0, vertices.size()):
		var val = clamp((noise.get_noise_3dv(vertices[i])*color_scale + 1)/2, 0, 1)
		if color_leaves_only:
			colors[i] = Color.from_hsv(color_leaf.h,1,1 if max_depth == 1 else 0)
		else:
			colors[i] = Color.from_hsv(val,1,1)
	
	#add mesh
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_COLOR] = colors
	arrays[ArrayMesh.ARRAY_INDEX] = indices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	#add material
	var material: SpatialMaterial = SpatialMaterial.new()
	#material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	material.flags_unshaded = true
	arr_mesh.surface_set_material(arr_mesh.get_surface_count()-1, material)
	
	#recurse (or don't)
	if max_depth > 1:
		for z in range(-1, 2, 2):
			for y in range(-1, 2, 2):
				for x in range(-1, 2, 2):
					var acc: int = 0
					acc += 1 if noise.get_noise_3dv(Vector3(0,0,0)*mid + origin) >= 0 else -1
					acc += 1 if noise.get_noise_3dv(Vector3(x,0,0)*mid + origin) >= 0 else -1
					acc += 1 if noise.get_noise_3dv(Vector3(0,y,0)*mid + origin) >= 0 else -1
					acc += 1 if noise.get_noise_3dv(Vector3(x,y,0)*mid + origin) >= 0 else -1
					acc += 1 if noise.get_noise_3dv(Vector3(0,0,z)*mid + origin) >= 0 else -1
					acc += 1 if noise.get_noise_3dv(Vector3(x,0,z)*mid + origin) >= 0 else -1
					acc += 1 if noise.get_noise_3dv(Vector3(0,y,z)*mid + origin) >= 0 else -1
					acc += 1 if noise.get_noise_3dv(Vector3(x,y,z)*mid + origin) >= 0 else -1
					if acc > -8 and acc < 8:
						build_mesh(arr_mesh, mid, Vector3(x,y,z)*mid/2 + origin, max_depth - 1)
