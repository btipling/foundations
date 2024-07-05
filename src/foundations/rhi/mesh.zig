program: u32,
vao: u32,
buffer: u32,
instance_type: mesh_instance,

linear_colorspace: bool = true,

pub const mesh_type = enum(usize) {
    array,
    element,
};

pub const mesh_instance = union(mesh_type) {
    array: array,
    element: element,
};

pub const array = struct {
    count: usize,
};

pub const element = struct {
    count: usize,
};
