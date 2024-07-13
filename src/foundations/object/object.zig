pub const object_type = enum {
    triangle,
    quad,
    cube,
    circle,
    sphere,
    strip,
};

pub const object = union(object_type) {
    triangle: triangle,
    quad: quad,
    cube: cube,
    circle: circle,
    sphere: sphere,
    strip: strip,
};

pub const triangle = @import("object_triangle/object_triangle.zig");
pub const quad = @import("object_quad/object_quad.zig");
pub const cube = @import("object_cube/object_cube.zig");
pub const circle = @import("object_circle/object_circle.zig");
pub const sphere = @import("object_sphere/object_sphere.zig");
pub const strip = @import("object_strip/object_strip.zig");
