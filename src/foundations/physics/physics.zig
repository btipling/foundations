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

pub const time = struct {
    t: f32 = 0.0,
    dt: f32 = 1.0,
};

pub const object = struct {
    velocity: f32 = 0,
    position: f32 = 0,
    force: f32 = 10,
    mass: f32 = 1,
};

const math = @import("../math/math.zig");
