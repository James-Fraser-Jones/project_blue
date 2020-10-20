tool
extends MeshInstance

export var seeed: int = 42
export var zoom: Vector3 = Vector3.ONE*15
export var origin: Vector3 = Vector3.ZERO
export(float, -1, 1) var thresh = 0
export var res: Vector3 = Vector3.ONE*3
export var size: Vector3 = Vector3.ONE*10
export var trans: Vector3 = Vector3.ZERO
export var generate : bool setget run_generate

func run_generate(k):
	mesh = $ProcGenRust.proc_gen(seeed, zoom, origin, thresh, res, size, trans)
