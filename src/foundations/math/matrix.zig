// A column vector matrix
columns: [4]vector.vec4 = .{
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
},

const matrix = @This();

pub fn identity() matrix {
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

pub fn rotationX(angle: f32) matrix {
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

pub fn rotationY(angle: f32) matrix {
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

pub fn rotationZ(angle: f32) matrix {
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

pub fn scale(x: f32, y: f32, z: f32) matrix {
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

pub fn translate(x: f32, y: f32, z:f32) matrix {
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

pub fn elementAt(m: matrix, row: usize, column: usize) f32 {
    return m.columns[column][row];
}

test elementAt {
    const a_m: matrix = .{
        .columns = .{
            .{-3, 15, 12, 0},
            .{9, 0, 9, 0},
            .{5, -2, -7, 0},
            .{0, 0, 0, 1},
        },
    };
    try std.testing.expectEqual(9, elementAt(a_m, 0, 1));
    try std.testing.expectEqual(-7, elementAt(a_m, 2, 2));
    try std.testing.expectEqual(15, elementAt(a_m, 1, 0));
}

pub fn mxm(a: matrix, b: matrix) matrix {
    const bt = b.transpose();
    return .{
        .columns = .{
            .{
                vector.dotProduct(a[0], bt[0]),
                vector.dotProduct(a[0], bt[1]),
                vector.dotProduct(a[0], bt[2]),
                vector.dotProduct(a[0], bt[3]),
            },
            .{
                vector.dotProduct(a[1], bt[0]),
                vector.dotProduct(a[1], bt[1]),
                vector.dotProduct(a[1], bt[2]),
                vector.dotProduct(a[1], bt[3]),
            },
            .{
                vector.dotProduct(a[2], bt[0]),
                vector.dotProduct(a[2], bt[1]),
                vector.dotProduct(a[2], bt[2]),
                vector.dotProduct(a[2], bt[3]),
            },
            .{
                vector.dotProduct(a[3], bt[0]),
                vector.dotProduct(a[3], bt[1]),
                vector.dotProduct(a[3], bt[2]),
                vector.dotProduct(a[3], bt[3]),
            },
        },
    };
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
}

pub fn transpose(m: matrix) matrix {
    return .{
        .columns = .{
            .{
                elementAt(m, 0, 0),
                elementAt(m, 0, 1),
                elementAt(m, 0, 2),
                elementAt(m, 0, 3),
            },
            .{
                elementAt(m, 1, 0),
                elementAt(m, 1, 1),
                elementAt(m, 1, 2),
                elementAt(m, 1, 3),
            },
            .{
                elementAt(m, 2, 0),
                elementAt(m, 2, 1),
                elementAt(m, 2, 2),
                elementAt(m, 2, 3),
            },
            .{
                elementAt(m, 3, 0),
                elementAt(m, 3, 1),
                elementAt(m, 3, 2),
                elementAt(m, 3, 3),
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
