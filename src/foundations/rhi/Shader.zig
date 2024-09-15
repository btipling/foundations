fragment_shader: fragment_shader_type,
instance_data: bool,
vertex_partials: [max_vertex_partials][]const u8 = undefined,
num_vertex_partials: usize = 0,
program: u32 = 0,

const max_vertex_partials: usize = 10;

pub const fragment_shader_type = enum(usize) {
    color,
    normals,
    texture,
};

pub inline fn single_vertex(vertex_shader: []const u8) [1][]const u8 {
    return [_][]const u8{vertex_shader};
}

const Shader = @This();

const vertex_attrib_header = @embedFile("../shaders/vertex_attrib_header.glsl");
const vertex_attrib_i_data = @embedFile("../shaders/vertex_attrib_i_data.glsl");

const frag_color = @embedFile("../shaders/frag_color.glsl");
const frag_normals = @embedFile("../shaders/frag_normals.glsl");
const frag_texture = @embedFile("../shaders/frag_texture.glsl");

pub fn attach(self: *Shader, allocator: std.mem.Allocator, vertex_partials: []const []const u8) void {
    const frag = switch (self.fragment_shader) {
        .color => frag_color,
        .normals => frag_normals,
        .texture => frag_texture,
    };

    {
        self.vertex_partials[self.num_vertex_partials] = vertex_attrib_header;
        self.num_vertex_partials += 1;
    }
    if (self.instance_data) {
        self.vertex_partials[self.num_vertex_partials] = vertex_attrib_i_data;
        self.num_vertex_partials += 1;
    }
    for (vertex_partials) |partial| {
        self.vertex_partials[self.num_vertex_partials] = partial;
        self.num_vertex_partials += 1;
    }
    const vertex = std.mem.concat(allocator, u8, self.vertex_partials[0..self.num_vertex_partials]) catch @panic("OOM");
    defer allocator.free(vertex);

    const shaders = [_]struct { source: []const u8, shader_type: c.GLenum }{
        .{ .source = vertex, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const log_len: usize = 1024;

    var i: usize = 0;
    while (i < shaders.len) : (i += 1) {
        const source: [:0]u8 = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{shaders[i].source}, 0) catch @panic("OOM");
        defer allocator.free(source);

        const shader = c.glCreateShader(shaders[i].shader_type);

        c.glShaderSource(shader, 1, &[_][*c]const u8{source.ptr}, null);
        c.glCompileShader(shader);

        var success: c.GLint = 0;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
        if (success == c.GL_FALSE) {
            var infoLog: [log_len]u8 = std.mem.zeroes([log_len]u8);
            var logSize: c.GLsizei = 0;
            c.glGetShaderInfoLog(shader, @intCast(log_len), &logSize, @ptrCast(&infoLog));
            const len: usize = @intCast(logSize);
            std.debug.panic("ERROR::SHADER::COMPILATION_FAILED\n{s}\n{s}\n", .{ infoLog[0..len], source });
        }
        c.glAttachShader(@intCast(self.program), shader);
    }
    {
        c.glLinkProgram(@intCast(self.program));
        var success: c.GLint = 0;
        c.glGetProgramiv(@intCast(self.program), c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) {
            var infoLog: [log_len]u8 = std.mem.zeroes([log_len]u8);
            var logSize: c.GLsizei = 0;
            c.glGetProgramInfoLog(@intCast(self.program), @intCast(log_len), &logSize, @ptrCast(&infoLog));
            const len: usize = @intCast(logSize);
            std.debug.panic("ERROR::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..len]});
        }
    }
    return;
}

const std = @import("std");
const c = @import("../c.zig").c;
