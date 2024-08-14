program: u32,
vao: u32,
buffer: u32,
instance_type: mesh_instance,
wire_mesh: bool = false,
blend: bool = false,

linear_colorspace: bool = true,

pub const mesh_type = enum(usize) {
    array,
    element,
    instanced,
};

pub const mesh_instance = union(mesh_type) {
    array: array,
    element: element,
    instanced: instanced,
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

pub const instanced = struct {
    primitive: c.GLenum,
    format: c.GLenum,
    index_count: usize,
    ebo: u32,
    instances_count: usize,
};

const c = @import("../c.zig").c;
