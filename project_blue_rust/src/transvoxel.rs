use transvoxel_data::regular_cell_data::{RegularCellData, REGULAR_CELL_CLASS, REGULAR_CELL_DATA, REGULAR_VERTEX_DATA};
use noise::{Perlin, NoiseFn, Seedable};

pub fn marching_cubes( noise: (impl NoiseFn<[f64;3]> + Seedable)
                     , seed: u32 //noise variables
                     , zoom: [f64; 3]
                     , origin: [f64; 3]
                     , threshold: f64
                     , rez: [f64; 3] //terrain variables
                     , size: [f64; 3]
                     , trans: [f64; 3]
                     ) -> (Vec<[f64; 3]>, Vec<[f64; 3]>) {

    //get info
    let dim: [usize; 3] = [(size[0]*rez[0]) as usize, (size[1]*rez[1]) as usize, (size[1]*rez[1]) as usize]; //how many cells?
    let step_size: [f64; 3] = [size[0]/rez[0], size[1]/rez[1], size[1]/rez[1]]; //how wide is each cell?

    //generate voxels
    let noise = noise.set_seed(seed);
    let voxel_count: usize = (dim[0]+1)*(dim[1]+1)*(dim[2]+1);
    let mut voxels: Vec<i8> = Vec::with_capacity(voxel_count);
    for z in 0..(dim[2]+1) {
        for y in 0..(dim[1]+1) {
            for x in 0..(dim[0]+1) {
                let val = ((noise.get(
                            [ origin[0] + (x as f64/zoom[0])
                            , origin[1] + (y as f64/zoom[1])
                            , origin[2] + (z as f64/zoom[2])
                            ]) + threshold) * 127.0) as i8;
                voxels.push(val);
            }
        }
    }

    //generate mesh
    let vertex_count: usize = 12*dim[0]*dim[1]*dim[2];
    let mut vertices: Vec<[f64; 3]> = Vec::with_capacity(vertex_count);
    let mut normals = Vec::with_capacity(vertex_count);
    for z in 0..dim[2] {
        for y in 0..dim[1] {
            for x in 0..dim[0] {

                //get corner values
                let corners: [i8; 8] = 
                [ voxels[x + y*(dim[0]+1) + z*(dim[0]+1)*(dim[1]+1)]
                , voxels[(x+1) + y*(dim[0]+1) + z*(dim[0]+1)*(dim[1]+1)]
                , voxels[x + (y+1)*(dim[0]+1) + z*(dim[0]+1)*(dim[1]+1)]
                , voxels[(x+1) + (y+1)*(dim[0]+1) + z*(dim[0]+1)*(dim[1]+1)]
                , voxels[x + y*(dim[0]+1) + (z+1)*(dim[0]+1)*(dim[1]+1)]
                , voxels[(x+1) + y*(dim[0]+1) + (z+1)*(dim[0]+1)*(dim[1]+1)]
                , voxels[x + (y+1)*(dim[0]+1) + (z+1)*(dim[0]+1)*(dim[1]+1)]
                , voxels[(x+1) + (y+1)*(dim[0]+1) + (z+1)*(dim[0]+1)*(dim[1]+1)]             
                ];

                let case_code: u8 = corners_to_index(corners);
                if (case_code ^ ((corners[7] >> 7) as u8)) != 0 { //if case_code != 00000000 && case_code != 11111111

                    //get cell and vertex data
                    let cell_data: RegularCellData = REGULAR_CELL_DATA[REGULAR_CELL_CLASS[case_code as usize] as usize];
                    let vertex_data: [u16; 12] = REGULAR_VERTEX_DATA[case_code as usize];

                    for i in 0..cell_data.get_triangle_count() {
                        //calculate and add vertices
                        let v0 = vertex_data[cell_data.vertex_index[0 + (i as usize)*3] as usize];
                        let v1 = vertex_data[cell_data.vertex_index[1 + (i as usize)*3] as usize];
                        let v2 = vertex_data[cell_data.vertex_index[2 + (i as usize)*3] as usize];
                        let adder_v0 = add_vertex(v0, &corners);
                        let adder_v1 = add_vertex(v1, &corners);
                        let adder_v2 = add_vertex(v2, &corners);
                        vertices.push(
                            [ ((x as f64) + (adder_v0[0] as f64)/255.0)*step_size[0]
                            , ((y as f64) + (adder_v0[1] as f64)/255.0)*step_size[1]
                            , ((z as f64) + (adder_v0[2] as f64)/255.0)*step_size[2]
                            ]
                        );
                        vertices.push(
                            [ ((x as f64) + (adder_v1[0] as f64)/255.0)*step_size[0]
                            , ((y as f64) + (adder_v1[1] as f64)/255.0)*step_size[1]
                            , ((z as f64) + (adder_v1[2] as f64)/255.0)*step_size[2]
                            ]
                        );
                        vertices.push(
                            [ ((x as f64) + (adder_v2[0] as f64)/255.0)*step_size[0] + trans[0]
                            , ((y as f64) + (adder_v2[1] as f64)/255.0)*step_size[1] + trans[1]
                            , ((z as f64) + (adder_v2[2] as f64)/255.0)*step_size[2] + trans[2]
                            ]
                        );
                        //calculate and add normals
                        let diff1: [f64; 3] = [adder_v1[0] as f64 - adder_v0[0] as f64, adder_v1[1] as f64 - adder_v0[1] as f64, adder_v1[2] as f64 - adder_v0[2] as f64];
                        let diff2: [f64; 3] = [adder_v2[0] as f64 - adder_v0[0] as f64, adder_v2[1] as f64 - adder_v0[1] as f64, adder_v2[2] as f64 - adder_v0[2] as f64];
                        let normal: [f64; 3] = [ diff1[1] * diff2[2] - diff1[2] * diff2[1]
                                               , diff1[2] * diff2[0] - diff1[0] * diff2[2]
                                               , diff1[0] * diff2[1] - diff1[1] * diff2[0]
                                               ];
                        normals.push(normal);
                        normals.push(normal);
                        normals.push(normal);
                    }
                }
            }
        }
    }

    (vertices, normals) //return vertices and normals
}

fn add_vertex(v: u16, corners: &[i8; 8]) -> [u8; 3] {
    //get corner indecies and values for each vertex
    let ca = ((v >> 4) & 0x000F) as u8; //smaller corner index
    let cb = (v & 0x000F) as u8;        //larger corner index
    let cav = corners[ca as usize];     //smaller corner value
    let cbv = corners[cb as usize];     //larger corner value
    //compute interpolation value: q
    let q: u8 = 255 - ((255*(cav.abs() as usize)) / (((cbv as isize - cav as isize)).abs() as usize)) as u8;
    let axis = (ca ^ cb) & 0x07; //calculate edge axis (1 = shift by x, 2 = shift by y, 4 = shift by z)
    //calculate adder (what to add to cell origin point (0,0,0) to get to correct edge)
    let mut adder: [u8; 3] = [((ca >> 0) & 0x01)*255, ((ca >> 1) & 0x01)*255, ((ca >> 2) & 0x01)*255];
    if axis == 1{
        adder[0] = q;
    }
    else if axis == 2{
        adder[1] = q;
    }
    else if axis == 4{
        adder[2] = q;
    }
    adder
}

fn corners_to_index(corners: [i8; 8]) -> u8 {
      ((corners[0] as u8 >> 7) & 0x01)
    | ((corners[1] as u8 >> 6) & 0x02)
    | ((corners[2] as u8 >> 5) & 0x04) 
    | ((corners[3] as u8 >> 4) & 0x08) 
    | ((corners[4] as u8 >> 3) & 0x10) 
    | ((corners[5] as u8 >> 2) & 0x20) 
    | ((corners[6] as u8 >> 1) & 0x40) 
    | ((corners[7] as u8 >> 0) & 0x80) 
}

// fn main() {
//     let (vertices, normals) = 
//         marching_cubes(
//             Perlin::new()                       //noise function
//         ,   42                                  //noise seed
//         ,   [(1.0/5.1),(1.0/5.1),(1.0/5.1)]     //noise zoom level
//         ,   [0.0,0.0,0.0]                       //noise origin
//         ,   0.0                                 //noise threshold
//         ,   [1.0,1.0,1.0]                       //terrain resolution
//         ,   [10.0,10.0,10.0]                    //terrain size
//         ,   [0.0,0.0,0.0]                       //terrain translation
//         );

//     println!("{:?}", normals);
// }
