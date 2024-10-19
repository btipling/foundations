fragment_shader: fragment_shader_type = .custom,
instance_data: bool,
vertex_partials: [max_vertex_partials][]const u8 = undefined,
num_vertex_partials: usize = 0,
frag_partials: [max_frag_partials][]const u8 = undefined,
num_frag_partials: usize = 0,
xup: xup_type = .none,
lighting: lighting_type = .none,
frag_body: ?[]const u8 = null,
program: u32 = 0,
shadowmaps: bool = false,
cubemap: bool = false,
bindless_vertex: bool = false,

const max_frag_partials: usize = 15;
const max_vertex_partials: usize = 15;
const log_len: usize = 1024 * 2;

pub const fragment_shader_type = enum(usize) {
    color,
    normal,
    texture,
    bindless,
    lighting,
    shadow,
    custom,
    disabled,
};

pub const lighting_type = enum(usize) {
    none,
    gauraud,
    phong,
    blinn_phong,
};

pub const xup_type = enum(usize) {
    none,
    wavefront,
};

pub inline fn single_vertex(vertex_shader: []const u8) [1][]const u8 {
    return [_][]const u8{vertex_shader};
}

const Shader = @This();

const vertex_header = @embedFile("../shaders/vertex_header.glsl");
const vertex_bindless_header = @embedFile("../shaders/vertex_bindless_header.glsl");
const vertex_attrib_header = @embedFile("../shaders/vertex_attrib_header.glsl");
const vertex_attrib_i_data = @embedFile("../shaders/vertex_attrib_i_data.glsl");
const vertex_subheader = @embedFile("../shaders/vertex_subheader.glsl");

const vertex_xup = @embedFile("../shaders/vertex_xup.glsl");
const vertex_xup_wavefront = @embedFile("../shaders/vertex_xup_wavefront.glsl");

const lighting_glsl = @embedFile("../shaders/lighting.glsl");

const frag_header = @embedFile("../shaders/frag_header.glsl");
const frag_bindless_shadowmaps = @embedFile("../shaders/frag_bindless_shadowmaps.glsl");
const frag_texture_shadowmaps = @embedFile("../shaders/frag_texture_shadowmaps.glsl");
const frag_bindless_header = @embedFile("../shaders/frag_bindless_header.glsl");
const frag_texture_header = @embedFile("../shaders/frag_texture_header.glsl");
const frag_subheader = @embedFile("../shaders/frag_subheader.glsl");
const frag_color = @embedFile("../shaders/frag_color.glsl");
const frag_normals = @embedFile("../shaders/frag_normals.glsl");
const frag_texture = @embedFile("../shaders/frag_texture.glsl");
const frag_cubemap = @embedFile("../shaders/frag_cubemap.glsl");
const frag_bindless = @embedFile("../shaders/frag_bindless.glsl");
const frag_shadow = @embedFile("../shaders/shadow_frag.glsl");

const frag_phong_lighting = @embedFile("../shaders/frag_phong_lighting.glsl");
const frag_blinn_phong_lighting = @embedFile("../shaders/frag_blinn_phong_lighting.glsl");

pub fn attach(self: *Shader, allocator: std.mem.Allocator, vertex_partials: []const []const u8) void {
    {
        self.vertex_partials[self.num_vertex_partials] = vertex_header;
        self.num_vertex_partials += 1;
    }
    if (self.bindless_vertex) {
        self.vertex_partials[self.num_vertex_partials] = vertex_bindless_header;
        self.num_vertex_partials += 1;
    }
    {
        self.vertex_partials[self.num_vertex_partials] = vertex_attrib_header;
        self.num_vertex_partials += 1;
    }
    {
        self.vertex_partials[self.num_vertex_partials] = vertex_subheader;
        self.num_vertex_partials += 1;
    }
    {
        const xup = switch (self.xup) {
            .wavefront => vertex_xup_wavefront,
            else => vertex_xup,
        };
        self.vertex_partials[self.num_vertex_partials] = xup;
        self.num_vertex_partials += 1;
    }
    if (self.instance_data) {
        self.vertex_partials[self.num_vertex_partials] = vertex_attrib_i_data;
        self.num_vertex_partials += 1;
    }
    if (self.lighting != .none) {
        self.vertex_partials[self.num_vertex_partials] = lighting_glsl;
        self.num_vertex_partials += 1;
    }
    for (vertex_partials) |partial| {
        self.vertex_partials[self.num_vertex_partials] = partial;
        self.num_vertex_partials += 1;
    }
    const vertex = std.mem.concat(allocator, u8, self.vertex_partials[0..self.num_vertex_partials]) catch @panic("OOM");
    defer allocator.free(vertex);

    if (self.fragment_shader != .disabled) {
        {
            self.frag_partials[self.num_frag_partials] = frag_header;
            self.num_frag_partials += 1;
        }
        if (self.fragment_shader == .bindless) {
            self.frag_partials[self.num_frag_partials] = frag_bindless_header;
            self.num_frag_partials += 1;
            if (self.shadowmaps) {
                self.frag_partials[self.num_frag_partials] = frag_bindless_shadowmaps;
                self.num_frag_partials += 1;
            }
        } else if (self.fragment_shader == .texture) {
            self.frag_partials[self.num_frag_partials] = frag_texture_header;
            self.num_frag_partials += 1;
            if (self.shadowmaps) {
                self.frag_partials[self.num_frag_partials] = frag_texture_shadowmaps;
                self.num_frag_partials += 1;
            }
        }
        {
            self.frag_partials[self.num_frag_partials] = frag_subheader;
            self.num_frag_partials += 1;
        }
        if (self.lighting != .none) {
            self.frag_partials[self.num_frag_partials] = lighting_glsl;
            self.num_frag_partials += 1;
        }
    }
    if (self.frag_body) |frag_body| {
        self.frag_partials[self.num_frag_partials] = frag_body;
        self.num_frag_partials += 1;
    } else {
        const frag_body: ?[]const u8 = switch (self.fragment_shader) {
            .color => frag_color,
            .normal => frag_normals,
            .texture => if (self.cubemap) frag_cubemap else frag_texture,
            .bindless => frag_bindless,
            .lighting => switch (self.lighting) {
                .gauraud => frag_color,
                .phong => frag_phong_lighting,
                else => frag_blinn_phong_lighting,
            },
            .shadow => frag_shadow,
            .custom => null,
            .disabled => null,
        };
        if (frag_body) |fb| {
            self.frag_partials[self.num_frag_partials] = fb;
            self.num_frag_partials += 1;
        }
    }
    const frag = std.mem.concat(allocator, u8, self.frag_partials[0..self.num_frag_partials]) catch @panic("OOM");
    defer allocator.free(frag);

    const shaders = [_]struct { source: []const u8, shader_type: c.GLenum }{
        .{ .source = vertex, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };

    var i: usize = 0;
    while (i < shaders.len) : (i += 1) {
        const source: [:0]u8 = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{shaders[i].source}, 0) catch @panic("OOM");
        defer allocator.free(source);

        const shader = c.glCreateShader(shaders[i].shader_type);

        self.attachToProgram(shader, source);
    }
    self.link();
    return;
}

pub fn attachToProgram(self: Shader, shader: c.GLenum, source: []const u8) void {
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

pub fn link(self: Shader) void {
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

const std = @import("std");
const c = @import("../c.zig").c;
