use gdnative::prelude::*;
use gdnative::api::{ArrayMesh, SurfaceTool, OpenSimplexNoise, Mesh, Material};

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

    #[export]
    fn proc_gen(&self, _owner: &Node, mesh_ref: &Ref<ArrayMesh, Shared>, material_ref: &Ref<Material, Shared>) {
        let mut mesh = unsafe { mesh_ref.assume_safe() };

        let noise = OpenSimplexNoise::new();
        noise.set_seed(42);

        let st = SurfaceTool::new();
        st.begin(Mesh::PRIMITIVE_TRIANGLES);

        match st.commit(Null::null(), 97280) {
            Some(m) => mesh = unsafe { m.assume_safe() },
            None => godot_print!("Rust error: Could not commit mesh"),
        }

        mesh.surface_set_material(0, material_ref)
    }
}

fn init(handle: InitHandle) {
    handle.add_tool_class::<ProcGen>();
}

godot_init!(init);

// func add_triangle(a,b,c):
// 	st.add_vertex(a)
// 	st.add_vertex(b)
// 	st.add_vertex(c)

// func add_square(a,b,c,d):
// 	st.add_normal(-(b-a).cross(c-a))
// 	add_triangle(a,b,c)
// 	add_triangle(b,d,c)
	
// func add_cube(a,b,c,d,e,f,g,h):
// 	add_square(a,b,c,d)
// 	add_square(f,e,h,g)
// 	add_square(b,a,f,e)
// 	add_square(c,d,g,h)
// 	add_square(a,c,e,g)
// 	add_square(d,b,h,f)

// func add_cube_safe(origin: Vector3, scale: Vector3):
// 	var a = origin
// 	var b = a + Vector3.RIGHT * scale.x
// 	var c = a + Vector3.FORWARD * scale.z
// 	var d = b + Vector3.FORWARD * scale.z
// 	var e = a + Vector3.UP * scale.y
// 	var f = b + Vector3.UP * scale.y
// 	var g = c + Vector3.UP * scale.y
// 	var h = d + Vector3.UP * scale.y
// 	add_cube(a,b,c,d,e,f,g,h)

// func add_cubes(origin: Vector3, scale: Vector3, size: Vector3):
// 	for x in range(size.x):
// 		for y in range(size.y):
// 			for z in range(size.z):
// 				var this_origin : Vector3 = origin
// 				this_origin += Vector3(x,y,z) * scale
// 				var val : float = noise.get_noise_3d(x,y,z)
// 				if val <= threshold and val >= -threshold:
// 					add_cube_safe(this_origin, scale)