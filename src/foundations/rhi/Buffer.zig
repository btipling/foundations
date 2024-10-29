name: c.GLuint = 0,

const Buffer = @This();

pub const buffer_type = enum(usize) {
    materials,
    lights,
    camera,
    chapter8_shadows,
    particles,
};

pub const buffer_data = union(buffer_type) {
    materials: []const lighting.Material,
    lights: []const lighting.Light,
    camera: physics.camera.CameraData,
    chapter8_shadows: scenes_list.cgpoc.chapter8.Shadows.SceneData,
    particles: []const ParticlesData,
};

pub const ParticlesData = struct {
    ts: [4]f32 = .{ 0, 0, 0, 0 },
    color: [4]f32 = .{ 1, 0, 1, 1 },
};

pub const storage_type = enum(usize) {
    ssbo,
    ubo,
};

pub const storage_binding_point = union(storage_type) {
    ssbo: c.GLuint,
    ubo: c.GLuint,
};

pub fn init(data: buffer_data, label: [:0]const u8) Buffer {
    var name: c.GLuint = 0;
    c.glCreateBuffers(1, @ptrCast(&name));

    var buf: [500]u8 = undefined;
    const label_text = std.fmt.bufPrintZ(&buf, "🐕buffer_{s}", .{label}) catch @panic("bufsize too small");
    c.glObjectLabel(c.GL_BUFFER, name, -1, label_text);
    const data_size: usize = switch (data) {
        .materials => @sizeOf(lighting.Material),
        .lights => @sizeOf(lighting.Light),
        .camera => @sizeOf(physics.camera.CameraData),
        .chapter8_shadows => @sizeOf(scenes_list.cgpoc.chapter8.Shadows.SceneData),
        .particles => @sizeOf(ParticlesData),
    };
    const data_len: usize = switch (data) {
        .materials => |d| d.len,
        .lights => |d| d.len,
        .particles => |d| d.len,
        else => 1,
    };
    const block_binding_point: storage_binding_point = switch (data) {
        .materials => .{ .ssbo = 0 },
        .lights => .{ .ssbo = 1 },
        .particles => .{ .ssbo = 2 },
        .camera => .{ .ubo = 0 },
        .chapter8_shadows => .{ .ubo = 1 },
    };
    const size = data_len * data_size;
    switch (data) {
        .materials => |d| {
            c.glNamedBufferData(name, @intCast(size), d.ptr, c.GL_STATIC_DRAW);
        },
        .lights => |d| {
            c.glNamedBufferData(name, @intCast(size), d.ptr, c.GL_STATIC_DRAW);
        },
        .particles => |d| {
            c.glNamedBufferData(name, @intCast(size), d.ptr, c.GL_DYNAMIC_DRAW);
        },
        else => |d| {
            c.glNamedBufferData(name, @intCast(size), &d, c.GL_DYNAMIC_DRAW);
        },
    }
    switch (block_binding_point) {
        .ssbo => |bp| {
            c.glBindBufferBase(c.GL_SHADER_STORAGE_BUFFER, bp, name);
        },
        .ubo => |bp| {
            c.glBindBufferBase(c.GL_UNIFORM_BUFFER, bp, name);
        },
    }
    return .{
        .name = name,
    };
}

pub fn deinit(self: Buffer) void {
    c.glDeleteBuffers(1, &self.name);
}

pub fn update(self: Buffer, data: buffer_data) void {
    const data_size: usize = switch (data) {
        .camera => @sizeOf(physics.camera.CameraData),
        .chapter8_shadows => @sizeOf(scenes_list.cgpoc.chapter8.Shadows.SceneData),
        .particles => @sizeOf(ParticlesData),
        else => 0,
    };
    const data_len: usize = switch (data) {
        .camera => 1,
        .chapter8_shadows => 1,
        .particles => |d| d.len,
        else => 0,
    };
    const size = data_len * data_size;
    switch (data) {
        .camera => |d| {
            c.glNamedBufferData(self.name, @intCast(size), &d, c.GL_DYNAMIC_DRAW);
        },
        .chapter8_shadows => |d| {
            c.glNamedBufferData(self.name, @intCast(size), &d, c.GL_DYNAMIC_DRAW);
        },
        .particles => |d| {
            c.glNamedBufferData(self.name, @intCast(size), d.ptr, c.GL_DYNAMIC_DRAW);
        },
        else => {},
    }
}

const std = @import("std");
const c = @import("../c.zig").c;
const lighting = @import("../lighting/lighting.zig");
const physics = @import("../physics/physics.zig");
const scenes_list = @import("../scenes/scenes.zig");
