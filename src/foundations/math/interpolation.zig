pub fn hermiteCurve(t: f32, positions: []vector.vec4, tangents: []vector.vec4, times: []f32) vector.vec4 {
    // assert input is correct
    std.debug.assert(times.len == positions.len);
    std.debug.assert(tangents.len == positions.len);

    // bounds check
    if (t < times[0]) return positions[0];
    if (t > times[times.len - 1]) return positions[positions.len - 1];

    // determine u, positions and tangents
    var i: usize = 0;
    while (true) {
        if (t < times[i + 1]) break;
        if (i + 1 == times.len - 1) break;
        i += 1;
    }
    const t0: f32 = times[i];
    const t1: f32 = times[i + 1];
    const u: f32 = (t - t0) / (t1 - t0);
    const p0 = positions[i];
    const p1 = positions[i + 1];
    const pt0 = tangents[i];
    const pt1 = tangents[i + 1];

    // setup matrices
    const U: vector.vec4 = .{ u * u * u, u * u, u, 1 };
    const M = matrix.hermite_basis();
    const G: matrix = .{
        .columns = .{
            .{ p0[0], p1[0], pt0[0], pt1[0] },
            .{ p0[1], p1[1], pt0[1], pt1[1] },
            .{ p0[2], p1[2], pt0[2], pt1[2] },
            .{ p0[3], p1[3], pt0[3], pt1[3] },
        },
    };

    const m = matrix.transformMatrix(M, G);
    return matrix.preTransformVector(U, m);
}

pub fn linear(t: f32, positions: []vector.vec4, times: []f32) vector.vec4 {
    std.debug.assert(times.len == positions.len);
    if (t < times[0]) return positions[0];
    if (t > times[times.len - 1]) return positions[positions.len - 1];
    var i: usize = 0;
    while (true) {
        if (t < times[i + 1]) break;
        if (i + 1 == times.len - 1) break;
        i += 1;
    }
    const t0: f32 = times[i];
    const t1: f32 = times[i + 1];
    const u: f32 = (t - t0) / (t1 - t0);
    const p0 = positions[i];
    const p1 = positions[i + 1];
    return vector.add(vector.mul(1.0 - u, p0), vector.mul(u, p1));
}

pub fn slerp(p: rotation.Quat, q: rotation.Quat, u: f32) rotation.Quat {
    var pn = vector.normalize(p);
    const qn = vector.normalize(q);

    const angle: f32 = std.math.acos(vector.dotProduct(pn, qn));
    const cs = @cos(angle);
    if (float.equal(cs, 1.0, 0.001)) return lerp(pn, qn, u);
    if (cs <= 0) pn = vector.normalize(vector.negate(pn));
    const denominator: f32 = @sin(angle);

    const pt: f32 = (1.0 - u) * angle;
    const spt: f32 = @sin(pt);
    const sptp: rotation.Quat = vector.mul(spt, pn);

    const sqt: f32 = @sin(u * angle);
    const sqtq: rotation.Quat = vector.mul(sqt, qn);

    const numerator: rotation.Quat = vector.add(sptp, sqtq);

    return vector.normalize(vector.mul(1.0 / denominator, numerator));
}

const epsilon = 0.0001;

test slerp {
    const a_p: rotation.Quat = rotation.axisAngleToQuat(
        rotation.degreesToRadians(0),
        @as(vector.vec3, .{ 0, 0, 1 }),
    );
    const a_q: rotation.Quat = rotation.axisAngleToQuat(
        rotation.degreesToRadians(90.0),
        @as(vector.vec3, .{ 0, 0, 1 }),
    );
    const a_t: f32 = 0.5;
    const a_e: rotation.Quat = vector.normalize(rotation.axisAngleToQuat(
        rotation.degreesToRadians(45.0),
        @as(vector.vec3, .{ 0, 0, 1 }),
    ));
    const a_r = slerp(a_p, a_q, a_t);
    try std.testing.expect(float.equal(a_e[0], a_r[0], epsilon));
    try std.testing.expect(float.equal(a_e[1], a_r[1], epsilon));
    try std.testing.expect(float.equal(a_e[2], a_r[2], epsilon));
    try std.testing.expect(float.equal(a_e[3], a_r[3], epsilon));
}

pub fn piecewiseSlerp(orientations: []const rotation.Quat, times: []const f32, t: f32) rotation.Quat {
    std.debug.assert(times.len == orientations.len);
    if (t < times[0]) return orientations[0];
    if (t > times[times.len - 1]) return orientations[orientations.len - 1];
    var i: usize = 0;
    while (true) {
        if (t < times[i + 1]) break;
        if (i + 1 == times.len - 1) break;
        i += 1;
    }
    const t0: f32 = times[i];
    const t1: f32 = times[i + 1];
    const u: f32 = (t - t0) / (t1 - t0);
    const p: rotation.Quat = orientations[i];
    const q: rotation.Quat = orientations[i + 1];
    return slerp(p, q, u);
}

pub fn lerp(p: rotation.Quat, q: rotation.Quat, u: f32) rotation.Quat {
    const pn = vector.normalize(p);
    const qn = vector.normalize(q);

    return vector.add(vector.mul(1.0 - u, pn), vector.mul(u, qn));
}

pub fn piecewiseLerp(orientations: []const rotation.Quat, times: []const f32, t: f32) rotation.Quat {
    std.debug.assert(times.len == orientations.len);
    if (t < times[0]) return orientations[0];
    if (t > times[times.len - 1]) return orientations[orientations.len - 1];
    var i: usize = 0;
    while (true) {
        if (t < times[i + 1]) break;
        if (i + 1 == times.len - 1) break;
        i += 1;
    }
    const t0: f32 = times[i];
    const t1: f32 = times[i + 1];
    const u: f32 = (t - t0) / (t1 - t0);
    const p: rotation.Quat = orientations[i];
    const q: rotation.Quat = orientations[i + 1];
    return lerp(p, q, u);
}

const std = @import("std");
const vector = @import("vector.zig");
const float = @import("float.zig");
const matrix = @import("matrix.zig");
const rotation = @import("rotation.zig");
