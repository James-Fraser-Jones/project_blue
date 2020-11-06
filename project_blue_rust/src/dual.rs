use noise::{Perlin, NoiseFn, Seedable};
//use std::ops::{Index,IndexMut};

// struct Lattice<T> {
//     vector: Vec<T>
// }

// impl<T> Lattice<T> {
//     fn new(vector: Vec<T>) -> Lattice<T> {
//         Lattice{vector}
//     }
// }

// impl<T> Index<(usize, usize, usize)> for Lattice<T> {
//     type Output = T;

//     fn index(&self, (x,y,z): (usize, usize, usize)) -> &Self::Output {
//         let index = 
//     }
// }

pub enum Octree<T> {
    Leaf (T),
    Node ([Box<Octree<T>>; 8])
}

// fn build_octree() -> Octree<bool> {

// }

// fn build_octree_r(octree: Octree<bool>, sdf_3d: fn(f64, f64, f64) -> f64, max_depth: usize) -> Octree<bool> {
//     if (max_depth == 0){
//         octree
//     }
//     else {
//         //read samples at corners, if any signs change, subdivide, else terminate
//     }
// }

fn get_noise_samples_3d<N>(size: usize, noise: N, seed: u32, zoom: f64) -> Vec<Vec<Vec<f64>>>
    where N: NoiseFn<[f64;3]> + Seedable + Copy
{
    noise.set_seed(seed);
    let mut sample_cube = Vec::with_capacity(size);
    for z in 0..size {
        let mut sample_square = Vec::with_capacity(size);
        for y in 0..size {
            let mut sample_line = Vec::with_capacity(size);
            for x in 0..size {
                sample_line[x] = noise.get([x as f64 / zoom, y as f64 / zoom, z as f64 / zoom])
            }
            sample_square[y] = sample_line
        }
        sample_cube[z] = sample_square
    }
    sample_cube
}

struct HermiteData {
    point: f64,
    normal: (f64, f64, f64)
}

//start with a signed distance function, this can be calculated from a mesh or voxel grid, or given by a noise function or geometric shape function

//then we create an octree which stores in its leaves the samples of that signed distance function at the corners of that sub-cube,
//leaves themselves are found by checking samples at higher levels of the octree
//this happens recursively down to a max depth 
//we need to make sure that we re-use existing samples as we recurse since this reduces the number of samples we have to make by 1/4
//regarding sign change, either <= 0 or >= 0 is used

//using this octree, we then convert the eight sample corners in each of these leaves into "Hermite Data"
//this data contains the intersection points of the surface along the edges which have a sign change
//the intersection points can be approximated using linear interpolation of the samples at the corners (i think)
//the data also contains the normalized normal vectors of the surface at those intersection points
//the normals are approximated using standard gradient calculation around the point with a tiny margin

//using this data, we can store a QEF for each leaf, based on the hermite data and stored using QR decomposition

//we can then use singular value decomposition to solve the quadratic error function for the hermite data in each leaf 
//(whilst ensuring that the solution is indeed inside the space defined by the leaf)
//this produces a single point of best fit of the surface inside each leaf cell

//we then attempt to do some simplification of the tree by collapsing 8? 2? adjacent leaves together when their respective best fit points can be
//adequately (acording to some threshold) replaced with a single point inside the parent node

//we then recurse down through the octree using several mututally recusive functions designed to find all possible instances of four adjacent
//leaf cells sharing an edge with a sign change, at which point a quad is drawn between the points in all four cells, with the face dependant on the
//direction of the sign change


//surface nets: like dual contouring but simpler
//