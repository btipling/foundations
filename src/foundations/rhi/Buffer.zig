name: c.GLuint = 0,
block_binding_point: c.GLuint = 0,

const Buffer = @This();

pub const buffer_type = enum(usize) {
    materials,
    lights,
};

pub const buffer_data = union(buffer_type) {
    materials: []lighting.Material,
    lights: []lighting.Light,
};

pub fn init(data: buffer_data) Buffer {
    var name: c.GLuint = 0;
    c.glCreateBuffers(1, @ptrCast(&name));
    const data_size = s: switch (data) {
        inline else => |d| break :s @sizeOf(@TypeOf(d).Child),
    };
    const data_len = s: switch (data) {
        inline else => |d| break :s d.len,
    };
    const ptr = s: switch (data) {
        inline else => |d| break :s d.ptr,
    };
    const block_binding_point = s: switch (buffer_data) {
        .materials => break :s 0,
        .lights => break :s 1,
    };
    const size = data_len * data_size;
    c.glNamedBufferData(name, @intCast(size), ptr, c.GL_STATIC_DRAW);
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
