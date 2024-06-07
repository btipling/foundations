fn messageCallback(
    source: c.GLenum,
    err_type: c.GLenum,
    id: c.GLuint,
    severity: c.GLenum,
    length: c.GLsizei,
    message: [*c]const c.GLchar,
    _: ?*const anyopaque,
) callconv(.C) void {
    const source_str: []const u8 = switch (source) {
        c.GL_DEBUG_SOURCE_API => "API",
        c.GL_DEBUG_SOURCE_WINDOW_SYSTEM => "WINDOW SYSTEM",
        c.GL_DEBUG_SOURCE_SHADER_COMPILER => "SHADER COMPILER",
        c.GL_DEBUG_SOURCE_THIRD_PARTY => "THIRD PARTY",
        c.GL_DEBUG_SOURCE_APPLICATION => "APPLICATION",
        else => "OTHER",
    };
    const type_str: []const u8 = switch (err_type) {
        c.GL_DEBUG_TYPE_ERROR => "ERROR",
        c.GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR => "DEPRECATED_BEHAVIOR",
        c.GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR => "UNDEFINED_BEHAVIOR",
        c.GL_DEBUG_TYPE_PORTABILITY => "PORTABILITY",
        c.GL_DEBUG_TYPE_PERFORMANCE => "PERFORMANCE",
        c.GL_DEBUG_TYPE_MARKER => "MARKER",
        else => "OTHER",
    };
    const severity_str: []const u8 = switch (severity) {
        c.GL_DEBUG_SEVERITY_LOW => "LOW",
        c.GL_DEBUG_SEVERITY_MEDIUM => "MEDIUM",
        c.GL_DEBUG_SEVERITY_HIGH => "HIGH",
        else => "NOTIFICATION",
    };
    const msg_str: []const u8 = message[0..@intCast(length)];
    std.log.err("OpenGL Error: {s}, {s}, {s}, {d} {s}\n", .{
        source_str,
        type_str,
        severity_str,
        id,
        msg_str,
    });
}

pub fn init() void {
    c.glEnable(c.GL_DEBUG_OUTPUT);
    c.glDebugMessageCallback(&messageCallback, null);
}

pub fn beginFrame() void {
    const dims = ui.windowDimensions();
    c.glViewport(0, 0, @intCast(dims[0]), @intCast(dims[1]));
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    c.glClearColor(0.6, 0, 1, 1);
}

const c = @cImport({
    @cInclude("glad/gl.h");
});

const std = @import("std");
const ui = @import("../ui/ui.zig");
