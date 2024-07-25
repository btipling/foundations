pub fn xUpLeftHandedTo2D(v: vector.vec3) vector.vec2 {
    return .{ v[2], v[0] };
}

pub fn TwoDToXUpLeftHandedTo(v: vector.vec2) vector.vec3 {
    return .{ v[1], 0.0, v[0] };
}

const vector = @import("../vector.zig");
pub const circle = @import("circle.zig");
pub const sphere = @import("sphere.zig");
pub const plane = @import("plane.zig");
pub const line = @import("line.zig");
pub const triangle = @import("triangle.zig");
