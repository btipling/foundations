normal: vector.vec3,
offset: f32,
parameterized: vector.vec4,

const Plane = @This();

pub fn init(normal: vector.vec3, offset: f32) Plane {
    return .{
        .normal = normal,
        .offset = offset,
        .parameterized = .{ normal[0], normal[1], normal[3], offset },
    };
}

const vector = @import("vector.zig");
