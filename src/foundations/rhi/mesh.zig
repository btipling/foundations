program: u32 = 0,
vao: u32 = 0,
buffer: u32 = 0,
instance_type: mesh_instance,
wire_mesh: bool = false,
blend: bool = false,
cull: bool = true,

linear_colorspace: bool = true,

// for when generating a shadomap
shadowmap_program: u32 = 0,
gen_shadowmap: bool = false,

pub const mesh_type = enum(usize) {
    array,
    element,
    instanced,
    norender,
};

pub const mesh_instance = union(mesh_type) {
    array: array,
    element: element,
    instanced: instanced,
    norender: void,
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
