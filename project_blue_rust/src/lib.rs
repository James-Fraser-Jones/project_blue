pub mod transvoxel;

use gdnative::prelude::*;
use gdnative::api::{Mesh, ArrayMesh};
use noise::Perlin;

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
    fn proc_gen(&self, _owner: &Node
                , seed: usize
                , zoom: Vector3
                , origin: Vector3
                , thresh: f64
                , res: Vector3
                , size: Vector3
                , trans: Vector3) 
                -> Ref<ArrayMesh, Unique> {

        let (vertices, normals) = 
            transvoxel::marching_cubes(
                Perlin::new()
            ,   seed as u32
            ,   [zoom.x as f64, zoom.y as f64, zoom.z as f64]
            ,   [origin.x as f64, origin.y as f64, origin.z as f64]
            ,   thresh
            ,   [res.x as f64, res.y as f64, res.z as f64]
            ,   [size.x as f64, size.y as f64, size.z as f64]
            ,   [trans.x as f64, trans.y as f64, trans.z as f64]
            );
        
        //https://godotengine.org/qa/22503/using-mesh-addsurfacefromarrays-from-c%23
        // var arrays = []
        // arrays.resize(Mesh.ARRAY_MAX)
        // arrays[Mesh.ARRAY_VERTEX] = vertex_array
        // arrays[Mesh.ARRAY_NORMAL] = normal_array

        let array_mesh = ArrayMesh::new();
        let arrays = VariantArray::new();
        arrays.resize(Mesh::ARRAY_MAX as i32);
        let mut vertex_array = Vector3Array::new();
        for vertex in vertices.iter() {
            let [x,y,z] = vertex;
            vertex_array.push(Vector3::new(*x as f32, *y as f32, *z as f32));
        }
        let mut normal_array = Vector3Array::new();
        for normal in normals.iter() {
            let [x,y,z] = normal;
            normal_array.push(Vector3::new(*x as f32, *y as f32, *z as f32));
        }
        arrays.set(Mesh::ARRAY_VERTEX as i32, vertex_array);
        arrays.set(Mesh::ARRAY_NORMAL as i32, normal_array);
        array_mesh.add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arrays.into_shared(), VariantArray::new().into_shared(), 97280);

        array_mesh
    }
}

fn init(handle: InitHandle) {
    handle.add_tool_class::<ProcGen>();
}

godot_init!(init);