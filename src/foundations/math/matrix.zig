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
            vector.mul(k, m.columns[3]),
        },
    };
}

pub fn mxv(m: matrix, v: vector.vec4) vector.vec4 {
    return .{
        vector.dotProduct(m.columns[0], v),
        vector.dotProduct(m.columns[1], v),
        vector.dotProduct(m.columns[2], v),
        vector.dotProduct(m.columns[3], v),
    };
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

const vector = @import("vector.zig");
