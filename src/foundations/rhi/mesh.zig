program: u32,
vao: u32,
buffer: u32,
instance_type: mesh_instance,
wire_mesh: bool = false,

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
    primitive: c.GLenum,
    format: c.GLenum,
    count: usize,
    ebo: u32,
};

const c = @import("../c.zig").c;
