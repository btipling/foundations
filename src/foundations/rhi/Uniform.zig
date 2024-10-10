program: u32,
location: c.GLint,

pub const UniformError = error{
    UniformErrorCreationFailed,
};

const Uniform = @This();

pub const empty: Uniform = .{ .program = 0, .location = 0 };

pub fn init(prog: u32, name: []const u8) UniformError!Uniform {
    const loc: c.GLint = c.glGetUniformLocation(@intCast(prog), @ptrCast(name));
    if (loc < 0) {
        std.log.warn("Uniform creation failed for {s}\n", .{name});
        return UniformError.UniformErrorCreationFailed;
    }
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

pub fn setUniform3fv(self: Uniform, v: [3]f32) void {
    const d: [3]c.GLfloat = .{ @floatCast(v[0]), @floatCast(v[1]), @floatCast(v[2]) };
    c.glProgramUniform3fv(@intCast(self.program), self.location, 1, &d);
}

pub fn setUniform4fv(self: Uniform, v: [4]f32) void {
    const d: [4]c.GLfloat = .{ @floatCast(v[0]), @floatCast(v[1]), @floatCast(v[2]), @floatCast(v[3]) };
    c.glProgramUniform4fv(@intCast(self.program), self.location, 1, &d);
}

pub fn setUniform1ui(self: Uniform, v: usize) void {
    c.glProgramUniform1ui(@intCast(self.program), self.location, @intCast(v));
}

pub fn setUniformHandleui64ARB(self: Uniform, handle: c.GLuint64) void {
    c.glProgramUniformHandleui64ARB(@intCast(self.program), self.location, handle);
}

const std = @import("std");
const c = @import("../c.zig").c;
const math = @import("../math/math.zig");
