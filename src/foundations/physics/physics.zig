const epsilon = 0.00001;

pub inline fn force(m: f32, a: f32) f32 {
    return m * a;
}

pub inline fn acceleration(f: f32, m: f32) f32 {
    if (math.float.equal(m, 0, epsilon)) return 0;
    return f / m;
}

pub inline fn accelerationOverTime(dv: f32, dt: f32) f32 {
    if (math.floatequal(dt, 0, epsilon)) return 0;
    return dv / dt;
}

pub inline fn velocityOverTim(dx: f32, dt: f32) f32 {
    if (math.floatequal(dt, 0, epsilon)) return 0;
    return dx / dt;
}

pub inline fn changeInPosition(velocity_: f32, dt: f32) f32 {
    return velocity_ * dt;
}

pub inline fn changeInVelocity(acceleration_: f32, dt: f32) f32 {
    return acceleration_ * dt;
}

pub fn springDampenerAcceleration(s: state, _: f64) f32 {
    const k: f32 = 15;
    const b: f32 = 0.1;
    return -k * s.position - b * s.velocity;
}

pub const state = struct {
    position: f32,
    velocity: f32,
};

pub const derivative = struct {
    dx: f32 = 0,
    dv: f32 = 0,
};

pub fn evaluate(initial: state, t: f64, dt: f64, der: derivative) derivative {
    const dt_: f32 = @floatCast(dt);
    const s: state = .{
        .position = initial.position + der.dx * dt_,
        .velocity = initial.velocity + der.dv * dt_,
    };
    return .{
        .dx = s.velocity,
        .dv = springDampenerAcceleration(s, t + dt),
    };
}

pub fn integrate(s: state, t: f64, dt: f64) state {
    const a: derivative = evaluate(s, t, 0, .{});
    const b: derivative = evaluate(s, t, dt * 0.5, a);
    const c: derivative = evaluate(s, t, dt * 0.5, b);
    const d: derivative = evaluate(s, t, dt, c);
    const dt_: f32 = @floatCast(dt);

    const dxdt: f32 = 1.0 / 6.0 * (a.dx + 2.0 * (b.dx + c.dx) + d.dx);
    const dvdt: f32 = 1.0 / 6.0 * (a.dv + 2.0 * (b.dv + c.dv) + d.dv);

    return .{
        .position = s.position + dxdt * dt_,
        .velocity = s.velocity + dvdt * dt_,
    };
}

pub const step = struct {
    t: f64,
    current_time: f64,
    state: state,
};

pub fn timestep(s: step, new_time: f64) step {
    const frame_time = new_time - s.current_time;
    return .{
        .t = s.t + frame_time,
        .state = integrate(s.state, s.t, frame_time),
        .current_time = new_time,
    };
}

const math = @import("../math/math.zig");
