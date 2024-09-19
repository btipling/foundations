name: c.GLuint = 0,
block_binding_point: c.GLuint = 0,

const Buffer = @This();

pub const buffer_type = enum(usize) {
    materials,
    lights,
};

pub const buffer_data = union(buffer_type) {
    materials: []const lighting.Material,
    lights: []const lighting.Light,
};

pub fn init(data: buffer_data) Buffer {
    var name: c.GLuint = 0;
    c.glCreateBuffers(1, @ptrCast(&name));
    const data_size: usize = s: switch (data) {
        .materials => break :s @sizeOf(lighting.Material),
        .lights => break :s @sizeOf(lighting.Light),
    };
    const data_len: usize = s: switch (data) {
        .materials => |d| break :s d.len,
        .lights => |d| break :s d.len,
    };
    const block_binding_point: u32 = s: switch (data) {
        .materials => break :s 0,
        .lights => break :s 1,
    };
    const size = data_len * data_size;
    switch (data) {
        .materials => |d| {
            c.glNamedBufferData(name, @intCast(size), d.ptr, c.GL_STATIC_DRAW);
        },
        .lights => |d| {
            c.glNamedBufferData(name, @intCast(size), d.ptr, c.GL_STATIC_DRAW);
        },
    }
    c.glBindBufferBase(c.GL_SHADER_STORAGE_BUFFER, block_binding_point, name);
    return .{
        .name = name,
        .block_binding_point = block_binding_point,
    };
}

pub fn deinit(self: Buffer) void {
    if (self.name != 0) {
        c.glDeleteBuffers(1, &self.name);
    }
}

const c = @import("../c.zig").c;
const lighting = @import("../lighting/lighting.zig");
