pub const storage_type = enum(usize) {
    ssbo,
    ubo,
};

pub const ParticlesData = struct {
    ts: [4]f32 = .{ 0, 0, 0, 0 },
    color: [4]f32 = .{ 1, 0, 1, 1 },
};

pub const storage_binding_point = union(storage_type) {
    ssbo: c.GLuint,
    ubo: c.GLuint,
};

pub const bbp_materials: storage_binding_point = .{ .ssbo = 0 };
pub const bbp_lights: storage_binding_point = .{ .ssbo = 1 };
pub const bbp_particles: storage_binding_point = .{ .ssbo = 2 };
pub const bbp_camera: storage_binding_point = .{ .ubo = 0 };
pub const bbp_chapter8_shadows: storage_binding_point = .{ .ubo = 1 };

pub fn Buffer(
    comptime T: type,
    comptime binding_point: storage_binding_point,
    comptime gl_storage_hint: c.GLenum,
) type {
    return struct {
        name: c.GLuint = 0,

        const Self = @This();

        pub fn init(data: T, label: [:0]const u8) Self {
            var name: c.GLuint = 0;
            c.glCreateBuffers(1, @ptrCast(&name));

            var buf: [500]u8 = undefined;
            const label_text = std.fmt.bufPrintZ(&buf, "🐕buffer_{s}", .{label}) catch @panic("bufsize too small");
            c.glObjectLabel(c.GL_BUFFER, name, -1, label_text);

            switch (@typeInfo(T)) {
                .array => |a| {
                    const size: usize = @sizeOf(a.child) * a.len;
                    c.glNamedBufferData(name, @intCast(size), data.ptr, gl_storage_hint);
                },
                .pointer => |p| {
                    const size: usize = switch (p.size) {
                        .Slice => @sizeOf(p.child) * data.len,
                        else => @sizeOf(p.child),
                    };
                    c.glNamedBufferData(name, @intCast(size), data.ptr, gl_storage_hint);
                },
                else => {
                    c.glNamedBufferData(name, @intCast(@sizeOf(T)), &data, gl_storage_hint);
                },
            }

            switch (binding_point) {
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

        pub fn deinit(self: Self) void {
            c.glDeleteBuffers(1, &self.name);
        }

        pub fn update(self: Self, data: T) void {
            switch (@typeInfo(T)) {
                .array => |a| {
                    const size: usize = @sizeOf(a.child) * a.len;
                    c.glNamedBufferData(self.name, @intCast(size), data.ptr, gl_storage_hint);
                },
                .pointer => |p| {
                    const size: usize = switch (p.size) {
                        .Slice => @sizeOf(p.child) * data.len,
                        else => @sizeOf(p.child),
                    };
                    c.glNamedBufferData(self.name, @intCast(size), data.ptr, gl_storage_hint);
                },
                else => {
                    c.glNamedBufferData(self.name, @intCast(@sizeOf(T)), &data, gl_storage_hint);
                },
            }
        }
    };
}

const std = @import("std");
const c = @import("../c.zig").c;
const lighting = @import("../lighting/lighting.zig");
const physics = @import("../physics/physics.zig");
const scenes_list = @import("../scenes/scenes.zig");
