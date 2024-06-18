pub const object_type = enum {
    point,
    triangle,
};

pub const object = union(object_type) {
    point: point,
    triangle: triangle,
};

pub const point = @import("point/point.zig");
pub const triangle = @import("triangle/triangle.zig");
