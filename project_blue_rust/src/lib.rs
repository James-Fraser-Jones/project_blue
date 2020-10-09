use gdnative::prelude::*;

#[derive(NativeClass)]
#[inherit(Node)]
struct ProcGen;

#[gdnative::methods]
impl ProcGen {
    fn new(_owner: &Node) -> Self {
        ProcGen
    }

    #[export]
    fn hello(&self, _owner: &Node) {
        godot_print!("hello, world.")
    }
}

fn init(handle: InitHandle) {
    handle.add_tool_class::<ProcGen>();
}

godot_init!(init);