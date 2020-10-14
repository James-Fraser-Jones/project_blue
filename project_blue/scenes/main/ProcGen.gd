tool
extends MeshInstance

export var generate : bool = false setget run_generate

func run_generate(k):
	mesh = $ProcGenRust.proc_gen(42, Vector3.ONE*2.1, Vector3.ZERO, 0.0, Vector3.ONE, Vector3.ONE*100, Vector3.ZERO)
