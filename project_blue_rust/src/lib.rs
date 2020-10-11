pub mod transvoxel;

use gdnative::prelude::*;
use gdnative::api::{ArrayMesh, SurfaceTool, OpenSimplexNoise, Mesh};
use isosurface::marching_cubes::MarchingCubes;
use isosurface::linear_hashed_marching_cubes::LinearHashedMarchingCubes;
use isosurface::source::Source;

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
    fn proc_gen(&self, _owner: &Node) -> Ref<ArrayMesh, Unique> {
        let mut mesh = ArrayMesh::new();
        let st = SurfaceTool::new();

        let noise = Noise::new();
        noise.set_seed(100);

        let mut marching_cubes = LinearHashedMarchingCubes::new(128);
        let mut vertices : Vec<f32> = Vec::new();
        let mut indices : Vec<u32> = Vec::new();
        marching_cubes.extract(&noise, &mut vertices, &mut indices);
        //marching_cubes.extract(&Const{switch: false, val: 0.5}, &mut vertices, &mut indices);
        
        st.begin(Mesh::PRIMITIVE_TRIANGLES);
        add_mesh(&st, vertices, indices);
        st.generate_normals(false);
        st.index();

        match st.commit(Null::null(), 97280) {
            Some(m) => mesh = unsafe { m.assume_unique() },
            None => godot_print!("Rust error: Could not commit mesh"),
        }

        mesh

        //mesh.surface_set_material(0, material_ref)
    }
}

fn add_mesh(st: &Ref<SurfaceTool, Unique>, mut vertices: Vec<f32>, indices: Vec<u32>){
    while vertices.len() >= 3 {
        let a = vertices.pop().unwrap();
        let b = vertices.pop().unwrap();
        let c = vertices.pop().unwrap();
        st.add_vertex(Vector3::new(a,b,c));
    }
    // for index in indices.iter() {
    //     st.add_index(*index as i64);
    // }
    transvoxel::transvoxel()
}

struct Noise {
    noise: Ref<OpenSimplexNoise, Unique>
}
impl Noise {
    fn get_noise_3d(&self, x: f64, y: f64, z: f64) -> f64 {
        self.noise.get_noise_3d(x,y,z)
    }
    fn set_seed(&self, n: i32) {
        self.noise.set_seed(n as i64);
    }
    fn new() -> Noise {
        Noise{noise: OpenSimplexNoise::new()}
    }
}
impl Source for Noise {
    fn sample(&self, x: f32, y: f32, z: f32) -> f32 {
        self.get_noise_3d(x as f64, y as f64, z as f64) as f32
    }
}

struct Const {
    switch: bool,
    val: f32,
}
impl Const {
    fn sample(&mut self) -> f32 {
        self.switch = !self.switch;
        (if self.switch {-1.0} else {1.0}) * self.val
    }
}
impl Source for Const {
    fn sample(&self, _x: f32, _y: f32, _z: f32) -> f32 {
        self.val
    }
}

fn init(handle: InitHandle) {
    handle.add_tool_class::<ProcGen>();
}

godot_init!(init);

fn add_triangle(st: &Ref<SurfaceTool, Unique>, a: Vector3, b: Vector3, c: Vector3) {
    st.add_vertex(a);
    st.add_vertex(b);
    st.add_vertex(c);
}

fn add_square(st: &Ref<SurfaceTool, Unique>, a: Vector3, b: Vector3, c: Vector3, d: Vector3) {
    st.add_normal(-(b-a).cross(c-a));
    add_triangle(st, a, b, c);
    add_triangle(st, b, d, c);
}

fn add_cube(st: &Ref<SurfaceTool, Unique>, a: Vector3, b: Vector3, c: Vector3, d: Vector3, e: Vector3, f: Vector3, g: Vector3, h: Vector3) {
    add_square(st,a,b,c,d);
    add_square(st,f,e,h,g);
    add_square(st,b,a,f,e);
    add_square(st,c,d,g,h);
    add_square(st,a,c,e,g);
    add_square(st,d,b,h,f);
}

fn add_cube_safe(st: &Ref<SurfaceTool, Unique>, origin: Vector3, scale: Vector3) {
    let a = origin;
    let b = a + Vector3::new(1.0,0.0,0.0) * scale.x;
    let c = a + Vector3::new(0.0,0.0,1.0) * scale.z;
    let d = b + Vector3::new(0.0,0.0,1.0) * scale.z;
    let e = a + Vector3::new(0.0,1.0,0.0) * scale.y;
    let f = b + Vector3::new(0.0,1.0,0.0) * scale.y;
    let g = c + Vector3::new(0.0,1.0,0.0) * scale.y;
    let h = d + Vector3::new(0.0,1.0,0.0) * scale.y;
    add_cube(st,a,b,c,d,e,f,g,h);
}

fn add_cubes(st: &Ref<SurfaceTool, Unique>, noise: &Ref<OpenSimplexNoise, Unique>, origin: Vector3, size: Vector3, threshold: f64) {
    for x in 0 .. size.x as i32 {
        for y in 0 .. size.y as i32 {
            for z in 0 .. size.z as i32 {
                let this_origin = origin + Vector3::new(x as f32, y as f32, z as f32); //*scale
                let val: f64 = noise.get_noise_3d(x as f64, y as f64, z as f64);
                if val <= threshold && val >= -threshold {
                    add_cube_safe(st, this_origin, Vector3::new(1.0,1.0,1.0))
                }
            }
        }
    }
}