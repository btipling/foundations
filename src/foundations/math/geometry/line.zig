direction: vector.vec3,
moment: vector.vec3,

const Line = @This();

pub fn init(p0: vector.vec3, p1: vector.vec3) Line {
    const direction = vector.normalize(vector.sub(p1, p0));
    return .{
        .direction = direction,
        .moment = vector.crossProduct(p0, direction),
    };
}

pub fn closestPointToOrigin(self: Line) vector.vec3 {
    const vs = vector.dotProduct(self.direction, self.direction);
    const rv = vector.crossProduct(self.direction, self.moment);
    return vector.mul(1.0 / vs, rv);
}

pub fn pointOnLine(self: Line, t: f32) vector.vec3 {
    const p0 = self.closestPointToOrigin();
    return vector.add(p0, vector.mul(t, self.direction));
}

const vector = @import("../vector.zig");
