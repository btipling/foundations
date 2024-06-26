pub const object_type = enum {
    point,
    triangle,
    quad,
};

pub const object = union(object_type) {
    point: point,
    triangle: triangle,
    quad: quad,
};

pub const point = @import("object_point/object_point.zig");
pub const triangle = @import("object_triangle/object_triangle.zig");
pub const quad = @import("object_quad/object_quad.zig");
pub const cube = @import("object_cube/object_cube.zig");
