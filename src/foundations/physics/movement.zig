start: math.vector.vec3,
step: physics.step,

const movement = @This();

pub fn init(start: math.vector.vec3, t: f64) movement {
    return .{
        .step = .{
            .state = .{
                .position = 0,
                .velocity = 0,
            },
            .t = 0,
            .current_time = t,
            .max_time = 2,
        },
        .start = start,
    };
}

const math = @import("../math/math.zig");
const physics = @import("physics.zig");
