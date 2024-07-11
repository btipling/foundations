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
    c.glClipControl(c.GL_LOWER_LEFT, c.GL_NEGATIVE_ONE_TO_ONE);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glFrontFace(c.GL_CCW);
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
    c.glClearColor(0, 0, 0, 1);
}

pub fn createProgram() u32 {
    const p = c.glCreateProgram();
    return @intCast(p);
}

pub fn createVAO() u32 {
    var vao: c.GLuint = 0;
    c.glCreateVertexArrays(1, @ptrCast(&vao));
    return @intCast(vao);
}

pub const attributeData = struct {
    position: [3]f32,
    color: [4]f32,
    normals: [3]f32 = .{ 0, 0, 0 },
};

pub const instanceData = struct {
    t_column0: [4]f32,
    t_column1: [4]f32,
    t_column2: [4]f32,
    t_column3: [4]f32,
    color: [4]f32,
};

pub fn attachBuffer(
    data: []attributeData,
) struct { vao: u32, buffer: u32 } {
    var buffer: c.GLuint = 0;
    const bind_index: usize = 0;
    c.glCreateBuffers(1, @ptrCast(&buffer));

    const data_size = @sizeOf(attributeData);
    const size = data.len * data_size;
    updateNamedBuffer(buffer, size, c.GL_STATIC_DRAW, data);

    var vao: c.GLuint = 0;
    c.glCreateVertexArrays(1, @ptrCast(&vao));
    c.glVertexArrayVertexBuffer(vao, bind_index, buffer, 0, @intCast(data_size));
    defineVertexData(vao);

    return .{ .vao = vao, .buffer = buffer };
}

pub fn attachInstancedBuffer(
    vertex_data: []attributeData,
    instance_data: []instanceData,
) struct { vao: u32, buffer: u32 } {
    var buffer: c.GLuint = 0;
    const vertex_bind_index: usize = 0;
    const instance_bind_index: usize = 0;
    c.glCreateBuffers(1, @ptrCast(&buffer));

    const vertex_data_size = vertex_data.len * @sizeOf(attributeData);
    const instance_data_size = instance_data.len * @sizeOf(instanceData);
    updateNamedBuffer(buffer, vertex_data_size + instance_data_size, c.GL_STATIC_DRAW, vertex_data);
    c.glNamedBufferSubData(buffer, @intCast(vertex_data_size), @intCast(instance_data_size), instance_data.ptr);

    var vao: c.GLuint = 0;
    c.glCreateVertexArrays(1, @ptrCast(&vao));
    c.glVertexArrayVertexBuffer(vao, vertex_bind_index, buffer, 0, @intCast(vertex_data_size));
    c.glVertexArrayVertexBuffer(vao, instance_bind_index, buffer, @intCast(vertex_data_size), @intCast(instance_data_size));
    defineVertexData(vao);
    defineInstanceData(vao, instance_bind_index, vertex_data_size, 3);

    return .{ .vao = vao, .buffer = buffer };
}

fn defineVertexData(vao: u32) void {
    inline for (0..3) |i| c.glEnableVertexArrayAttrib(vao, i);

    c.glVertexArrayAttribFormat(vao, 0, 3, c.GL_FLOAT, c.GL_FALSE, @offsetOf(attributeData, "position"));
    c.glVertexArrayAttribFormat(vao, 1, 4, c.GL_FLOAT, c.GL_FALSE, @offsetOf(attributeData, "color"));
    c.glVertexArrayAttribFormat(vao, 2, 3, c.GL_FLOAT, c.GL_FALSE, @offsetOf(attributeData, "normals"));

    inline for (0..3) |i| c.glVertexArrayAttribBinding(vao, i, 0);
}

fn defineInstanceData(vao: u32, instance_bind_index: usize, offset: usize, location_offset: usize) void {
    c.glVertexArrayBindingDivisor(vao, @intCast(instance_bind_index), 1);

    inline for (1..6) |i| c.glEnableVertexArrayAttrib(vao, @intCast(location_offset + i));

    c.glVertexArrayAttribFormat(vao, @intCast(location_offset + 1), 4, c.GL_FLOAT, c.GL_FALSE, @intCast(offset + @offsetOf(instanceData, "t_column0")));
    c.glVertexArrayAttribFormat(vao, @intCast(location_offset + 2), 4, c.GL_FLOAT, c.GL_FALSE, @intCast(offset + @offsetOf(instanceData, "t_column1")));
    c.glVertexArrayAttribFormat(vao, @intCast(location_offset + 3), 4, c.GL_FLOAT, c.GL_FALSE, @intCast(offset + @offsetOf(instanceData, "t_column2")));
    c.glVertexArrayAttribFormat(vao, @intCast(location_offset + 4), 4, c.GL_FLOAT, c.GL_FALSE, @intCast(offset + @offsetOf(instanceData, "t_column3")));
    c.glVertexArrayAttribFormat(vao, @intCast(location_offset + 5), 4, c.GL_FLOAT, c.GL_FALSE, @intCast(offset + @offsetOf(instanceData, "color")));

    inline for (1..6) |i| c.glVertexArrayAttribBinding(vao, @intCast(location_offset + i), 0);
}

pub fn updateNamedBuffer(name: u32, size: usize, draw_hint: c.GLenum, data: []attributeData) void {
    c.glNamedBufferData(name, @intCast(size), null, draw_hint);
    c.glNamedBufferSubData(name, 0, @intCast(size), data.ptr);
}

pub fn initEBO(indices: []const u32, vao: u32) u32 {
    var ebo: u32 = undefined;
    c.glCreateBuffers(1, @ptrCast(&ebo));

    const size = @as(isize, @intCast(indices.len * @sizeOf(u32)));
    const indicesptr: *const anyopaque = indices.ptr;
    c.glNamedBufferData(ebo, size, indicesptr, c.GL_STATIC_DRAW);
    c.glVertexArrayElementBuffer(vao, ebo);
    return ebo;
}

pub fn attachShaders(program: u32, vertex: []const u8, frag: []const u8) void {
    const shaders = [_]struct { source: []const u8, shader_type: c.GLenum }{
        .{ .source = vertex, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const log_len: usize = 1024;

    var i: usize = 0;
    while (i < shaders.len) : (i += 1) {
        const source: [:0]u8 = std.mem.concatWithSentinel(rhi.allocator, u8, &[_][]const u8{shaders[i].source}, 0) catch @panic("OOM");
        defer rhi.allocator.free(source);

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
        c.glAttachShader(@intCast(program), shader);
    }
    {
        c.glLinkProgram(@intCast(program));
        var success: c.GLint = 0;
        c.glGetProgramiv(@intCast(program), c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) {
            var infoLog: [log_len]u8 = std.mem.zeroes([log_len]u8);
            var logSize: c.GLsizei = 0;
            c.glGetProgramInfoLog(@intCast(program), @intCast(log_len), &logSize, @ptrCast(&infoLog));
            const len: usize = @intCast(logSize);
            std.debug.panic("ERROR::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..len]});
        }
    }
    return;
}

pub fn drawArrays(program: u32, vao: u32, count: usize) void {
    c.glUseProgram(@intCast(program));
    c.glBindVertexArray(vao);
    c.glDrawArrays(c.GL_TRIANGLES, 0, @intCast(count));
}

pub fn drawElements(m: mesh, element: mesh.element) void {
    c.glUseProgram(@intCast(m.program));
    c.glBindVertexArray(m.vao);
    c.glDrawElements(element.primitive, @intCast(element.count), element.format, null);
}

pub fn drawInstances(m: mesh, instanced: mesh.instanced) void {
    c.glUseProgram(@intCast(m.program));
    c.glBindVertexArray(m.vao);
    c.glDrawElementsInstanced(
        instanced.primitive,
        @intCast(instanced.index_count),
        @intCast(instanced.format),
        null,
        @intCast(instanced.instances_count),
    );
}

pub fn drawPoints(program: u32, vao: u32, count: usize) void {
    c.glUseProgram(@intCast(program));
    c.glBindVertexArray(vao);
    c.glPointSize(30.0);
    c.glDrawArrays(c.GL_POINTS, 0, @intCast(count));
    c.glPointSize(1.0);
}

pub fn setUniform1f(program: u32, name: []const u8, v: f32) void {
    const location: c.GLint = c.glGetUniformLocation(@intCast(program), @ptrCast(name));
    c.glProgramUniform1f(@intCast(program), location, @floatCast(v));
}

pub fn setUniformVec4(program: u32, name: []const u8, v: math.vector.vec4) void {
    const location: c.GLint = c.glGetUniformLocation(@intCast(program), @ptrCast(name));
    c.glProgramUniform4f(
        @intCast(program),
        location,
        @floatCast(v[0]),
        @floatCast(v[1]),
        @floatCast(v[2]),
        @floatCast(v[3]),
    );
}

pub fn setUniformMatrix(program: u32, name: []const u8, m: math.matrix) void {
    const v = math.matrix.array(m);
    const location: c.GLint = c.glGetUniformLocation(@intCast(program), @ptrCast(name));
    c.glProgramUniformMatrix4fv(@intCast(program), location, 1, c.GL_FALSE, &v);
}

pub fn setUniformVec2(program: u32, name: []const u8, v: math.vector.vec2) void {
    const location: c.GLint = c.glGetUniformLocation(@intCast(program), @ptrCast(name));
    c.glProgramUniform2f(@intCast(program), location, @floatCast(v[0]), @floatCast(v[1]));
}

pub fn deletePrimitive(program: u32, vao: u32, buffer: u32) void {
    c.glDeleteProgram(program);
    c.glDeleteVertexArrays(1, @ptrCast(&vao));
    if (buffer != 0) c.glDeleteBuffers(1, @ptrCast(&buffer));
}

pub fn deleteMesh(m: mesh) void {
    c.glDeleteProgram(m.program);
    c.glDeleteVertexArrays(1, @ptrCast(&m.vao));
    switch (m.instance_type) {
        .element => |e| c.glDeleteBuffers(1, e.ebo),
        else => {},
    }
    if (m.buffer != 0) c.glDeleteBuffers(1, @ptrCast(&m.buffer));
}

pub fn drawObjects(objects: []object.object) void {
    var i: usize = 0;
    while (i < objects.len) : (i += 1) {
        switch (objects[i]) {
            inline else => |o| drawMesh(o.mesh),
        }
    }
}

pub fn drawMesh(m: mesh) void {
    if (m.linear_colorspace) {
        c.glEnable(c.GL_FRAMEBUFFER_SRGB);
    }
    if (m.wire_mesh) {
        c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
    }
    switch (m.instance_type) {
        .array => |a| drawArrays(m.program, m.vao, a.count),
        .element => |e| drawElements(m, e),
        .instanced => |i| drawInstances(m, i),
    }
    if (m.linear_colorspace) {
        c.glDisable(c.GL_FRAMEBUFFER_SRGB);
    }
    if (m.wire_mesh) {
        c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
    }
}

pub fn deleteObjects(objects: []object.object) void {
    var i: usize = 0;
    while (i < objects.len) : (i += 1) {
        switch (objects[i]) {
            inline else => |o| deleteMesh(o.mesh),
        }
    }
}

const std = @import("std");
const c = @import("../c.zig").c;
const ui = @import("../ui/ui.zig");
const math = @import("../math/math.zig");
const object = @import("../object/object.zig");

pub const mesh = @import("./mesh.zig");
