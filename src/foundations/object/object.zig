pub const object_type = enum {
    norender,
    triangle,
    quad,
    cube,
    circle,
    sphere,
    strip,
    parallelepiped,
    cylinder,
    cone,
    instanced_triangle,
};

pub const object = union(object_type) {
    norender: NoRender,
    triangle: Triangle,
    quad: Quad,
    cube: Cube,
    circle: Circle,
    sphere: Sphere,
    strip: Strip,
    parallelepiped: Parallelepiped,
    cylinder: Cylinder,
    cone: Cone,
    instanced_triangle: InstancedTriangle,
};

pub const NoRender = @import("object_no_render/ObjectNoRender.zig");
pub const Triangle = @import("object_triangle/ObjectTriangle.zig");
pub const Quad = @import("object_quad/ObjectQuad.zig");
pub const Cube = @import("object_cube/ObjectCube.zig");
pub const Circle = @import("object_circle/ObjectCircle.zig");
pub const Sphere = @import("object_sphere/ObjectSphere.zig");
pub const Strip = @import("object_strip/ObjectStrip.zig");
pub const Parallelepiped = @import("object_parallelepiped/ObjectParallelepiped.zig");
pub const Cylinder = @import("object_cylinder/ObjectCylinder.zig");
pub const Cone = @import("object_cone/ObjectCone.zig");
pub const InstancedTriangle = @import("object_instanced_triangle/ObjectInstancedTriangle.zig");
