v0: vector.vec3,
v1: vector.vec3,
v2: vector.vec3,

const Triangle = @This();

pub fn vectorAt(self: Triangle, i: usize) vector.vec3 {
    return switch (i) {
        0 => self.v0,
        1 => self.v1,
        2 => self.v2,
        else => undefined,
    };
}

const vector = @import("../vector.zig");
