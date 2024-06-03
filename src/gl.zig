const c = @cImport({
    @cInclude("GL/glcorearb.h");
});

pub const GLError = error{
    NotFound,
};

pub fn loadAll() !void {
    try load("glViewport", .{&glViewport});
    try load("glClearColor", .{&glClearColor});
    try load("glClear", .{&glClear});
}

fn load(name: []const u8, bindings: anytype) !void {
    const ProcType = @typeInfo(@TypeOf(bindings.@"0")).Pointer.child;
    const addr = glfw.getProcAddress(ProcType, name) catch return GLError.NotFound;
    inline for (bindings) |b| {
        b.* = addr;
    }
}

pub var glViewport: *const fn (x: c_int, y: c_int, width: isize, height: isize) callconv(.C) void = undefined;
pub var glClearColor: *const fn (red: f32, green: f32, blue: f32, alpha: f32) callconv(.C) void = undefined;
pub var glClear: *const fn (mask: c_int) callconv(.C) void = undefined;

pub const GL_COLOR_BUFFER_BIT = c.GL_COLOR_BUFFER_BIT;
pub const GL_DEPTH_BUFFER_BIT = c.GL_DEPTH_BUFFER_BIT;

const glfw = @import("glfw.zig");
