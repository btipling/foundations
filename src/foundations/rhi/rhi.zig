allocator: std.mem.Allocator,

const RHI = @This();

var rhi: *RHI = undefined;

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

pub fn init(allocator: std.mem.Allocator) void {
    c.glEnable(c.GL_DEBUG_OUTPUT);
    c.glDebugMessageCallback(&messageCallback, null);
    rhi = allocator.create(RHI) catch @panic("OOM");
    rhi.* = .{ .allocator = allocator };
}

pub fn deinit() void {
    rhi.allocator.destroy(rhi);
}

pub fn beginFrame() void {
    const dims = ui.windowDimensions();
    c.glViewport(0, 0, @intCast(dims[0]), @intCast(dims[1]));
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    c.glClearColor(0.6, 0, 1, 1);
}

pub fn createProgram() u32 {
    const p = c.glCreateProgram();
    return @intCast(p);
}

pub fn attachShaders(program: u32, vertex: []const u8, frag: []const u8) void {
    const shaders = [_][]const u8{ vertex, frag };
    const log_len: usize = 1024;

    var i: usize = 0;
    while (i < shaders.len) : (i += 1) {
        const source: [:0]u8 = std.mem.concatWithSentinel(rhi.allocator, .{shaders[i]}) catch @panic("OOM");
        defer rhi.allocator.free(source);

        const shader = c.glCreateShader(c.GL_VERTEX_SHADER);

        c.glShaderSource(shader, 1, @ptrCast(source.ptr));
        c.glCompileShader(shader);

        var success: c.GLint = 0;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
        if (success == c.GL_FALSE) {
            var infoLog: [log_len]u8 = undefined;
            var logSize: c.GLsizei = 0;
            c.glGetShaderInfoLog(shader, @intCast(log_len), &logSize, @ptrCast(&infoLog));
            const len: usize = @intCast(logSize);
            std.debug.panic("ERROR::SHADER::COMPILATION_FAILED\n{s}\n", .{infoLog[0..len]});
        }
        c.glAttachShader(program, shader);
    }
    {
        c.glLinkProgram(program);
        var success: c.GLint = 0;
        c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) {
            var infoLog: [log_len]u8 = undefined;
            var logSize: c.GLsizei = 0;
            c.glGetProgramInfoLog(program, @intCast(log_len), &logSize, @ptrCast(&infoLog));
            const len: usize = @intCast(logSize);
            std.debug.panic("ERROR::SHADER::COMPILATION_FAILED\n{s}\n", .{infoLog[0..len]});
        }
    }
    return;
}

const c = @cImport({
    @cInclude("glad/gl.h");
});

const std = @import("std");
const ui = @import("../ui/ui.zig");
