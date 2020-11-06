tool
extends Node

export var enable_tool: bool = false

#mesh generation settings
export(float, EXP, 0.1, 10000.0) var size = 1
export(int, 0, 6) var max_depth = 0
export var noise: OpenSimplexNoise

export var generate: bool setget run_generate
export var remove_mesh: bool setget run_remove_mesh

func run_generate(_s):
	if enable_tool:
		var arr_mesh = ArrayMesh.new()
		var octree: Dictionary = build_octree(size, Vector3.ZERO, max_depth)
		mesh_from_octree(arr_mesh, octree)
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

func build_octree(size: float, center: Vector3, max_depth: int) -> Dictionary:
	var corners: Array = get_corners(size, center)
	if max_depth > 0:
		if contains_contour(corners):
			var children = [
				build_octree(size/2, center + Vector3(-1,-1,-1) * size/4, max_depth - 1)
			,	build_octree(size/2, center + Vector3(1,-1,-1) * size/4, max_depth - 1)
			,	build_octree(size/2, center + Vector3(-1,1,-1) * size/4, max_depth - 1)
			,	build_octree(size/2, center + Vector3(1,1,-1) * size/4, max_depth - 1)
			,	build_octree(size/2, center + Vector3(-1,-1,1) * size/4, max_depth - 1)
			,	build_octree(size/2, center + Vector3(1,-1,1) * size/4, max_depth - 1)
			,	build_octree(size/2, center + Vector3(-1,1,1) * size/4, max_depth - 1)
			,	build_octree(size/2, center + Vector3(1,1,1) * size/4, max_depth - 1)
			]
			return {children: children}
		else:
			return {}
	else:
		return {size: size, center: center, corners: corners}

func s(f: float) -> bool: #returns true if point lies on (or inside) surface
	return f <= 0

func contains_contour(corners: Array) -> bool:
	var is_full: bool = s(corners[0]) && s(corners[1]) && s(corners[2]) && s(corners[3]) && s(corners[4]) && s(corners[5]) && s(corners[6]) && s(corners[7])
	var is_empty: bool = !s(corners[0]) && !s(corners[1]) && !s(corners[2]) && !s(corners[3]) && !s(corners[4]) && !s(corners[5]) && !s(corners[6]) && !s(corners[7])
	return !(is_full || is_empty)

func get_corners(size, center) -> Array:
	return [
		noise.get_noise_3dv(center + Vector3(-1,-1,-1) * size/2)
	,	noise.get_noise_3dv(center + Vector3(1,-1,-1) * size/2)
	,	noise.get_noise_3dv(center + Vector3(-1,1,-1) * size/2)
	,	noise.get_noise_3dv(center + Vector3(1,1,-1) * size/2)
	,	noise.get_noise_3dv(center + Vector3(-1,-1,1) * size/2)
	,	noise.get_noise_3dv(center + Vector3(1,-1,1) * size/2)
	,	noise.get_noise_3dv(center + Vector3(-1,1,1) * size/2)
	,	noise.get_noise_3dv(center + Vector3(1,1,1) * size/2)
	]
	
func mesh_from_octree(arr_mesh: ArrayMesh, octree: Dictionary):
	#initialize arrays
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	
	#add vertices and normals
	cellProc(octree, vertices, normals)
	
	#add mesh
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
func cellProc(octree: Dictionary, vertices: PoolVector3Array, normals: PoolVector3Array):
	match octree_type(octree):
		CellType.NODE:
			cellProc(octree.children[0], vertices, normals)
			cellProc(octree.children[1], vertices, normals)
			cellProc(octree.children[2], vertices, normals)
			cellProc(octree.children[3], vertices, normals)
			cellProc(octree.children[4], vertices, normals)
			cellProc(octree.children[5], vertices, normals)
			cellProc(octree.children[6], vertices, normals)
			cellProc(octree.children[7], vertices, normals)
			faceProc([octree.children[0], octree.children[1]], vertices, normals, Axis.X)
			faceProc([octree.children[2], octree.children[3]], vertices, normals, Axis.X)
			faceProc([octree.children[4], octree.children[5]], vertices, normals, Axis.X)
			faceProc([octree.children[6], octree.children[7]], vertices, normals, Axis.X)
			faceProc([octree.children[0], octree.children[2]], vertices, normals, Axis.Y)
			faceProc([octree.children[1], octree.children[3]], vertices, normals, Axis.Y)
			faceProc([octree.children[4], octree.children[6]], vertices, normals, Axis.Y)
			faceProc([octree.children[5], octree.children[7]], vertices, normals, Axis.Y)
			faceProc([octree.children[0], octree.children[4]], vertices, normals, Axis.Z)
			faceProc([octree.children[1], octree.children[5]], vertices, normals, Axis.Z)
			faceProc([octree.children[2], octree.children[6]], vertices, normals, Axis.Z)
			faceProc([octree.children[3], octree.children[7]], vertices, normals, Axis.Z)
			edgeProc([octree.children[0], octree.children[2], octree.children[4], octree.children[6]], vertices, normals, Axis.X)
			edgeProc([octree.children[1], octree.children[3], octree.children[5], octree.children[7]], vertices, normals, Axis.X)
			edgeProc([octree.children[0], octree.children[1], octree.children[4], octree.children[5]], vertices, normals, Axis.Y)
			edgeProc([octree.children[2], octree.children[3], octree.children[6], octree.children[7]], vertices, normals, Axis.Y)
			edgeProc([octree.children[0], octree.children[1], octree.children[2], octree.children[3]], vertices, normals, Axis.Z)
			edgeProc([octree.children[4], octree.children[5], octree.children[6], octree.children[7]], vertices, normals, Axis.Z)
		CellType.LEAF:
			pass
		CellType.FULL_EMPTY:
			pass

func faceProc(octrees: Array, vertices: PoolVector3Array, normals: PoolVector3Array, axis: int):
	pass

func edgeProc(octrees: Array, vertices: PoolVector3Array, normals: PoolVector3Array, axis: int):
	pass
	
enum Axis {X, Y, Z}
enum CellType {NODE, LEAF, FULL_EMPTY}

func octree_child(): #attempt to get child but return parent if it's actually a leaf
	pass

func octree_type(octree: Dictionary) -> int:
	if octree.children:
		return CellType.NODE
	elif octree.size:
		return CellType.LEAF
	else:
		return CellType.FULL_EMPTY
