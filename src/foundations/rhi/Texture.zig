name: c.GLuint = 0,
texture_unit: c.GLuint = 0,
handle: c.GLuint64 = 0,
uniforms: [100]Uniform = undefined,
num_uniforms: usize = 0,
wrap_s: c.GLint = c.GL_CLAMP_TO_EDGE,
wrap_t: c.GLint = c.GL_CLAMP_TO_EDGE,
disable_bindless: bool = false,

const Texture = @This();

pub const TextureError = error{
    BindlessHandleCreationFailed,
    UniformCreationFailed,
};

pub fn disableBindless(disable_bindless: bool) bool {
    if (disable_bindless) return true;
    return c.glfwExtensionSupported("GL_ARB_bindless_texture") != 1;
}

pub fn frag_shader(tx: ?Texture) Shader.fragment_shader_type {
    if (tx) |t| if (!t.disable_bindless) return .bindless;
    return .texture;
}

pub fn init(disable_bindless: bool) TextureError!Texture {
    const t: Texture = .{
        .disable_bindless = disableBindless(disable_bindless),
    };

    return t;
}

pub fn deinit(self: Texture) void {
    self.makeNonResident();
    if (self.name != 0) {
        c.glDeleteTextures(1, &self.name);
    }
}

pub fn setupShadow(self: *Texture, width: usize, height: usize, label: [:0]const u8) TextureError!void {
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_2D, 1, @ptrCast(&name));
    var buf: [500]u8 = undefined;
    const label_text = std.fmt.bufPrintZ(&buf, "👤shadow_texture_{s}", .{label}) catch @panic("bufsize too small");
    c.glObjectLabel(c.GL_TEXTURE, name, -1, label_text);
    c.glTextureStorage2D(name, 1, c.GL_DEPTH_COMPONENT32, @intCast(width), @intCast(height));
    c.glTextureParameteri(name, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTextureParameteri(name, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    c.glTextureParameteri(name, c.GL_TEXTURE_COMPARE_MODE, c.GL_COMPARE_REF_TO_TEXTURE);
    c.glTextureParameteri(name, c.GL_TEXTURE_COMPARE_FUNC, c.GL_LEQUAL);
    const borderColor: [4]c.GLfloat = .{ 1.0, 1.0, 1.0, 1.0 };
    c.glTextureParameterfv(name, c.GL_TEXTURE_BORDER_COLOR, &borderColor);

    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_BORDER);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_BORDER);

    self.name = name;

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
pub fn setupRenderTexture(self: *Texture, width: usize, height: usize, label: [:0]const u8) TextureError!void {
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_2D, 1, @ptrCast(&name));
    var buf: [500]u8 = undefined;
    const label_text = std.fmt.bufPrintZ(&buf, "🎨render_texture_{s}", .{label}) catch @panic("bufsize too small");
    c.glObjectLabel(c.GL_TEXTURE, name, -1, label_text);
    c.glTextureStorage2D(name, 1, c.GL_RGBA8, @intCast(width), @intCast(height));
    c.glTextureParameteri(name, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTextureParameteri(name, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    self.name = name;

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

pub fn setupDepthTexture(self: *Texture, width: usize, height: usize, label: [:0]const u8) TextureError!void {
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_2D, 1, @ptrCast(&name));
    var buf: [500]u8 = undefined;
    const label_text = std.fmt.bufPrintZ(&buf, "⏬depth_texture_{s}", .{label}) catch @panic("bufsize too small");
    c.glObjectLabel(c.GL_TEXTURE, name, -1, label_text);
    c.glTextureStorage2D(name, 1, c.GL_DEPTH_COMPONENT24, @intCast(width), @intCast(height));
    c.glTextureParameteri(name, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTextureParameteri(name, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    self.name = name;
    return;
}

pub fn setup(self: *Texture, image: ?*assets.Image, program: u32, uniform_name: []const u8, label: [:0]const u8) TextureError!void {
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_2D, 1, @ptrCast(&name));
    var buf: [500]u8 = undefined;
    const label_text = std.fmt.bufPrintZ(&buf, "🖼️texture_{s}", .{label}) catch @panic("bufsize too small");
    c.glObjectLabel(c.GL_TEXTURE, name, -1, label_text);
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

    self.uniforms[0] = Uniform.init(program, uniform_name) catch {
        return TextureError.UniformCreationFailed;
    };
    self.num_uniforms += 1;

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

pub fn setupWriteable(
    self: *Texture,
    data: []u8,
    program: u32,
    uniform_name: []const u8,
    label: [:0]const u8,
    width: usize,
    height: usize,
) TextureError!void {
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_2D, 1, @ptrCast(&name));
    var buf: [500]u8 = undefined;
    const label_text = std.fmt.bufPrintZ(&buf, "✍️writeable_texture_{s}", .{label}) catch @panic("bufsize too small");
    c.glObjectLabel(c.GL_TEXTURE, name, -1, label_text);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_S, self.wrap_s);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_T, self.wrap_t);
    c.glTextureParameteri(name, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTextureParameteri(name, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);

    const w: f32 = @floatFromInt(width);
    const h: f32 = @floatFromInt(height);
    const mip_map_levels: c.GLsizei = @intFromFloat(@ceil(@log2(@max(w, h))));
    c.glTextureStorage2D(name, mip_map_levels, c.GL_RGBA8, @intCast(width), @intCast(height));
    c.glTextureSubImage2D(
        name,
        0,
        0,
        0,
        @intCast(width),
        @intCast(height),
        c.GL_RGBA,
        c.GL_UNSIGNED_BYTE,
        data.ptr,
    );

    c.glGenerateTextureMipmap(name);
    if (c.glfwExtensionSupported("GL_EXT_texture_filter_anisotropic") == 1) {
        var ansio_setting: f32 = 0;
        c.glGetFloatv(c.GL_MAX_TEXTURE_MAX_ANISOTROPY, &ansio_setting);
        c.glTextureParameterf(name, c.GL_TEXTURE_MAX_ANISOTROPY, ansio_setting);
    }

    self.name = name;

    self.uniforms[0] = Uniform.init(program, uniform_name) catch {
        return TextureError.UniformCreationFailed;
    };
    self.num_uniforms += 1;

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

pub fn setupCubemap(self: *Texture, images: ?[6]*assets.Image, program: u32, uniform_name: []const u8, label: [:0]const u8) TextureError!void {
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_CUBE_MAP, 1, @ptrCast(&name));
    var buf: [500]u8 = undefined;
    const label_text = std.fmt.bufPrintZ(&buf, "🗺️cubemap_{s}", .{label}) catch @panic("bufsize too small");
    c.glObjectLabel(c.GL_TEXTURE, name, -1, label_text);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_R, c.GL_CLAMP_TO_EDGE);
    c.glTextureParameteri(name, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTextureParameteri(name, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    if (images) |imgs| {
        const first_img = imgs[0];
        c.glTextureStorage2D(name, 1, c.GL_RGBA8, @intCast(first_img.width), @intCast(first_img.height));
        for (imgs, 0..) |img, i| {
            c.glTextureSubImage3D(
                name,
                0,
                0,
                0,
                @intCast(i),
                @intCast(first_img.width),
                @intCast(first_img.height),
                1,
                c.GL_RGBA,
                c.GL_UNSIGNED_BYTE,
                img.stb_data.ptr,
            );
        }
    } else {
        const magenta_rgba_color = [4]u8{ 255, 0, 255, 255 };
        c.glTextureStorage2D(name, 1, c.GL_RGBA8, 1, 1);
        for (0..6) |i| {
            c.glTextureSubImage3D(
                name,
                0,
                0,
                0,
                @intCast(i),
                1,
                1,
                1,
                c.GL_RGBA,
                c.GL_UNSIGNED_BYTE,
                &magenta_rgba_color,
            );
        }
    }

    if (c.glfwExtensionSupported("GL_EXT_texture_filter_anisotropic") == 1) {
        var ansio_setting: f32 = 0;
        c.glGetFloatv(c.GL_MAX_TEXTURE_MAX_ANISOTROPY, &ansio_setting);
        c.glTextureParameterf(name, c.GL_TEXTURE_MAX_ANISOTROPY, ansio_setting);
    }
    self.texture_unit = 16;
    self.name = name;

    self.uniforms[0] = Uniform.init(program, uniform_name) catch {
        return TextureError.UniformCreationFailed;
    };
    self.num_uniforms += 1;

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

pub fn setup3D(
    self: *Texture,
    t3d_opt: ?*assets.Texture3D,
    width: u32,
    height: u32,
    depth: u32,
    program: u32,
    wrap: c.GLint,
    uniform_name: []const u8,
    label: [:0]const u8,
) TextureError!void {
    const t3d = t3d_opt orelse return;
    const data = t3d.data;
    var name: u32 = undefined;
    c.glCreateTextures(c.GL_TEXTURE_3D, 1, @ptrCast(&name));
    var buf: [500]u8 = undefined;
    const label_text = std.fmt.bufPrintZ(&buf, "🧱3d_texture_{s}", .{label}) catch @panic("bufsize too small");
    c.glObjectLabel(c.GL_TEXTURE, name, -1, label_text);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_S, wrap);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_T, wrap);
    c.glTextureParameteri(name, c.GL_TEXTURE_WRAP_R, wrap);
    c.glTextureParameteri(name, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);

    c.glTextureStorage3D(name, 1, c.GL_RGBA8, @intCast(width), @intCast(height), @intCast(depth));
    c.glTextureSubImage3D(
        name,
        0,
        0,
        0,
        0,
        @intCast(width),
        @intCast(height),
        @intCast(depth),
        c.GL_RGBA,
        c.GL_UNSIGNED_INT_8_8_8_8_REV,
        data.ptr,
    );

    c.glGenerateTextureMipmap(name);
    if (c.glfwExtensionSupported("GL_EXT_texture_filter_anisotropic") == 1) {
        var ansio_setting: f32 = 0;
        c.glGetFloatv(c.GL_MAX_TEXTURE_MAX_ANISOTROPY, &ansio_setting);
        c.glTextureParameterf(name, c.GL_TEXTURE_MAX_ANISOTROPY, ansio_setting);
    }

    self.name = name;

    self.uniforms[0] = Uniform.init(program, uniform_name) catch {
        return TextureError.UniformCreationFailed;
    };
    self.num_uniforms += 1;

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

pub fn removeUniform(self: *Texture, program: u32) void {
    var num_uniforms: usize = 0;
    var uniforms: [100]Uniform = undefined;
    for (0..self.num_uniforms) |i| {
        if (self.uniforms[i].program == program) continue;
        uniforms[num_uniforms] = self.uniforms[i];
        num_uniforms += 1;
    }
    self.uniforms = uniforms;
    self.num_uniforms = num_uniforms;
}

pub fn addUniform(self: *Texture, program: u32, uniform_name: []const u8) TextureError!void {
    self.uniforms[self.num_uniforms] = Uniform.init(program, uniform_name) catch {
        return TextureError.UniformCreationFailed;
    };
    self.num_uniforms += 1;
}

pub fn bind(self: Texture) void {
    if (self.disable_bindless) {
        c.glBindTextureUnit(self.texture_unit, self.name);
        return;
    }
    for (0..self.num_uniforms) |i| {
        self.uniforms[i].setUniformHandleui64ARB(self.handle);
    }
}

const std = @import("std");
const c = @import("../c.zig").c;
const Uniform = @import("Uniform.zig");
const assets = @import("../assets/assets.zig");
const Shader = @import("Shader.zig");
