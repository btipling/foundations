name: c.GLuint = 0,
texture_unit: c.GLuint = 0,

const Texture = @This();

pub fn init(image: *assets.Image) Texture {
    var t: Texture = .{};
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_2D, 1, @ptrCast(&name));
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
    c.glTextureParameteri(name, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_LINEAR);
    c.glTextureParameteri(name, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    c.glTextureStorage2D(name, 1, c.GL_RGBA8, @intCast(image.width), @intCast(image.height));
    c.glTextureSubImage2D(
        name,
        0,
        0,
        0,
        @intCast(image.width),
        @intCast(image.height),
        c.GL_RGBA,
        c.GL_UNSIGNED_BYTE,
        image.stb_data.ptr,
    );

    c.glGenerateTextureMipmap(name);
    if (c.glfwExtensionSupported("GL_EXT_texture_filter_anisotropic") == 1) {
        var ansio_setting: f32 = 0;
        c.glGetFloatv(c.GL_MAX_TEXTURE_MAX_ANISOTROPY, &ansio_setting);
        c.glTextureParameterf(name, c.GL_TEXTURE_MAX_ANISOTROPY, ansio_setting);
    }

    t.name = name;
    return t;
}

pub fn bind(self: Texture) void {
    c.glBindTextureUnit(self.texture_unit, self.name);
}

const std = @import("std");
const c = @import("../c.zig").c;
const assets = @import("../assets/assets.zig");
