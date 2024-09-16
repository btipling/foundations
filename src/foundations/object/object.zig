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
    pyramid,
    torus,
    obj,
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
    pyramid: Pyramid,
    torus: Torus,
    obj: Obj,
};

pub const NoRender = @import("ObjectNoRender.zig");
pub const Triangle = @import("ObjectTriangle.zig");
pub const Quad = @import("ObjectQuad.zig");
pub const Cube = @import("ObjectCube.zig");
pub const Circle = @import("ObjectCircle.zig");
pub const Sphere = @import("ObjectSphere.zig");
pub const Strip = @import("ObjectStrip.zig");
pub const Parallelepiped = @import("ObjectParallelepiped.zig");
pub const Cylinder = @import("ObjectCylinder.zig");
pub const Cone = @import("ObjectCone.zig");
pub const InstancedTriangle = @import("ObjectInstancedTriangle.zig");
pub const Pyramid = @import("ObjectPyramid.zig");
pub const Torus = @import("ObjectTorus.zig");
pub const Obj = @import("ObjectObj.zig");
