pub const object_type = enum {
    point,
    triangle,
};

pub const object = union(object_type) {
    point: point,
    triangle: triangle,
};

pub const point = @import("object_point/object_point.zig");
pub const triangle = @import("object_triangle/object_triangle.zig");
