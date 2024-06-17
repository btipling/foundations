pub const vec4 = @Vector(4, f32);
pub const vec3 = @Vector(3, f32);
pub const vec2 = @Vector(2, f32);

pub fn negate(v: anytype) @TypeOf(v) {
    return mul(-1, v);
}

test negate {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ -1, -2, -3, 0 };
    try std.testing.expectEqual(ae, negate(a));
}

pub fn mul(m: anytype, v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const K = @TypeOf(m);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v * @as(T, @splat(m)),
            // This isn't mathmatically correct for vector math, correct vector multiplication is the dot product or the cross product
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector length") else return v * m,
            else => @compileError("second input must be a vector or scalar"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test mul {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ 2, 4, 6, 0 };
    try std.testing.expectEqual(ae, mul(2, a));

    const b: vec4 = .{ 1, 2, 3, 0 };
    const be: vec4 = .{ 10, -20, 9, 0 };
    try std.testing.expectEqual(be, mul(@as(vec4, .{ 10, -10, 3, 100 }), b));

    // multiplying a vector by 2 makes it twice as long:
    const c: vec3 = .{ 3, -2, 7 };
    const cm = magnitude(c);
    try std.testing.expectEqual(cm * 2, magnitude(mul(2, c)));

    // multiplying a vector by zero makes the zero vector:
    const d: vec3 = .{ 3, -2, 7 };
    try std.testing.expect(isZeroVector(mul(0, d)));
}

pub fn div(v: anytype, d: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const K = @TypeOf(d);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v / @as(T, @splat(d)),
            // This isn't mathmatically correct for vector math, vectors can't be divided by other vectors
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return v / d,
            else => @compileError("second input must be a vector or scalar"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test div {
    const a: vec4 = .{ 2, 4, 6, 0 };
    const ae: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(ae, div(a, 2));
    const b: vec4 = .{ 10, -20, 9, 0 };
    const be: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(be, div(b, @as(vec4, .{ 10, -10, 3, 100 })));
}

pub fn add(v1: anytype, v2: anytype) @TypeOf(v1) {
    const T = @TypeOf(v1);
    const K = @TypeOf(v2);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            // This isn't mathmatically correct for vector math, vectors and scalars cannot be added together
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v1 + @as(T, @splat(v2)),
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return v1 + v2,
            else => @compileError("second input must be a vector or scalar"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test add {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ 3, 4, 5, 2 };
    try std.testing.expectEqual(ae, add(a, 2));
    const b: vec4 = .{ 1, 2, 3, 0 };
    const be: vec4 = .{ 10, -20, 9, 0 };
    try std.testing.expectEqual(be, add(@as(vec4, .{ 9, -22, 6, 0 }), b));
}

pub fn sub(v1: anytype, v2: anytype) @TypeOf(v1) {
    const T = @TypeOf(v1);
    const K = @TypeOf(v2);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            // This isn't mathmatically correct for vector math, vectors and scalars cannot be subtracted
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v1 - @as(T, @splat(v2)),
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return v1 - v2,
            else => @compileError("second input must be a vector or scalar"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test sub {
    const a: vec4 = .{ 2, 4, 6, 0 };
    const ae: vec4 = .{ 0, 2, 4, -2 };
    try std.testing.expectEqual(ae, sub(a, 2));
    const b: vec4 = .{ 10, -20, 9, 0 };
    const be: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(be, sub(b, @as(vec4, .{ 9, -22, 6, 0 })));
}

// vecFromPointAToPointB treats points as vectors from origin
pub fn vecFromPointAToPointB(v1: anytype, v2: anytype) @TypeOf(v1) {
    const T = @TypeOf(v1);
    const K = @TypeOf(v2);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return v2 - v1,
            else => @compileError("second input must be a vector"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test vecFromPointAToPointB {
    const b: vec4 = .{ 10, -20, 9, 0 };
    const be: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(be, vecFromPointAToPointB(@as(vec4, .{ 9, -22, 6, 0 }), b));
}

pub fn magnitude(v: anytype) @TypeOf(v[0]) {
    switch (@typeInfo(@TypeOf(v))) {
        .Vector => {
            return @sqrt(@reduce(.Add, v * v));
        },
        else => {},
    }
    @compileError("input must be a vector");
}

test magnitude {
    const a: vec4 = .{ 3, 4, 5, 6 };
    const ae: f32 = 9.27361;
    try std.testing.expect(float.equal(ae, magnitude(a), 0.00001));
}

// To avoid a costly square root calculation when we can
pub fn lengthSquared(v: anytype) @TypeOf(v[0]) {
    switch (@typeInfo(@TypeOf(v))) {
        .Vector => {
            return @reduce(.Add, v * v);
        },
        else => {},
    }
    @compileError("input must be a vector");
}

test lengthSquared {
    const a: vec4 = .{ 3, 4, 5, 6 };
    const ae: f32 = 86;
    try std.testing.expectEqual(ae, lengthSquared(a));
}

pub fn normalize(v: anytype) @TypeOf(v) {
    if (@typeInfo(@TypeOf(v)) != .Vector) @compileError("input must be a vector");
    return div(v, magnitude(v));
}

test normalize {
    const a: vec2 = .{ 12, -5 };
    const aex: f32 = 0.923;
    const aey: f32 = -0.385;
    const res = normalize(a);
    try std.testing.expect(float.equal(aex, res[0], 0.001));
    try std.testing.expect(float.equal(aey, res[1], 0.001));

    const b: vec3 = .{ 1, 0, 0 };
    try std.testing.expectEqual(b, normalize(b));
}

pub fn distance(a: anytype, b: anytype) @TypeOf(a[0]) {
    return magnitude(sub(b, a));
}

test distance {
    const a_a: vec2 = .{ 5, 0 };
    const a_b: vec2 = .{ -1, 8 };
    const ae: f32 = 10;
    try std.testing.expectEqual(ae, distance(a_a, a_b));
    try std.testing.expectEqual(ae, distance(a_b, a_a));
}

pub fn dotProduct(v1: anytype, v2: anytype) @TypeOf(v1[0]) {
    const T = @TypeOf(v1);
    const K = @TypeOf(v2);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return @reduce(.Add, v1 * v2),
            else => @compileError("second input must be a vector"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test dotProduct {
    const a_v1: vec2 = .{ 4, 6 };
    const a_v2: vec2 = .{ -3, 7 };
    const ae: f32 = 30;
    try std.testing.expectEqual(ae, dotProduct(a_v1, a_v2));

    const b_v1: vec3 = .{ 3, -2, 7 };
    const b_v2: vec3 = .{ 0, 4, -1 };
    const be: f32 = -15;
    try std.testing.expectEqual(be, dotProduct(b_v1, b_v2));

    // Geometric tests
    // perpendicular dot product produces a 0:
    const c_v1: vec3 = .{ 2, 0, 0 };
    const c_v2: vec3 = .{ 0, 4, 0 };
    const ce: f32 = 0;
    try std.testing.expectEqual(ce, dotProduct(c_v1, c_v2));

    // same direction vectors produce a positive value
    const d_v1: vec3 = .{ 2, 0, 0 };
    const d_v2: vec3 = .{ 4, 0, 0 };
    try std.testing.expect(dotProduct(d_v1, d_v2) > 0);

    // opposite direction vectors produce a negative value
    const e_v1: vec3 = .{ 2, 0, 0 };
    const e_v2: vec3 = .{ -4, 0, 0 };
    try std.testing.expect(dotProduct(e_v1, e_v2) < 0);

    // dot product projection scales by the same factor as scaling the vector
    const f_v1: vec3 = .{ 3, -2, 7 };
    const f_v2: vec3 = .{ 0, 4, -1 };
    const f_scale: f32 = 5;
    try std.testing.expectEqual(dotProduct(f_v1, mul(f_scale, f_v2)), dotProduct(f_v1, f_v2) * f_scale);
    try std.testing.expectEqual(dotProduct(mul(f_scale, f_v1), f_v2), dotProduct(f_v1, f_v2) * f_scale);

    // if both vectors are unit vectors the projection of eiter on the other has the same length
    const g_v1: vec3 = .{ 3, -2, 7 };
    const g_v2: vec3 = .{ 0, 4, -1 };
    try std.testing.expectEqual(
        dotProduct(normalize(g_v1), normalize(g_v2)),
        dotProduct(normalize(g_v2), normalize(g_v1)),
    );

    // Vectors do not need to be the same length to be commutative
    const h_v1: vec3 = .{ 3, -2, 7 };
    const h_v2: vec3 = .{ 0, 4, -1 };
    try std.testing.expectEqual(dotProduct(h_v1, h_v2), dotProduct(h_v2, h_v1));

    // the dot product distributes across addition and subtraction
    const i_v1: vec3 = .{ 3, -2, 7 };
    const i_v2: vec3 = .{ 0, 4, -1 };
    const i_v3: vec3 = .{ 1, 4, 0 };
    try std.testing.expectEqual(dotProduct(i_v1, add(i_v2, i_v3)), dotProduct(i_v1, i_v2) + dotProduct(i_v1, i_v3));
    try std.testing.expectEqual(dotProduct(i_v1, sub(i_v2, i_v3)), dotProduct(i_v1, i_v2) - dotProduct(i_v1, i_v3));

    // the dot product of a unit vector of an axis and a vector extracts the value from vector for that axis
    const j_v1: vec3 = .{ -3, 5, 22 };
    try std.testing.expectEqual(-3, dotProduct(@as(vec3, .{ 1, 0, 0 }), j_v1));
    try std.testing.expectEqual(5, dotProduct(@as(vec3, .{ 0, 1, 0 }), j_v1));
    try std.testing.expectEqual(22, dotProduct(@as(vec3, .{ 0, 0, 1 }), j_v1));

    // the dot product of a vector with itself is the magnitude of the vector scaled by itself
    const k_v1: vec3 = .{ -3, 5, 22 };
    try std.testing.expectEqual(magnitude(k_v1) * magnitude(k_v1), dotProduct(k_v1, k_v1));
    try std.testing.expectEqual(magnitude(k_v1), @sqrt(dotProduct(k_v1, k_v1)));

    // extracting the b's perpendicular b and parallel b (to a unit vector a)
    const l_v1: vec2 = .{ 1, 0 };
    const l_v2: vec2 = .{ -3, 5 };
    const l_v3: vec2 = .{ 0, 1 };
    // l_v2_parallel is a vector parallel to a, magnitude of b along a scaled to unit a
    const l_v2_parallel = mul(dotProduct(l_v1, l_v2), l_v1);
    // l_v2_perpendicular is a vetor perpendicular a, the magnitude of b along that axis
    const l_v2_perpendicular = sub(l_v2, l_v2_parallel);
    try std.testing.expectEqual(l_v2_perpendicular, sub(l_v2, mul(dotProduct(l_v1, l_v2), l_v1)));
    // The result of the l_v2_perpendicular is just the y value extracted:
    try std.testing.expectEqual(mul(dotProduct(l_v3, l_v2), l_v3), l_v2_perpendicular);
    // the dot product of perpendicular vertices is 0:
    try std.testing.expectEqual(0, dotProduct(l_v2_parallel, l_v2_perpendicular));

    // cos ∅ = adjacent/hypotenuse = (a dot b)/1 = a dot b
    const m_v1: vec2 = .{ 1, 1 }; // some vector with a magnitude and direction
    const m_v2: vec2 = .{ 0, 1 }; // a unit vector along the x positive axis
    const m_v3: vec2 = normalize(m_v1); // extract a unit vector with just that direction,
    const m_hypotenuse: f32 = magnitude(m_v3); // its length is the hypotenuse
    // the dot product of the hypotenuse and the unit vector create the adjacent side of the triangle:
    const m_adjacent: f32 = dotProduct(m_v2, m_v3);
    const m_angle: f32 = std.math.acos(m_adjacent / m_hypotenuse); // I mean I am just testing that acos works I guess :|
    try std.testing.expectEqual(@cos(m_angle), m_adjacent / m_hypotenuse);
    // a dot b = ||a|| * ||b|| * cos ∅
    try std.testing.expectEqual(m_adjacent, magnitude(m_v2) * magnitude(m_v3) * @cos(m_angle));

    // The zero vector is perpendicular to every vector
    const n_v1: vec3 = .{ -3, 5, 22 };
    const n_v2: vec3 = .{ 0, 0, 0 };
    try std.testing.expectEqual(0, dotProduct(n_v1, n_v2));
}

// angleBetweenVectors returns angle in radians
pub fn angleBetweenVectors(a: anytype, b: anytype) f32 {
    const T = @TypeOf(a);
    const K = @TypeOf(b);
    if (T != K) @compileError("a and b must be the same type");
    if (@typeInfo(T) != .Vector) @compileError("inputs must be vectors");
    const child_type = @typeInfo(T).Vector.child;
    if (@typeInfo(child_type) == .Float or @typeInfo(child_type) == .ComptimeFloat) {
        const dp = dotProduct(a, b);
        const divisor = magnitude(a) * magnitude(b);
        return @floatCast(std.math.acos(dp / divisor));
    }
    if (@typeInfo(child_type) == .It or @typeInfo(child_type) == .ComptimeInt) {
        const dp = dotProduct(a, b);
        const divisor = magnitude(a) * magnitude(b);
        return @floatFromInt(std.math.acos(dp / divisor));
    }
    @compileError("inputs must be vectors of floats or ints");
}

test angleBetweenVectors {
    const a_v1: vec2 = .{ 1, 0 };
    const a_v2: vec2 = .{ 0, 1 };
    const ae: f32 = 90;
    try std.testing.expectEqual(ae, rotation.radiansToDegrees(angleBetweenVectors(a_v1, a_v2)));
}

pub fn isZeroVector(v: anytype) bool {
    const ti = @typeInfo(@TypeOf(v));
    if (ti != .Vector) @compileError("input must be a vector");
    var i: usize = 0;
    while (i < ti.Vector.len) : (i += 1) if (v[i] != 0) return false;
    return true;
}

test isZeroVector {
    try std.testing.expect(isZeroVector(@as(vec3, .{ 0, 0, 0 })));
    try std.testing.expect(!isZeroVector(@as(vec3, .{ 1, 2, 3 })));
    try std.testing.expect(isZeroVector(@as(vec2, .{ 0, 0 })));
    try std.testing.expect(!isZeroVector(@as(vec2, .{ 1, 2 })));
    try std.testing.expect(!isZeroVector(@as(vec2, .{ 1, 0 })));
    try std.testing.expect(!isZeroVector(@as(vec2, .{ 1, -1 })));
}

pub fn crossProduct(p: anytype, q: anytype) @TypeOf(p) {
    const T = @TypeOf(p);
    const K = @TypeOf(q);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Vector => |VM| {
                if (VT.len != VM.len and VT.len < 3) @compileError("cross product must be for 3D vector");
                var result: T = undefined;
                if (VT.len > 3) @memset(&result, 0);
                result[0] = p[1] * q[2] - p[2] * q[1];
                result[1] = p[2] * q[0] - p[0] * q[2];
                result[2] = p[0] * q[1] - p[1] * q[0];
                return result;
            },
            else => @compileError("second input must be a vector"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test crossProduct {
    const a_v1: vec3 = .{ 1, 3, 4 };
    const a_v2: vec3 = .{ 2, -5, 8 };
    const ae: vec3 = .{ 44, 0, -11 };
    try std.testing.expectEqual(ae, crossProduct(a_v1, a_v2));

    // ||a × b|| = ||a|| * ||b|| * sine ∅
    const b_v1: vec3 = .{ 1, 3, 4 };
    const b_v2: vec3 = .{ 2, -5, 8 };
    const b_angle = angleBetweenVectors(b_v1, b_v2);
    try std.testing.expect(float.equal(magnitude(crossProduct(b_v1, b_v2)), magnitude(b_v1) * magnitude(b_v2) * @sin(b_angle), 0.0001));

    // parallel vectors return the zero vector
    const c_v1: vec3 = .{ 1, 0, 0 };
    const c_v2: vec3 = .{ 3, 0, 0 };
    try std.testing.expect(isZeroVector(crossProduct(c_v1, c_v2)));

    // zero vectors are always parallel to any vector
    const d_v1: vec3 = .{ 1, 3, 4 };
    const d_v2: vec3 = .{ 0, 0, 0 };
    try std.testing.expect(isZeroVector(crossProduct(d_v1, d_v2)));

    // v × v is the zero vector, obviously as v is parallel to itself:
    const d2_v1: vec3 = .{ 1, 3, 4 };
    try std.testing.expect(isZeroVector(crossProduct(d2_v1, d2_v1)));

    // the cross product is anti-commutative
    const e_v1: vec3 = .{ 1, 3, 4 };
    const e_v2: vec3 = .{ 2, -5, 8 };
    try std.testing.expectEqual(crossProduct(e_v1, e_v2), negate(crossProduct(e_v2, e_v1)));

    // The cross product points in a perpendicular direction
    const x_pos: vec3 = .{ 1, 0, 0 };
    const x_neg: vec3 = negate(x_pos);
    const y_pos: vec3 = .{ 0, 1, 0 };
    const y_neg: vec3 = negate(y_pos);
    const z_pos: vec3 = .{ 0, 0, 1 };
    const z_neg: vec3 = negate(z_pos);

    // Pointing in the positive direction
    try std.testing.expectEqual(z_pos, crossProduct(x_pos, y_pos));
    try std.testing.expectEqual(x_pos, crossProduct(y_pos, z_pos));
    try std.testing.expectEqual(y_pos, crossProduct(z_pos, x_pos));

    // Pointing in the negative direction
    try std.testing.expectEqual(z_neg, crossProduct(y_pos, x_pos));
    try std.testing.expectEqual(x_neg, crossProduct(z_pos, y_pos));
    try std.testing.expectEqual(y_neg, crossProduct(x_pos, z_pos));

    // The cross product is orthogonal to both input vectors
    const f_v1: vec3 = .{ 1, 3, 4 };
    const f_v2: vec3 = .{ 2, -5, 8 };
    try std.testing.expectEqual(0, dotProduct(crossProduct(f_v1, f_v2), f_v1));
    try std.testing.expectEqual(0, dotProduct(crossProduct(f_v1, f_v2), f_v2));

    // The cross product produces a vector that adheres to the right hand rule in a right handed coordinate system
    // given fingers aligned with the direction vector P points, and the palm points in direction of Q
    // the thumb will point in the direction of the product
    // given a y up z positive going out of the screen as per a right handed coordinate system
    const g_p: vec3 = .{ 1, 0, 0 }; // the i basis vector - fingers of right hand to the right
    const g_q: vec3 = .{ 0, 1, 0 }; // the j basis vector - palm facing up
    const g_expected_vector: vec3 = .{ 0, 0, 1 }; // the k basis vector - the thumb would point toward the back of the person, RHS z+ direction
    try std.testing.expectEqual(g_expected_vector, crossProduct(g_p, g_q));
}

// decomposeProjection - extract the projection of p onto q and the portion of p that is perpendicular to q
pub fn decomposeProjection(p: anytype, q: anytype) struct { proj: @TypeOf(p), perp: @TypeOf(p) } {
    const T = @TypeOf(p);
    const K = @TypeOf(q);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Vector => |VM| {
                if (VT.len != VM.len) @compileError("vectors must be of the same length");
                const q_mag = magnitude(q);
                const proj = mul(dotProduct(p, q) / q_mag * q_mag, q);
                const perp = sub(p, proj);
                return .{ .proj = proj, .perp = perp };
            },
            else => @compileError("second input must be a vector"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test decomposeProjection {
    const a_v1: vec3 = .{ 1, 1, 1 };
    const a_p: vec3 = normalize(a_v1);
    const a_q: vec3 = .{ 1, 0, 0 };
    const a_expected_proj: vec3 = .{ @as(f32, 1.0 / @sqrt(3.0)), 0, 0 };
    const a_expected_perp: vec3 = .{ 0, @as(f32, @sqrt(3.0) / 3.0), @as(f32, @sqrt(3.0) / 3.0) };
    const res = decomposeProjection(a_p, a_q);
    try std.testing.expectEqual(a_expected_proj, res.proj);
    try std.testing.expectEqual(a_expected_perp, res.perp);
}

const std = @import("std");
const float = @import("float.zig");
const rotation = @import("rotation.zig");
