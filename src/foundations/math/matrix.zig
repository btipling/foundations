// A column vector matrix
columns: [4]vector.vec4 = .{
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
    .{ 0, 0, 0, 0 },
},

const matrix = @This();

pub fn mc(d: [16]f32) matrix {
    var m: matrix = undefined;
    inline for (0..4) |r| {
        inline for (0..4) |c| {
            m.columns[c][r] = d[c + r * 4];
        }
    }
    return m;
}

pub fn identity() matrix {
    return mc(.{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    });
}

pub fn rotationX(angle: f32) matrix {
    return mc(.{
        1, 0,           0,            0,
        0, @cos(angle), -@sin(angle), 0,
        0, @sin(angle), @cos(angle),  0,
        0, 0,           0,            1,
    });
}

pub fn rotationY(angle: f32) matrix {
    return mc(.{
        @cos(angle), 0, -@sin(angle), 0,
        0,           1, 0,            0,
        @sin(angle), 0, @cos(angle),  0,
        0,           0, 0,            1,
    });
}

pub fn rotationZ(angle: f32) matrix {
    return mc(.{
        @cos(angle), -@sin(angle), 0, 0,
        @sin(angle), @cos(angle),  0, 0,
        0,           0,            1, 0,
        0,           0,            0, 1,
    });
}

pub fn scale(x: f32, y: f32, z: f32) matrix {
    return mc(.{
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1,
    });
}

pub fn perspectiveProjection(field_of_view_y_angle: f32, aspect_ratio_s: f32, near: f32, far: f32) matrix {
    const perspective_plane_distance_g: f32 = 1.0 / @tan(field_of_view_y_angle * 0.5);
    return perspectiveProjectionCamera(perspective_plane_distance_g, aspect_ratio_s, near, far);
}

test perspectiveProjection {
    const fovy: f32 = rotation.degreesToRadians(70);
    const width: f32 = 3840;
    const height: f32 = 2400;
    const s = width / height;
    const near: f32 = 0.1;
    const far: f32 = 500;
    const g: f32 = 1.0 / @tan(fovy * 0.5);
    const p = perspectiveProjectionCamera(g, s, near, far);
    const plane_extracted_left = vector.normalize(vector.add(p.columns[3], p.columns[0]));
    const clip_space_left: vector.vec4 = .{ 1, 0, 0, 1 };
    const perspective_transformed_left = vector.normalize(transformVector(p, clip_space_left));

    try std.testing.expect(float.equal(plane_extracted_left[0], perspective_transformed_left[0], 0.000001));
    try std.testing.expect(float.equal(plane_extracted_left[1], perspective_transformed_left[1], 0.000001));
    try std.testing.expect(float.equal(plane_extracted_left[2], perspective_transformed_left[2], 0.000001));
    try std.testing.expect(float.equal(plane_extracted_left[3], perspective_transformed_left[3], 0.000001));
}

pub fn perspectiveProjectionCamera(perspective_plane_distance_g: f32, aspect_ratio_s: f32, near: f32, far: f32) matrix {
    const depth_scale = far / (far - near);
    return mc(.{
        perspective_plane_distance_g / aspect_ratio_s, 0,                            0,           0,
        0,                                             perspective_plane_distance_g, 0,           0,
        0,                                             0,                            depth_scale, -near * depth_scale,
        0,                                             0,                            1,           0,
    });
}

pub fn infinityProjection(fovy: f32, s: f32, n: f32, epsilon: f32) matrix {
    const g: f32 = 1.0 / @tan(fovy * 0.5);
    return mc(.{
        g / s, 0, 0,       0,
        0,     g, 0,       0,
        0,     0, epsilon, n * (1.0 - epsilon),
        0,     0, 1,       0,
    });
}

pub fn orthographicProjection(_: f32, r: f32, _: f32, b: f32, n: f32, f: f32) matrix {
    const d_inv: f32 = 1.0 / (f - n);
    return mc(.{
        2 / r, 0,     0,     0,
        0,     2 / b, 0,     0,
        0,     0,     d_inv, 0,
        0,     0,     1,     1,
    });
}

pub fn reverseOrthographicProjection(l: f32, r: f32, t: f32, b: f32, n: f32, f: f32) matrix {
    return inverse(orthographicProjection(l, r, t, b, n, f));
}

pub fn uniformScale(s: f32) matrix {
    return scale(s, s, s);
}

pub fn translateVec(v: anytype) matrix {
    return translate(v[0], v[1], v[2]);
}

pub fn translate(x: f32, y: f32, z: f32) matrix {
    return mc(.{
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1,
    });
}

pub fn normalizedQuaternionToMatrix(q: Quat) matrix {
    const qw = q[0];
    const qx = q[1];
    const qy = q[2];
    const qz = q[3];

    const s: f32 = 2.0 / (qx * qx + qy * qy + qz * qz + qw * qw);

    const xs: f32 = s * qx;
    const ys: f32 = s * qy;
    const zs: f32 = s * qz;

    const wx = qw * xs;
    const wy = qw * ys;
    const wz = qw * zs;

    const xx = qx * xs;
    const xy = qx * ys;
    const xz = qx * zs;

    const yy = qy * ys;
    const yz = qy * zs;

    const zz = qz * zs;

    return mc(.{
        1.0 - (yy + zz), xy - wz,         xz + wy,         0,
        xy + wz,         1.0 - (xx + zz), yz - wx,         0,
        xz - wy,         yz + wx,         1.0 - (xx + yy), 0,
        0,               0,               0,               1,
    });
}

pub fn leftHandedXUpToNDC() matrix {
    return mc(.{
        0, 0, 1, 0,
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 1,
    });
}

pub fn NDCToLeftHandedXUp() matrix {
    return transpose(leftHandedXUpToNDC());
}

test leftHandedXUpToNDC {
    const m = leftHandedXUpToNDC();
    const v1v2_cross_product = vector.crossProduct(m.columns[0], m.columns[1]);
    const a: vector.vec3 = .{
        v1v2_cross_product[0],
        v1v2_cross_product[1],
        v1v2_cross_product[2],
    };
    const b: vector.vec3 = .{
        m.columns[2][0],
        m.columns[2][1],
        m.columns[2][2],
    };
    const result = vector.dotProduct(a, b);
    try std.testing.expect(result > 0);
}

pub fn debug(m: matrix, msg: []const u8) void {
    const mt = transpose(m);
    std.debug.print("\ndebug matrix {s}: \n\t{any}\n\t{any}\n\t{any}\n\t{any}\n\n", .{
        msg,
        mt.columns[0],
        mt.columns[1],
        mt.columns[2],
        mt.columns[3],
    });
}

pub fn array(m: matrix) [16]f32 {
    var rv: [16]f32 = undefined;
    @memcpy(rv[0..4], @as([4]f32, m.columns[0])[0..]);
    @memcpy(rv[4..8], @as([4]f32, m.columns[1])[0..]);
    @memcpy(rv[8..12], @as([4]f32, m.columns[2])[0..]);
    @memcpy(rv[12..16], @as([4]f32, m.columns[3])[0..]);
    return rv;
}

pub fn at(m: matrix, row: usize, column: usize) f32 {
    return m.columns[column][row];
}

test at {
    const a_m = mc(.{
        -3, 9, 5,  0,
        15, 0, -2, 0,
        12, 9, -7, 0,
        0,  0, 0,  1,
    });
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

pub fn hermite_basis() matrix {
    return .{
        .columns = .{
            .{ 2, -3, 0, 1 },
            .{ -2, 3, 0, 0 },
            .{ 1, -2, 1, 0 },
            .{ 1, -1, 0, 0 },
        },
    };
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

pub fn preTransformVector(v: vector.vec4, m: matrix) vector.vec4 {
    return .{
        vector.dotProduct(v, @as(vector.vec4, .{
            at(m, 0, 0),
            at(m, 1, 0),
            at(m, 2, 0),
            at(m, 3, 0),
        })),
        vector.dotProduct(v, @as(vector.vec4, .{
            at(m, 0, 1),
            at(m, 1, 1),
            at(m, 2, 1),
            at(m, 3, 1),
        })),
        vector.dotProduct(v, @as(vector.vec4, .{
            at(m, 0, 2),
            at(m, 1, 2),
            at(m, 2, 2),
            at(m, 3, 2),
        })),
        vector.dotProduct(v, @as(vector.vec4, .{
            at(m, 0, 3),
            at(m, 1, 3),
            at(m, 2, 3),
            at(m, 3, 3),
        })),
    };
}

test preTransformVector {
    const a_v: vector.vec4 = .{ 2, 3, 4, 1 };
    const a_m: matrix = identity();
    const a_e: vector.vec4 = .{ 2, 3, 4, 1 };
    const a_r = preTransformVector(a_v, a_m);
    try std.testing.expectEqual(a_e, a_r);

    const b_v: vector.vec4 = .{ 2, 3, 4, 5 };
    const b_m: matrix = .{
        .columns = .{
            .{ 3, 0, 0, 0 },
            .{ 0, 4, 0, 0 },
            .{ 0, 0, 5, 0 },
            .{ 4, 4, 4, 1 },
        },
    };
    const b_e: vector.vec4 = .{ 6, 12, 20, 41 };
    const b_r = preTransformVector(b_v, b_m);
    try std.testing.expectEqual(b_e, b_r);

    const c_v: vector.vec4 = .{ 1, 2, 3, 4 };
    const c_m: matrix = .{
        .columns = .{
            .{ -3, 0, 0, 0 },
            .{ 3, 0, 0, 0 },
            .{ -2, 0, 1, 0 },
            .{ -1, 0, 0, 0 },
        },
    };
    const c_e: vector.vec4 = .{ -3, 3, 1, -1 };
    const c_r = preTransformVector(c_v, c_m);
    try std.testing.expectEqual(c_e, c_r);
}

pub fn transpose(m: matrix) matrix {
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

pub fn cameraInverse(m: matrix) matrix {
    var r: matrix = .{
        .columns = .{
            .{
                at(m, 0, 0),
                at(m, 0, 1),
                at(m, 0, 2),
                0,
            },
            .{
                at(m, 1, 0),
                at(m, 1, 1),
                at(m, 1, 2),
                0,
            },
            .{
                at(m, 2, 0),
                at(m, 2, 1),
                at(m, 2, 2),
                0,
            },
            .{ 0, 0, 0, 0 },
        },
    };
    var vPos: vector.vec4 = vector.negate(transformVector(r, m.columns[3]));
    vPos[3] = 1;
    r.columns[3] = vPos;
    return r;
}

test cameraInverse {
    const a: rotation.AxisAngle = .{
        .angle = std.math.pi * 0.2,
        .axis = .{ 1, 0, 0 },
    };
    const camera_orientation: rotation.Quat = rotation.axisAngleToQuat(a);
    var m = identity();
    m = transformMatrix(m, translate(
        10,
        3,
        -0.5,
    ));
    m = transformMatrix(m, normalizedQuaternionToMatrix(camera_orientation));
    const m_i = inverse(m);
    const c_i = cameraInverse(m);
    try std.testing.expect(equal(m_i, c_i, 0.000001));
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

    // rotations have a determinant of 1
    const e_mt = rotationX(0.234);
    try std.testing.expect(float.equal(1.0, determinant(e_mt), 0.000001));
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
    try std.testing.expect(equal(a_e, a_r, 0.000001));

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
    try std.testing.expect(equal(b_e, b_r, 0.000001));
    // Inverse M⁻¹M = I
    const c_e = identity();
    const c_r: matrix = transformMatrix(b_m, b_e);
    try std.testing.expect(equal(c_e, c_r, 0.000001));

    // The inverse of a scale matrix is the recriprocal of the original matrices components.
    // This is clear if you consider that a scale matrix is a diagonal matrix and
    // that to reverse the transformation of a scale, as an example, that grows you would want to shrink
    // in the reverse amount.
    const d_m = scale(2.0, 3.0, 4.0);
    const d_e = scale(1.0 / 2.0, 1.0 / 3.0, 1.0 / 4.0);
    const d_r = inverse(d_m);
    try std.testing.expect(equal(d_e, d_r, 0.000001));

    // The inverse of a translation will translate a vector back to where it was
    // originally translated from
    const e_m = translate(2.0, 3.0, 4.0);
    const e_e = translate(-2.0, -3.0, -4.0);
    const e_r = inverse(e_m);
    try std.testing.expect(equal(e_e, e_r, 0.000001));
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
    try std.testing.expect(equal(a_e, a_r, 0.000001));

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
    try std.testing.expect(equal(b_e, b_r, 0.000001));

    // The detemrinant of an orthogonal matrix is 1
    const c_m: matrix = .{
        .columns = .{
            .{ 0.9, 0, 0, 0 },
            .{ 0.005, 1.005, 0, 0 },
            .{ 0, 0, 1002, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const c_r = orthonormalize(c_m);
    try std.testing.expect(!float.equal(1.0, determinant(c_m), 0.00001));
    try std.testing.expect(float.equal(1.0, determinant(c_r), 0.00001));
}

const echelon_reduction_precision: f32 = 0.0001;

pub fn scalarElementaryMatrix(a: f32, row: usize) matrix {
    std.debug.assert(row < 4);
    std.debug.assert(!std.math.isNan(a));
    std.debug.assert(!std.math.isInf(a));
    var m = identity();
    // m is a diagonal matrix so row is equal column;
    m.columns[row] = vector.mul(a, m.columns[row]);
    return m;
}

pub fn addititionElementaryMatrix(a: f32, row: usize, column: usize) matrix {
    std.debug.assert(row < 4);
    std.debug.assert(!std.math.isNan(a));
    std.debug.assert(!std.math.isInf(a));
    var m = identity();
    m.columns[column][row] = a;
    return m;
}

pub fn swapElementaryMatrix(row_a: usize, row_b: usize) matrix {
    std.debug.assert(row_a < 4 and row_b < 4);
    var m = identity();
    const cb = m.columns[row_b];
    m.columns[row_b] = m.columns[row_a];
    m.columns[row_a] = cb;
    return transpose(m);
}

fn largestColumnComponent(c: vector.vec4, start_at: usize) ?struct { index: usize, value: f32 } {
    if (vector.isZeroVector(c)) return null;
    var rv: usize = 0;
    var highest = -std.math.inf(f32);
    var i: usize = start_at;
    while (i < 4) : (i += 1) {
        if (@abs(c[i]) > highest) {
            rv = i;
            highest = @abs(c[i]);
        }
    }
    if (float.equal(c[rv], 0.0, echelon_reduction_precision)) return null;
    return .{ .index = rv, .value = c[rv] };
}

pub fn toReducedRowEchelonForm(a: matrix, b: matrix) ?struct { reduced_echelon: matrix, solution: matrix } {
    var i: usize = 0;
    var a_prime = a;
    var b_prime = b;
    // lower triangle space transform to row echelon form
    while (i < 4) : (i += 1) {
        // pivot step
        const pivot_element = largestColumnComponent(a_prime.columns[i], i) orelse return null;
        if (pivot_element.value != 1) {
            const m_swap = swapElementaryMatrix(i, pivot_element.index);
            a_prime = transformMatrix(m_swap, a_prime);
            b_prime = transformMatrix(m_swap, b_prime);

            const s = 1.0 / pivot_element.value;
            const m_scalar = scalarElementaryMatrix(s, i);
            a_prime = transformMatrix(m_scalar, a_prime);
            std.debug.assert(float.equal(at(a_prime, i, i), 1.0, echelon_reduction_precision));
            b_prime = transformMatrix(m_scalar, b_prime);
        }
        var row: usize = i + 1;

        const column = i;
        while (row < 4) : (row += 1) {
            var element = at(a_prime, row, column);
            if (float.equal(element, 0.0, echelon_reduction_precision)) continue; // already zero
            element *= -1; // add the negative value to reduce to zero
            const m_add = addititionElementaryMatrix(element, row, column);
            a_prime = transformMatrix(m_add, a_prime);
            std.debug.assert(float.equal(at(a_prime, row, column), 0.0, echelon_reduction_precision));
            b_prime = transformMatrix(m_add, b_prime);
        }
    }
    // a_prime is now in row echelon form. upper triangle space transform to reduced row echelon form
    // just need to turn all the upper non-diagonals to zero
    var column: usize = 1;
    while (column < 4) : (column += 1) {
        var row: isize = @intCast(column - 1);
        while (row >= 0) : (row -= 1) {
            var lower_scalar = at(a_prime, @intCast(row), column);
            if (float.equal(lower_scalar, 0.0, echelon_reduction_precision)) continue;
            lower_scalar *= -1;
            const m_add = addititionElementaryMatrix(lower_scalar, @intCast(row), column);
            a_prime = transformMatrix(m_add, a_prime);
            b_prime = transformMatrix(m_add, b_prime);
        }
    }
    return .{
        .reduced_echelon = a_prime,
        .solution = b_prime,
    };
}

test toReducedRowEchelonForm {
    const I = identity();
    const a_ma: matrix = .{ .columns = .{
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
    } };
    const a_mb = identity();
    try std.testing.expectEqual(null, toReducedRowEchelonForm(a_ma, a_mb));

    const b_res = toReducedRowEchelonForm(I, I);
    try std.testing.expect(b_res != null);
    try std.testing.expectEqual(I, b_res.?.reduced_echelon);
    try std.testing.expectEqual(I, b_res.?.solution);

    const c_ma: matrix = transpose(.{
        .columns = .{
            .{ 1, 0, 0, 0 },
            .{ 2, 1, 0, 0 },
            .{ 0, 0, 1, 0 },
            .{ 0, 0, 0, 1 },
        },
    });
    const c_res = toReducedRowEchelonForm(c_ma, I);
    try std.testing.expect(c_res != null);
    try std.testing.expectEqual(I, c_res.?.reduced_echelon);
    try std.testing.expectEqual(I, transformMatrix(c_ma, c_res.?.solution));

    const d_m: matrix = .{
        .columns = .{
            .{ 1, 2, 2, 0 },
            .{ 0.5, 2, 1, 0 },
            .{ 0.5, 1, 2, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const d_re: matrix = .{
        .columns = .{
            .{ 3, -2, -2, 0 },
            .{ -0.5, 1, 0, 0 },
            .{ -0.5, 0, 1, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
    const d_res = toReducedRowEchelonForm(d_m, I);
    try std.testing.expect(d_res != null);
    try std.testing.expectEqual(I, d_res.?.reduced_echelon);
    try std.testing.expectEqual(d_re, d_res.?.solution);

    // Linear dependent has no solution set.
    // zig fmt: off
    const e_m: matrix = .{
        .columns = .{
            .{ 1,   0,  0,  0 },
            .{ 0,   1,  0,  0 },
            .{ 0,   1,  0,  0 },
            .{ 0,   0,  0,  1 },
        },
    };
    // zig fmt: on
    const e_res = toReducedRowEchelonForm(e_m, I);
    try std.testing.expectEqual(0, determinant(e_m));
    try std.testing.expect(e_res == null);
}

fn equal(m1: matrix, m2: matrix, epsilon: f32) bool {
    inline for (0..4) |r| {
        inline for (0..4) |c| {
            if (!float.equal(at(m1, r, c), at(m2, r, c), epsilon)) return false;
        }
    }
    return true;
}

const std = @import("std");
const vector = @import("vector.zig");
const float = @import("float.zig");
const rotation = @import("rotation.zig");
const geometry = @import("geometry/geometry.zig");
const Quat = rotation.Quat;
