tool
extends Node

export var generate : bool = false setget run_generate

func run_generate(k):
	$proc_gen_rust.hello()
