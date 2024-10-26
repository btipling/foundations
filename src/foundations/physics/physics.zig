const epsilon = 0.00001;

pub fn force(m: f32, a: f32) f32 {
    return m * a;
}

pub fn acceleration(f: f32, m: f32) f32 {
    if (math.float.equal(m, 0, epsilon)) return 0;
    return f / m;
}

pub fn accelerationOverTime(dv: f32, dt: f32) f32 {
    if (math.floatequal(dt, 0, epsilon)) return 0;
    return dv / dt;
}

pub fn velocityOverTime(dx: f32, dt: f32) f32 {
    if (math.floatequal(dt, 0, epsilon)) return 0;
    return dx / dt;
}

pub fn changeInPosition(velocity_: f32, dt: f32) f32 {
    return velocity_ * dt;
}

pub fn changeInVelocity(acceleration_: f32, dt: f32) f32 {
    return acceleration_ * dt;
}

pub const SpringDampener = struct {
    const Self = @This();
    pub fn acceleration(_: Self, s: state, _: f64) f32 {
        const k: f32 = 15;
        const b: f32 = 0.1;
        return -k * s.position - b * s.velocity;
    }
};

pub const SmoothDeceleration = struct {
    omega: f32 = 16.0,
    const Self = @This();
    pub fn acceleration(self: Self, s: state, _: f64) f32 {
        return -2.0 * self.omega * s.velocity - self.omega * self.omega * s.position;
    }
};

pub const state = struct {
    position: f32,
    velocity: f32,
};

pub const derivative = struct {
    dx: f32 = 0,
    dv: f32 = 0,
};

pub fn Integrator(comptime T: type) type {
    return struct {
        const Self = @This();
        accelerator: T,

        pub fn init(acc: T) Self {
            return .{
                .accelerator = acc,
            };
        }

        pub fn evaluate(self: Self, initial: state, t: f64, dt: f64, der: derivative) derivative {
            const dt_: f32 = @floatCast(dt);
            const s: state = .{
                .position = initial.position + der.dx * dt_,
                .velocity = initial.velocity + der.dv * dt_,
            };
            return .{
                .dx = s.velocity,
                .dv = self.accelerator.acceleration(s, t + dt),
            };
        }

        pub fn integrate(self: Self, s: state, t: f64, dt: f64) state {
            const a: derivative = self.evaluate(s, t, 0, .{});
            const b: derivative = self.evaluate(s, t, dt * 0.5, a);
            const c: derivative = self.evaluate(s, t, dt * 0.5, b);
            const d: derivative = self.evaluate(s, t, dt, c);
            const dt_: f32 = @floatCast(dt);

            const dxdt: f32 = 1.0 / 6.0 * (a.dx + 2.0 * (b.dx + c.dx) + d.dx);
            const dvdt: f32 = 1.0 / 6.0 * (a.dv + 2.0 * (b.dv + c.dv) + d.dv);

            return .{
                .position = s.position + dxdt * dt_,
                .velocity = s.velocity + dvdt * dt_,
            };
        }

        pub fn timestep(self: Self, s: step, new_time: f64) step {
            var t: f64 = s.t;
            const dt: f64 = 1.0 / 60.0;
            var frame_time = new_time - s.current_time;

            var st: state = undefined;
            while (frame_time > 0) {
                const delta_time: f64 = @min(frame_time, dt);
                st = self.integrate(s.state, s.t, delta_time);
                frame_time -= delta_time;
                t += delta_time;
            }

            const rv: step = .{
                .t = t,
                .state = st,
                .current_time = new_time,
            };
            return rv;
        }
    };
}

pub const step = struct {
    t: f64,
    current_time: f64,
    state: state,

    pub fn debug(self: step) void {
        std.debug.print("t: {d} current_time: {d} position: {d} velocity: {d}\n", .{
            self.t,
            self.current_time,
            self.state.position,
            self.state.velocity,
        });
    }
};

const std = @import("std");
const math = @import("../math/math.zig");
pub const movement = @import("movement.zig");
pub const camera = @import("camera.zig");
