tool
extends MeshInstance

export var generate : bool = false setget run_generate

func run_generate(k):
	mesh = $ProcGenRust.proc_gen()
