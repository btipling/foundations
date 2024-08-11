v0: vector.vec3,
v1: vector.vec3,
v2: vector.vec3,
e0: vector.vec3,
e1: vector.vec3,
e2: vector.vec3,
normal: vector.vec3,

const Triangle = @This();

pub fn init(v0: vector.vec3, v1: vector.vec3, v2: vector.vec3) Triangle {
    const e0 = vector.sub(v2, v1);
    const e1 = vector.sub(v0, v2);
    const e2 = vector.sub(v1, v0);
    const ortho_v = vector.crossProduct(e0, e1);
    const n = vector.normalize(ortho_v);
    return .{
        .v0 = v0,
        .v1 = v1,
        .v2 = v2,
        .e0 = e0,
        .e1 = e1,
        .e2 = e2,
        .normal = n,
    };
}

pub fn area(self: Triangle) f32 {
    return vector.magnitude(vector.crossProduct(self.e0, self.e1)) / 2.0;
}

pub fn barycentricCooordinate(self: Triangle, point: vector.vec3) vector.vec3 {
    const d0 = vector.sub(point, self.v0);
    const d1 = vector.sub(point, self.v1);
    const d2 = vector.sub(point, self.v2);
    const area_t = vector.dotProduct(vector.crossProduct(self.e0, self.e1), self.normal);
    return .{
        vector.dotProduct(vector.crossProduct(self.e0, d2), self.normal) / area_t,
        vector.dotProduct(vector.crossProduct(self.e1, d0), self.normal) / area_t,
        vector.dotProduct(vector.crossProduct(self.e2, d1), self.normal) / area_t,
    };
}

pub fn centerOfGravity(self: Triangle) vector.vec3 {
    var rv: vector.vec3 = self.v0;
    rv = vector.add(rv, self.v1);
    rv = vector.add(rv, self.v2);
    return vector.mul(1.0 / 3.0, rv);
}

pub fn perimiter(self: Triangle) f32 {
    const l0 = vector.magnitude(self.e0);
    const l1 = vector.magnitude(self.e1);
    const l2 = vector.magnitude(self.e2);
    return l0 + l1 + l2;
}

pub fn incenter(self: Triangle) vector.vec3 {
    const l0 = vector.magnitude(self.e0);
    const l1 = vector.magnitude(self.e1);
    const l2 = vector.magnitude(self.e2);
    var rv: vector.vec3 = vector.mul(l0, self.v0);
    rv = vector.add(rv, vector.mul(l1, self.v1));
    rv = vector.add(rv, vector.mul(l2, self.v2));
    return vector.mul(1.0 / (l0 + l1 + l2), rv);
}

pub fn incribedCircle(self: Triangle) Circle {
    const c = self.incenter();
    const s = self.perimiter() / 2;
    const a = self.area();
    return .{
        .center = geometry.xUpLeftHandedTo2D(c),
        .radius = a / s,
    };
}

pub fn circumCenter(self: Triangle) f32 {
    const d0: f32 = vector.dotProduct(vector.negate(self.e1), self.e2);
    const d1: f32 = vector.dotProduct(vector.negate(self.e2), self.e0);
    const d2: f32 = vector.dotProduct(vector.negate(self.e0), self.e1);
    const c0: f32 = d1 * d2;
    const c1: f32 = d2 * d0;
    const c2: f32 = d0 * d1;
    const c: f32 = c0 + c1 + c2;
    var cc_n = vector.mul(vector.add(c1, c2), self.v0);
    cc_n = vector.add(cc_n, vector.mul(vector.add(c2, c0), self.v1));
    cc_n = vector.add(cc_n, vector.mul(vector.add(c0, c1), self.v2));
    return vector.mul(1 / 2 * c, cc_n);
}

pub fn circumscribedCircle(self: Triangle) Circle {
    const d0: f32 = vector.dotProduct(vector.negate(self.e1), self.e2);
    const d1: f32 = vector.dotProduct(vector.negate(self.e2), self.e0);
    const d2: f32 = vector.dotProduct(vector.negate(self.e0), self.e1);
    const c0: f32 = d1 * d2;
    const c1: f32 = d2 * d0;
    const c2: f32 = d0 * d1;
    const c: f32 = c0 + c1 + c2;
    var cc_n = vector.mul(c1 + c2, self.v0);
    cc_n = vector.add(cc_n, vector.mul(c2 + c0, self.v1));
    cc_n = vector.add(cc_n, vector.mul(c0 + c1, self.v2));
    const cc = vector.mul(1 / (2 * c), cc_n);
    const r = @sqrt((d0 + d1) * (d1 + d2) * (d2 + d0) / c) / 2;
    const center = geometry.xUpLeftHandedTo2D(cc);
    return .{
        .center = center,
        .radius = r,
    };
}

pub fn vectorAt(self: Triangle, i: usize) vector.vec3 {
    return switch (i) {
        0 => self.v0,
        1 => self.v1,
        2 => self.v2,
        else => undefined,
    };
}

const std = @import("std");
const geometry = @import("geometry.zig");
const Circle = @import("Circle.zig");
const vector = @import("../vector.zig");
