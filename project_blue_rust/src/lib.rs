use gdnative::prelude::*;

#[derive(NativeClass)]
#[inherit(Node)]
struct ProcGen;

#[gdnative::methods]
impl ProcGen {
    fn new(_owner: &Node) -> Self {
        ProcGen
    }

    // #[export]
    // fn _ready(&self, _owner: &Node) {
    //     godot_print!("hello, world.")
    // }

    #[export]
    fn hello(&self, _owner: &Node) {
        godot_print!("hello, world.")
    }
}

fn init(handle: InitHandle) {
    handle.add_tool_class::<ProcGen>(); //'add_tool_class' rather than 'add_class'
}

godot_init!(init);