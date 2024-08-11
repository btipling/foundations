pub fn xUpLeftHandedTo2D(v: anytype) vector.vec2 {
    return .{ v[2], v[0] };
}

pub fn TwoDToXUpLeftHandedTo(v: vector.vec2) vector.vec4 {
    return .{ v[1], 0.0, v[0], 1.0 };
}

const vector = @import("../vector.zig");
pub const Circle = @import("Circle.zig");
pub const Sphere = @import("Sphere.zig");
pub const Plane = @import("Plane.zig");
pub const Line = @import("Line.zig");
pub const Triangle = @import("Triangle.zig");
pub const Parallelepiped = @import("Parallelepiped.zig");
