// A column vector matrix
columns: [4]vector.vec4 = .{
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
},

const matrix = @This();

pub inline fn identity() matrix {
    // zig fmt: off
    return .{
        .columns = .{
            .{  1,  0,  0,  0 },
            .{  0,  1,  0,  0 },
            .{  0,  0,  1,  0 },
            .{  0,  0,  0,  1 },
        },
    };
    // zig fmt: on
}

pub inline fn rotationX(angle: f32) matrix {
    // zig fmt: off
    return .{
        .columns = .{
            .{          1,           0,             0,      0 },
            .{          0,  @cos(angle),  @sin(angle),      0 },
            .{          0, -@sin(angle),  @cos(angle),      0 },
            .{          0,           0,             0,      1 },
        },
    };
    // zig fmt: on
}

pub inline fn rotationY(angle: f32) matrix {
    // zig fmt: off
    return .{
        .columns = .{
            .{ @cos(angle),         0, -@sin(angle),        0 },
            .{           0,         1,            0,        0 },
            .{ @sin(angle),         0,  @cos(angle),        0 },
            .{           0,         0,            0,        1 },
        },
    };
    // zig fmt: on
}

pub inline fn rotationZ(angle: f32) matrix {
    // zig fmt: off
    return .{
        .columns = .{
            .{  @cos(angle),  @sin(angle),        0,      0 },
            .{ -@sin(angle),  @cos(angle),        0,      0 },
            .{             0,           0,        1,      0 },
            .{             0,           0,        0,      1 },
        },
    };
    // zig fmt: on
}

pub inline fn scale(x: f32, y: f32, z: f32) matrix {
    // zig fmt: off
    return .{
        .columns = .{
            .{  x,  0,  0,  0 },
            .{  0,  y,  0,  0 },
            .{  0,  0,  z,  0 },
            .{  0,  0,  0,  1 },
        },
    };
    // zig fmt: on
}

pub inline fn translate(x: f32, y: f32, z: f32) matrix {
    // zig fmt: off
    return .{
        .columns = .{
            .{  1,  0,  0,  0 },
            .{  0,  1,  0,  0 },
            .{  0,  0,  1,  0 },
            .{  x,  y,  z,  1 },
        },
    };
    // zig fmt: on
}

pub inline fn leftHandedXUpToNDC() matrix {
    // zig fmt: off
    return .{
        .columns = .{
            .{  0,  1,  0,  0 },
            .{  0,  0,  1,  0 },
            .{  1,  0,  0,  0 },
            .{  0,  0,  0,  1 },
        },
    };
    // zig fmt: on
}

pub inline fn array(m: matrix) [16]f32 {
    var rv: [16]f32 = undefined;
    @memcpy(rv[0..4], @as([4]f32, m.columns[0])[0..]);
    @memcpy(rv[4..8], @as([4]f32, m.columns[1])[0..]);
    @memcpy(rv[8..12], @as([4]f32, m.columns[2])[0..]);
    @memcpy(rv[12..16], @as([4]f32, m.columns[3])[0..]);
    return rv;
}

pub inline fn at(m: matrix, row: usize, column: usize) f32 {
    return m.columns[column][row];
}

test at {
    const a_m: matrix = .{
        .columns = .{
            .{ -3, 15, 12, 0 },
            .{ 9, 0, 9, 0 },
            .{ 5, -2, -7, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    try std.testing.expectEqual(9, at(a_m, 0, 1));
    try std.testing.expectEqual(-7, at(a_m, 2, 2));
    try std.testing.expectEqual(15, at(a_m, 1, 0));
}

pub fn transformMatrix(a: matrix, b: matrix) matrix {
    const amt = transpose(a);
    var rv: matrix = undefined;
    comptime var column: usize = 0;
    inline while (column < 4) : (column += 1) {
        rv.columns[column] = .{
            vector.dotProduct(amt.columns[0], b.columns[column]),
            vector.dotProduct(amt.columns[1], b.columns[column]),
            vector.dotProduct(amt.columns[2], b.columns[column]),
            vector.dotProduct(amt.columns[3], b.columns[column]),
        };
    }
    return rv;
}

test transformMatrix {
    const a_ma: matrix = .{
        .columns = .{
            .{ 1, 2, 3, 0 },
            .{ 4, 5, 6, 0 },
            .{ 7, 8, 9, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const a_mb = identity();
    const a_r = transformMatrix(a_ma, a_mb);
    try std.testing.expectEqual(a_ma, a_r);

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
    const b_r = transformMatrix(b_ma, b_mb);
    try std.testing.expectEqual(b_e, b_r);

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
    const c_r = transformMatrix(c_ma, c_mb);
    try std.testing.expectEqual(c_e, c_r);

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
    const d_r1 = transformMatrix(d_ma, transformMatrix(d_mb, d_mc));
    const d_r2 = transformMatrix(transformMatrix(d_ma, d_mb), d_mc);
    try std.testing.expectEqual(d_e, d_r1);
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
    const e_abt = transpose(transformMatrix(e_ma, e_mb));
    const e_btat = transformMatrix(e_mbt, e_mat);
    try std.testing.expectEqual(e_abt, e_btat);
}

pub fn scaleMatrix(k: f32, m: matrix) matrix {
    return .{
        .columns = .{
            vector.mul(k, m.columns[0]),
            vector.mul(k, m.columns[1]),
            vector.mul(k, m.columns[2]),
            m.columns[3],
        },
    };
}

test scaleMatrix {
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
    const a_r = scaleMatrix(5, a_m);
    try std.testing.expectEqual(a_e, a_r);
}

pub fn transformVector(m: matrix, v: vector.vec4) vector.vec4 {
    const mt = transpose(m);
    return .{
        vector.dotProduct(mt.columns[0], v),
        vector.dotProduct(mt.columns[1], v),
        vector.dotProduct(mt.columns[2], v),
        vector.dotProduct(mt.columns[3], v),
    };
}

test transformVector {
    const a_m = identity();
    const a_v = .{ -3, 2, 1, 1 };
    const a_r = transformVector(a_m, a_v);
    try std.testing.expectEqual(a_v, a_r);

    const b_m = scale(10, 1, 1);
    const b_v = .{ 1, 1, 1, 1 };
    const b_e = .{ 10, 1, 1, 1 };
    const b_r = transformVector(b_m, b_v);
    try std.testing.expectEqual(b_e, b_r);

    const c_m = scale(20, -3, 5);
    const c_v = .{ -3, 2, 9, 1 };
    const c_e = .{ -60, -6, 45, 1 };
    const c_r = transformVector(c_m, c_v);
    try std.testing.expectEqual(c_e, c_r);

    const d_m: matrix = .{
        .columns = .{
            .{ 8, 4, 7, 0 },
            .{ 2, 1, 5, 0 },
            .{ 6, -3, 9, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const d_v = .{ -3, 2, 9, 1 };
    const d_e = .{ 34, -37, 70, 1 };
    const d_r = transformVector(d_m, d_v);
    try std.testing.expectEqual(d_e, d_r);
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
            .{ 1, 10, 20, 0 },
            .{ 2, 5, 40, 0 },
            .{ 3, 4, 15, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const a_e: matrix = .{
        .columns = .{
            .{ 1, 2, 3, 0 },
            .{ 10, 5, 4, 0 },
            .{ 20, 40, 15, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const a_r = transpose(a_m);
    try std.testing.expectEqual(a_e, a_r);
}

pub fn determinant(m: matrix) f32 {
    // det (M) = (n-1 ∑ j=0) Mₖⱼ (-1)ᵏ⁺ʲ|M(not(ₖⱼ))|
    // k = 0
    const rv1: f32 = at(m, 0, 0) * (at(m, 1, 1) * at(m, 2, 2) - at(m, 1, 2) * at(m, 2, 1)); // j = 0
    const rv2: f32 = at(m, 0, 1) * (at(m, 1, 2) * at(m, 2, 0) - at(m, 1, 0) * at(m, 2, 2)); // j = 1
    const rv3: f32 = at(m, 0, 2) * (at(m, 1, 0) * at(m, 2, 1) - at(m, 1, 1) * at(m, 2, 0)); // j = 2
    return rv1 + rv2 + rv3;
}

test determinant {
    const a_m: matrix = identity();
    const a_e: f32 = 1.0;
    const a_r: f32 = determinant(a_m);
    try std.testing.expectEqual(a_e, a_r);

    const b_m: matrix = .{
        .columns = .{
            .{ 8, 4, 7, 0 },
            .{ 2, 1, 5, 0 },
            .{ 6, -3, 9, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const b_e: f32 = 156;
    const b_r: f32 = determinant(b_m);
    try std.testing.expectEqual(b_e, b_r);

    // det (AB) = det(A) det(B)
    const c_ma: matrix = .{
        .columns = .{
            .{ 8, 4, 7, 0 },
            .{ 2, 1, 5, 0 },
            .{ 6, -3, 9, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const c_mb: matrix = .{
        .columns = .{
            .{ 1, 2, 3, 0 },
            .{ 10, 5, 4, 0 },
            .{ 20, 40, 15, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const c_ad: f32 = determinant(c_ma);
    const c_bd: f32 = determinant(c_mb);
    const c_pd: f32 = determinant(transformMatrix(c_ma, c_mb));
    try std.testing.expectEqual(c_pd, c_ad * c_bd);

    // det(Aᵀ) = det(A)
    const d_ma: matrix = .{
        .columns = .{
            .{ 8, 4, 7, 0 },
            .{ 2, 1, 5, 0 },
            .{ 6, -3, 9, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const d_mt: matrix = transpose(d_ma);
    const d_mad: f32 = determinant(d_ma);
    const d_mtd: f32 = determinant(d_mt);
    try std.testing.expectEqual(d_mad, d_mtd);
}

pub fn inverse(m: matrix) matrix {
    const a = m.columns[0];
    const b = m.columns[1];
    const c = m.columns[2];
    const d = m.columns[3];

    const x: f32 = at(m, 3, 0);
    const y: f32 = at(m, 3, 1);
    const z: f32 = at(m, 3, 2);
    const w: f32 = at(m, 3, 3);

    var s = vector.crossProduct(a, b);
    var t = vector.crossProduct(c, d);
    var u = vector.sub(vector.mul(y, a), vector.mul(x, b));
    var v = vector.sub(vector.mul(w, c), vector.mul(z, d));

    const inv_d: f32 = 1.0 / vector.dotProduct(s, v) + vector.dotProduct(t, u);
    s = vector.mul(inv_d, s);
    t = vector.mul(inv_d, t);
    u = vector.mul(inv_d, u);
    v = vector.mul(inv_d, v);

    var r0: vector.vec4 = vector.add(vector.crossProduct(b, v), vector.mul(y, t));
    var r1: vector.vec4 = vector.sub(vector.crossProduct(v, a), vector.mul(x, t));
    var r2: vector.vec4 = vector.add(vector.crossProduct(d, u), vector.mul(w, s));
    var r3: vector.vec4 = vector.sub(vector.crossProduct(u, c), vector.mul(z, s));
    r0[3] = vector.dotProduct(b, t) * -1.0;
    r1[3] = vector.dotProduct(a, t);
    r2[3] = vector.dotProduct(d, s) * -1.0;
    r3[3] = vector.dotProduct(c, s);

    return transpose(.{ .columns = .{ r0, r1, r2, r3 } });
}

test inverse {
    // The inverse of I is I
    const a_m = identity();
    const a_e = identity();
    const a_r = inverse(a_m);
    try std.testing.expectEqual(a_e, a_r);

    const b_m: matrix = .{
        .columns = .{
            .{ 1, 2, 2, 0 },
            .{ 0.5, 2, 1, 0 },
            .{ 0.5, 1, 2, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const b_e: matrix = .{
        .columns = .{
            .{ 3, -2, -2, 0 },
            .{ -0.5, 1, 0, 0 },
            .{ -0.5, 0, 1, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const b_r = inverse(b_m);
    try std.testing.expectEqual(b_e, b_r);
    // Inverse M⁻¹M = I
    const c_e = identity();
    const c_r: matrix = transformMatrix(b_m, b_e);
    try std.testing.expectEqual(c_e, c_r);
}

pub fn orthonormalize(m: matrix) matrix {
    const i: vector.vec4 = m.columns[0];
    const j: vector.vec4 = m.columns[1];
    const k: vector.vec4 = m.columns[2];
    const iprime = vector.normalize(i);
    const jdi = vector.decomposeProjection(j, iprime);
    var jprime = j;
    jprime = vector.sub(jprime, jdi.proj);
    jprime = vector.normalize(jprime);
    const kdi = vector.decomposeProjection(k, iprime);
    const kdj = vector.decomposeProjection(k, jprime);
    var kprime = k;
    kprime = vector.sub(kprime, kdi.proj);
    kprime = vector.sub(kprime, kdj.proj);
    kprime = vector.normalize(kprime);
    return .{
        .columns = .{
            iprime,
            jprime,
            kprime,
            .{ 0, 0, 0, 1 },
        },
    };
}

test orthonormalize {
    const a_m: matrix = .{
        .columns = .{
            .{ 0.8999998, 0, 0, 0 },
            .{ 0.0, 1.2, 0, 0 },
            .{ 0, 0, 1.0004, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const a_e = identity();
    const a_r = orthonormalize(a_m);
    try std.testing.expectEqual(a_e, a_r);

    const b_m: matrix = .{
        .columns = .{
            .{ 0.9, 0, 0, 0 },
            .{ 0.005, 1.005, 0, 0 },
            .{ 0, 0, 1002, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const b_e = identity();
    const b_r = orthonormalize(b_m);
    try std.testing.expectEqual(b_e, b_r);
}

pub fn scalarElementaryMatrix(a: f32, row: usize) matrix {
    std.debug.assert(row < 4);
    std.debug.assert(!std.math.isNan(a));
    std.debug.assert(!std.math.isInf(a));
    var m = identity();
    // m is a diagonal matrix so row == column;
    m.columns[row] = vector.mul(a, m.columns[row]);
    std.debug.print("\n \n\n scalarElementaryMatrix: a: {d}, row: {d}, {any}\n", .{ a, row, m });
    return m;
}

pub fn addititionELementaryMatrix(a: f32, row: usize) matrix {
    std.debug.assert(row < 4);
    std.debug.assert(!std.math.isNan(a));
    std.debug.assert(!std.math.isInf(a));
    var m = identity();
    switch (row) {
        0 => m.columns[1][0] = a,
        else => m.columns[0][row] = a,
    }
    std.debug.print("addititionELementaryMatrix: {any}\n", .{m});
    return m;
}

pub fn swapElementaryMatrix(row_a: usize, row_b: usize) matrix {
    std.debug.assert(row_a < 4 and row_b < 4);
    var m = identity();
    const cb = m.columns[row_b];
    m.columns[row_b] = m.columns[row_a];
    m.columns[row_a] = cb;
    std.debug.print("swapElementaryMatrix: {any}\n", .{m});
    return transpose(m);
}

fn largestColumnComponent(c: vector.vec4) ?struct { index: usize, value: f32 } {
    if (vector.isZeroVector(c)) return null;
    var rv: usize = 0;
    var highest = -std.math.inf(f32);
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        if (c[i] > highest) {
            rv = i;
            highest = c[i];
        }
    }
    if (c[rv] == 0) return null;
    return .{ .index = rv, .value = c[rv] };
}

pub fn toReducedRowEchelonForm(a: matrix, b: matrix) ?struct { reduced_echelon: matrix, solution: matrix } {
    var i: usize = 0;
    var a_prime = a;
    var b_prime = b;
    // lower triangle space transform to row echelon form
    while (i < 4) : (i += 1) {
        // pivot step
        const pivot_element = largestColumnComponent(a.columns[i]) orelse return null;
        if (pivot_element.value != 1) {
            const m_swap = swapElementaryMatrix(i, pivot_element.index);
            a_prime = transformMatrix(a_prime, m_swap);
            b_prime = transformMatrix(a_prime, m_swap);
            const m_scalar = scalarElementaryMatrix(1.0 / pivot_element.value, i);
            a_prime = transformMatrix(a_prime, m_scalar);
            b_prime = transformMatrix(b_prime, m_scalar);
        }
        var j: usize = i + 1;
        while (j < 4) : (j += 1) {
            var lower_scalar = at(a_prime, j, i);
            if (lower_scalar == 0) continue;
            lower_scalar *= -1;
            const m_add = addititionELementaryMatrix(lower_scalar, j);
            a_prime = transformMatrix(a_prime, m_add);
            b_prime = transformMatrix(b_prime, m_add);
        }
    }
    // a_prime is now in reduced echelon form. upper triangle space transform to reduced row echelon form
    // just need to turn all the upper diagonals to zero
    var column: usize = 1;
    while (column < 4) : (column += 1) {
        var row: isize = @intCast(column - 1);
        while (row >= 0) : (row -= 1) {
            var lower_scalar = at(a_prime, @intCast(row), column);
            if (lower_scalar == 0) continue;
            lower_scalar *= -1;
            const m_add = addititionELementaryMatrix(lower_scalar, @intCast(row));
            a_prime = transformMatrix(a_prime, m_add);
            b_prime = transformMatrix(b_prime, m_add);
        }
    }
    return .{
        .reduced_echelon = a_prime,
        .solution = b_prime,
    };
}

test toReducedRowEchelonForm {
    const a_ma: matrix = .{ .columns = .{
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
    } };
    const a_mb = identity();
    try std.testing.expectEqual(null, toReducedRowEchelonForm(a_ma, a_mb));

    const b_ma = identity();
    const b_mb = identity();
    const b_res = toReducedRowEchelonForm(b_ma, b_mb);
    const b_re = identity();
    try std.testing.expect(b_res != null);
    try std.testing.expectEqual(b_re, b_res.?.reduced_echelon);
    try std.testing.expectEqual(b_re, b_res.?.solution);
}

const std = @import("std");
const vector = @import("vector.zig");
