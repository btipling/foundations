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
    const p1 = positions[i];
    const p2 = positions[i + 1];
    return vector.add(vector.mul(1.0 - u, p1), vector.mul(u, p2));
}

const std = @import("std");
const vector = @import("vector.zig");
const matrix = @import("matrix.zig");
