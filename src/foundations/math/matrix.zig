// A column vector matrix
columns: [4]vector.vec4 = .{
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
},

const matrix = @This();

pub inline fn identity() matrix {
    return .{
        .columns = .{
            // zig fmt: off
            .{  1,  0,  0,  0 },
            .{  0,  1,  0,  0 },
            .{  0,  0,  1,  0 },
            .{  0,  0,  0,  1 },
            // zig fmt: on
        },
    };
}

pub inline fn rotationX(angle: f32) matrix {
    return .{
        .columns = .{
            // zig fmt: off
            .{          1,           0,             0,      0 },
            .{          0,  @cos(angle),  @sin(angle),      0 },
            .{          0, -@sin(angle),  @cos(angle),      0 },
            .{          0,           0,             0,      1 },
            // zig fmt: on
        },
    };
}

pub inline fn rotationY(angle: f32) matrix {
    return .{
        .columns = .{
            // zig fmt: off
            .{ @cos(angle),         0, -@sin(angle),        0 },
            .{           0,         1,            0,        0 },
            .{ @sin(angle),         0,  @cos(angle),        0 },
            .{           0,         0,            0,        1 },
            // zig fmt: on
        },
    };
}

pub inline fn rotationZ(angle: f32) matrix {
    return .{
        .columns = .{
            // zig fmt: off
            .{  @cos(angle),  @sin(angle),        0,      0 },
            .{ -@sin(angle),  @cos(angle),        0,      0 },
            .{             0,           0,        1,      0 },
            .{             0,           0,        0,      1 },
            // zig fmt: on
        },
    };
}

pub inline fn scale(x: f32, y: f32, z: f32) matrix {
    return .{
        .columns = .{
            // zig fmt: off
            .{  x,  0,  0,  0 },
            .{  0,  y,  0,  0 },
            .{  0,  0,  z,  0 },
            .{  0,  0,  0,  1 },
            // zig fmt: on
        },
    };
}

pub inline fn translate(x: f32, y: f32, z:f32) matrix {
    return .{
        .columns = .{
            // zig fmt: off
            .{  0,  0,  0,  x },
            .{  0,  0,  0,  y },
            .{  0,  0,  0,  z },
            .{  0,  0,  0,  1 },
            // zig fmt: on
        },
    };
}

pub inline fn at(m: matrix, row: usize, column: usize) f32 {
    return m.columns[column][row];
}

test at {
    const a_m: matrix = .{
        .columns = .{
            .{-3, 15, 12, 0},
            .{9, 0, 9, 0},
            .{5, -2, -7, 0},
            .{0, 0, 0, 1},
        },
    };
    try std.testing.expectEqual(9, at(a_m, 0, 1));
    try std.testing.expectEqual(-7, at(a_m, 2, 2));
    try std.testing.expectEqual(15, at(a_m, 1, 0));
}

pub fn mxm(a: matrix, b: matrix) matrix {
    const amt = transpose(a);
    var rv: matrix = undefined;
    comptime var column: usize = 0;
    inline while (column < 4) : (column += 1) {
        rv.columns[column] =  .{
            vector.dotProduct(amt.columns[0], b.columns[column]),
            vector.dotProduct(amt.columns[1], b.columns[column]),
            vector.dotProduct(amt.columns[2], b.columns[column]),
            vector.dotProduct(amt.columns[3], b.columns[column]),
        };
    }
    return rv;
}

test mxm {
    const a_ma: matrix = .{
        .columns = .{
            .{ 1, 2, 3, 0 },
            .{ 4, 5, 6, 0 },
            .{ 7, 8, 9, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const a_mb = identity();
    const a_r = mxm(a_ma, a_mb);
    try std.testing.expectEqual(a_ma.columns[0], a_r.columns[0]);
    try std.testing.expectEqual(a_ma.columns[1], a_r.columns[1]);
    try std.testing.expectEqual(a_ma.columns[2], a_r.columns[2]);
    try std.testing.expectEqual(a_ma.columns[3], a_r.columns[3]);

    const b_ma: matrix = .{
        .columns = .{
            .{ 3, 1, 0, 0 },
            .{ -10, 7, 5, 0 },
            .{ 2, 9, -1, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const b_mb: matrix = .{
        .columns = .{
            .{ 1, 0, 0, 0 },
            .{ 0, 0, 0, 0 },
            .{ 0, 0, 0, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const b_e: matrix = .{
        .columns = .{
            .{ 3, 1, 0, 0 },
            .{ 0, 0, 0, 0 },
            .{ 0, 0, 0, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const b_r = mxm(b_ma, b_mb);
    try std.testing.expectEqual(b_e.columns[0], b_r.columns[0]);
    try std.testing.expectEqual(b_e.columns[1], b_r.columns[1]);
    try std.testing.expectEqual(b_e.columns[2], b_r.columns[2]);
    try std.testing.expectEqual(b_e.columns[3], b_r.columns[3]);

    const c_ma: matrix = .{
        .columns = .{
            .{ 3, 1, 0, 0 },
            .{ -10, 7, 5, 0 },
            .{ 2, 9, -1, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const c_mb: matrix = .{
        .columns = .{
            .{ 8, 4, 7, 0 },
            .{ 2, 1, 5, 0 },
            .{ 6, -3, 9, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const c_e: matrix = .{
        .columns = .{
            .{ -2, 99, 13, 0 },
            .{ 6, 54, 0, 0 },
            .{ 66, 66, -24, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const c_r = mxm(c_ma, c_mb);
    try std.testing.expectEqual(c_e.columns[0], c_r.columns[0]);
    try std.testing.expectEqual(c_e.columns[1], c_r.columns[1]);
    try std.testing.expectEqual(c_e.columns[2], c_r.columns[2]);
    try std.testing.expectEqual(c_e.columns[3], c_r.columns[3]);

    // Test associative property
    const d_ma: matrix = .{
        .columns = .{
            .{ 0.5, 1, 0, 0 },
            .{ 0.5, 0.5, 0.25, 0 },
            .{ 0.25, 0.5, -1, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const d_mb: matrix = .{
        .columns = .{
            .{ 0.25, 0.25, 0.25, 0 },
            .{ 0.25, 1, 0.5, 0 },
            .{ 0.5, -0.25, 1, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const d_mc: matrix = .{
        .columns = .{
            .{ 1, 0.25, 0.5, 0 },
            .{ 0.5, 1, 0.25, 0 },
            .{ 0.5, 1, 0.25, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const d_e: matrix = .{
        .columns = .{
            .{ 0.6875, 1.1875, -0.78125, 0 },
            .{ 1, 1.46875, -0.609375, 0 },
            .{ 1, 1.46875, -0.609375, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const d_r1 = mxm(d_ma, mxm(d_mb, d_mc));
    const d_r2 = mxm(mxm(d_ma, d_mb), d_mc);
    try std.testing.expectEqual(d_e.columns[0], d_r1.columns[0]);
    try std.testing.expectEqual(d_e.columns[1], d_r1.columns[1]);
    try std.testing.expectEqual(d_e.columns[2], d_r1.columns[2]);
    try std.testing.expectEqual(d_e.columns[3], d_r1.columns[3]);
    try std.testing.expectEqual(d_r1, d_r2);

    // (AB)ᵀ = BᵀAᵀ
    const e_ma: matrix = .{
        .columns = .{
            .{ 3, 1, 0, 0 },
            .{ -10, 7, 5, 0 },
            .{ 2, 9, -1, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const e_mat = transpose(e_ma);
    const e_mb: matrix = .{
        .columns = .{
            .{ 1, 0.25, 0.5, 0 },
            .{ 0.5, 1, 0.25, 0 },
            .{ 0.5, 1, 0.25, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const e_mbt = transpose(e_mb);
    const e_abt = transpose(mxm(e_ma, e_mb));
    const e_btat = mxm(e_mbt, e_mat);
    try std.testing.expectEqual(e_abt.columns[0], e_btat.columns[0]);
    try std.testing.expectEqual(e_abt.columns[1], e_btat.columns[1]);
    try std.testing.expectEqual(e_abt.columns[2], e_btat.columns[2]);
    try std.testing.expectEqual(e_abt.columns[3], e_btat.columns[3]);
}

pub fn sxm(k: f32, m: matrix) matrix {
    return .{
        .columns = .{
            vector.mul(k, m.columns[0]),
            vector.mul(k, m.columns[1]),
            vector.mul(k, m.columns[2]),
            m.columns[3],
        },
    };
}

test sxm {
    const a_m: matrix = .{
        .columns = .{
            .{ 1, 2, 3, 0 },
            .{ 4, 5, 6, 0 },
            .{ 7, 8, 9, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const a_e: matrix = .{
        .columns = .{
            .{ 5, 10, 15, 0 },
            .{ 20, 25, 30, 0 },
            .{ 35, 40, 45, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const a_r = sxm(5, a_m);
    try std.testing.expectEqual(a_e.columns[0], a_r.columns[0]);
    try std.testing.expectEqual(a_e.columns[1], a_r.columns[1]);
    try std.testing.expectEqual(a_e.columns[2], a_r.columns[2]);
    try std.testing.expectEqual(a_e.columns[3], a_r.columns[3]);
}

pub fn mxv(m: matrix, v: vector.vec4) vector.vec4 {
    return .{
        vector.dotProduct(m.columns[0], v),
        vector.dotProduct(m.columns[1], v),
        vector.dotProduct(m.columns[2], v),
        vector.dotProduct(m.columns[3], v),
    };
}

test mxv {
    const a_m = identity();
    const a_v = .{-3, 2, 1, 1};
    const a_r = mxv(a_m, a_v);
    try std.testing.expectEqual(a_v, a_r);

    const b_m = scale(10, 1, 1);
    const b_v = .{1, 1, 1, 1};
    const b_e = .{10, 1, 1, 1};
    const b_r = mxv(b_m, b_v);
    try std.testing.expectEqual(b_e, b_r);

    const c_m = scale(20, -3, 5);
    const c_v = .{-3, 2, 9, 1};
    const c_e = .{-60, -6, 45, 1};
    const c_r = mxv(c_m, c_v);
    try std.testing.expectEqual(c_e, c_r);
}

pub inline fn transpose(m: matrix) matrix {
    return .{
        .columns = .{
            .{
                at(m, 0, 0),
                at(m, 0, 1),
                at(m, 0, 2),
                at(m, 0, 3),
            },
            .{
                at(m, 1, 0),
                at(m, 1, 1),
                at(m, 1, 2),
                at(m, 1, 3),
            },
            .{
                at(m, 2, 0),
                at(m, 2, 1),
                at(m, 2, 2),
                at(m, 2, 3),
            },
            .{
                at(m, 3, 0),
                at(m, 3, 1),
                at(m, 3, 2),
                at(m, 3, 3),
            },
        },
    };
}

test transpose {
    const a_m: matrix = .{
        .columns = .{
            .{1, 10, 20, 0},
            .{2, 5, 40, 0},
            .{3, 4, 15, 0},
            .{0, 0, 0, 1},
        },
    };
    const a_e: matrix = .{
        .columns = .{
            .{1, 2, 3, 0},
            .{10, 5, 4, 0},
            .{20, 40, 15, 0},
            .{0, 0, 0, 1},
        },
    };
    const a_r = transpose(a_m);
    try std.testing.expectEqual(a_e.columns[0], a_r.columns[0]);
    try std.testing.expectEqual(a_e.columns[1], a_r.columns[1]);
    try std.testing.expectEqual(a_e.columns[2], a_r.columns[2]);
    try std.testing.expectEqual(a_e.columns[3], a_r.columns[3]);
}

pub fn orthonormalize() matrix {
    @compileError("not yet implemented, see page 32 in book 1 foundations of game engine dev");
}

pub fn determinant3D() matrix {
    @compileError("not yet implemented, see page 33-34 in book 1 foundatoins of game engine dev");
}

pub fn determinant4D() matrix {
    @compileError("not yet implemented, see page 33-34 in book 1 foundatoins of game engine dev");
}

pub fn invert3D() matrix {
    @compileError("not yet implemented, see page 33-34 in book 1 foundatoins of game engine dev");
}

pub fn invert4D() matrix {
    @compileError("not yet implemented, see page 33-34 in book 1 foundatoins of game engine dev");
}

const std = @import("std");
const vector = @import("vector.zig");
