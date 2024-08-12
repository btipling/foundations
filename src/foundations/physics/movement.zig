start: math.vector.vec3,
step: physics.step,
direction: direction,

const movement = @This();

pub const direction = enum {
    none,
    forward,
    backward,
    left,
    right,
    up,
    down,
};

pub fn init(start: math.vector.vec3, t: f64, dir: direction) movement {
    return .{
        .step = .{
            .state = .{
                .position = 0,
                .velocity = 0,
            },
            .t = 0,
            .current_time = t,
        },
        .start = start,
        .direction = dir,
    };
}

const math = @import("../math/math.zig");
const physics = @import("physics.zig");
