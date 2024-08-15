pub const object_type = enum {
    triangle,
    quad,
    cube,
    circle,
    sphere,
    strip,
    parallelepiped,
};

pub const object = union(object_type) {
    triangle: Triangle,
    quad: Quad,
    cube: Cube,
    circle: Circle,
    sphere: Sphere,
    strip: Strip,
    parallelepiped: Parallelepiped,
};

pub const Triangle = @import("object_triangle/ObjectTriangle.zig");
pub const Quad = @import("object_quad/ObjectQuad.zig");
pub const Cube = @import("object_cube/ObjectCube.zig");
pub const Circle = @import("object_circle/ObjectCircle.zig");
pub const Sphere = @import("object_sphere/ObjectSphere.zig");
pub const Strip = @import("object_strip/ObjectStrip.zig");
pub const Parallelepiped = @import("object_parallelepiped/ObjectParallelepiped.zig");
