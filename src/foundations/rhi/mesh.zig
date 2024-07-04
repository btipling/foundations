program: u32,
vao: u32,
buffer: u32,
instance_type: mesh_instance,

linear_colorspace: bool = true,

pub const mesh_type = enum(usize) {
    array,
};

pub const mesh_instance = union(mesh_type) {
    array: array,
};

pub const array = struct {
    count: usize,
};
