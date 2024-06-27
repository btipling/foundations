pub const object_type = enum {
    triangle,
    quad,
    cube,
};

pub const object = union(object_type) {
    triangle: triangle,
    quad: quad,
    cube: cube,
};

pub const triangle = @import("object_triangle/object_triangle.zig");
pub const quad = @import("object_quad/object_quad.zig");
pub const cube = @import("object_cube/object_cube.zig");
