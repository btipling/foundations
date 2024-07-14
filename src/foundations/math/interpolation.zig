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
    return matrix.preTransformVector(U, matrix.transformMatrix(M, G));
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

const std = @import("std");
const vector = @import("vector.zig");
const matrix = @import("matrix.zig");
