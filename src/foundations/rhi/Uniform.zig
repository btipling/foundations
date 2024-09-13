program: u32,
location: c.GLint,

const Uniform = @This();

pub const empty: Uniform = .{ .program = 0, .location = 0 };

pub fn init(prog: u32, name: []const u8) Uniform {
    const loc: c.GLint = c.glGetUniformLocation(@intCast(prog), @ptrCast(name));
    return .{
        .program = prog,
        .location = loc,
    };
}

pub fn setUniformMatrix(self: Uniform, m: math.matrix) void {
    const v = math.matrix.array(m);
    c.glProgramUniformMatrix4fv(@intCast(self.program), self.location, 1, c.GL_FALSE, &v);
}

pub fn setUniform1f(self: Uniform, v: f32) void {
    c.glProgramUniform1f(@intCast(self.program), self.location, @floatCast(v));
}

const c = @import("../c.zig").c;
const math = @import("../math/math.zig");
