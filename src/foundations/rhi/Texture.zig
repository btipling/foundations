name: c.GLuint = 0,
texture_unit: c.GLuint = 0,
handle: c.GLuint64 = 0,
uniform: Uniform = undefined,
wrap_s: c.GLint = c.GL_CLAMP_TO_EDGE,
wrap_t: c.GLint = c.GL_CLAMP_TO_EDGE,
disable_bindless: bool = false,

const Texture = @This();

pub const TextureError = error{
    BindlessHandleCreationFailed,
};

pub fn frag_shader(tx: ?Texture) Shader.fragment_shader_type {
    if (tx) |t| if (!t.disable_bindless) return .bindless;
    return .texture;
}

pub fn init(disable_bindless: bool) TextureError!Texture {
    var t: Texture = .{
        .disable_bindless = disable_bindless,
    };

    if (c.glfwExtensionSupported("GL_ARB_bindless_texture") != 1 or c.glfwExtensionSupported("GL_ARB_bindless_texture") != 1) {
        t.disable_bindless = true;
    }
    return t;
}

pub fn setup(self: *Texture, image: ?*assets.Image, program: u32, uniform_name: []const u8) TextureError!void {
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_2D, 1, @ptrCast(&name));
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_S, self.wrap_s);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_T, self.wrap_t);
    c.glTextureParameteri(name, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_LINEAR);
    c.glTextureParameteri(name, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    if (image) |img| {
        const w: f32 = @floatFromInt(img.width);
        const h: f32 = @floatFromInt(img.height);
        const mip_map_levels: c.GLsizei = @intFromFloat(@ceil(@log2(@max(w, h))));
        c.glTextureStorage2D(name, mip_map_levels, c.GL_RGBA8, @intCast(img.width), @intCast(img.height));
        c.glTextureSubImage2D(
            name,
            0,
            0,
            0,
            @intCast(img.width),
            @intCast(img.height),
            c.GL_RGBA,
            c.GL_UNSIGNED_BYTE,
            img.stb_data.ptr,
        );
    } else {
        const magenta_rgba_color = [4]u8{ 255, 0, 255, 255 };
        c.glTextureStorage2D(name, 1, c.GL_RGBA8, 1, 1);
        c.glTextureSubImage2D(
            name,
            0,
            0,
            0,
            1,
            1,
            c.GL_RGBA,
            c.GL_UNSIGNED_BYTE,
            &magenta_rgba_color,
        );
    }

    c.glGenerateTextureMipmap(name);
    if (c.glfwExtensionSupported("GL_EXT_texture_filter_anisotropic") == 1) {
        var ansio_setting: f32 = 0;
        c.glGetFloatv(c.GL_MAX_TEXTURE_MAX_ANISOTROPY, &ansio_setting);
        c.glTextureParameterf(name, c.GL_TEXTURE_MAX_ANISOTROPY, ansio_setting);
    }

    self.name = name;

    self.uniform = Uniform.init(program, uniform_name);

    if (self.disable_bindless) {
        return;
    }
    // Generate bindless handle
    self.handle = c.glGetTextureHandleARB(self.name);
    if (self.handle == 0) {
        return TextureError.BindlessHandleCreationFailed;
    }

    // Make the texture resident
    c.glMakeTextureHandleResidentARB(self.handle);

    return;
}

pub fn makeNonResident(self: Texture) void {
    if (self.handle != 0) {
        c.glMakeTextureHandleNonResidentARB(self.handle);
    }
}

pub fn deinit(self: Texture) void {
    self.makeNonResident();
    if (self.name != 0) {
        c.glDeleteTextures(1, &self.name);
    }
}

pub fn bind(self: Texture) void {
    if (self.disable_bindless) {
        c.glBindTextureUnit(self.texture_unit, self.name);
        return;
    }
    self.uniform.setUniformHandleui64ARB(self.handle);
}

const std = @import("std");
const c = @import("../c.zig").c;
const Uniform = @import("Uniform.zig");
const assets = @import("../assets/assets.zig");
const Shader = @import("Shader.zig");
