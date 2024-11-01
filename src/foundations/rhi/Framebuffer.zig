name: c.GLuint = 0,

const FrameBuffer = @This();

pub const FrameBufferError = error{
    FramebufferIncomplete,
    FramebufferStatusCheckFailure,
};

pub fn init() FrameBuffer {
    var name: u32 = undefined;
    c.glCreateFramebuffers(1, @ptrCast(&name));
    return .{
        .name = name,
    };
}

pub fn deinit(self: FrameBuffer) void {
    c.glDeleteFramebuffers(1, &self.name);
}

pub fn setupForShadowMap(self: *FrameBuffer, depth_texture: Texture) FrameBufferError!void {
    self.attachDepthTexture(depth_texture);
    const buffers = [_]c.GLenum{c.GL_NONE};
    self.setDrawBuffers(&buffers);
    self.checkStatus() catch {
        return FrameBufferError.FramebufferStatusCheckFailure;
    };
}

pub fn setupForColorRendering(
    self: *FrameBuffer,
    color_texture: Texture,
    depth_texture: Texture,
) FrameBufferError!void {
    self.attachColorTexture(color_texture);
    const buffers = [_]c.GLenum{c.GL_COLOR_ATTACHMENT0};
    self.setDrawBuffers(&buffers);
    self.attachDepthTexture(depth_texture);
    self.checkStatus() catch {
        return FrameBufferError.FramebufferStatusCheckFailure;
    };
}

pub fn setDrawBuffers(self: FrameBuffer, buffers: []const c.GLenum) void {
    c.glNamedFramebufferDrawBuffers(self.name, @intCast(buffers.len), buffers.ptr);
}

pub fn attachDepthTexture(self: *FrameBuffer, texture: Texture) void {
    c.glNamedFramebufferTexture(self.name, c.GL_DEPTH_ATTACHMENT, texture.name, 0);
}

pub fn detachDepthTexture(self: *FrameBuffer) void {
    c.glNamedFramebufferTexture(self.name, c.GL_DEPTH_ATTACHMENT, 0, 0);
}

pub fn attachColorTexture(self: *FrameBuffer, texture: Texture) void {
    c.glNamedFramebufferTexture(self.name, c.GL_COLOR_ATTACHMENT0, texture.name, 0);
}

pub fn checkStatus(self: FrameBuffer) FrameBufferError!void {
    const status = c.glCheckNamedFramebufferStatus(self.name, c.GL_FRAMEBUFFER);
    switch (status) {
        c.GL_FRAMEBUFFER_COMPLETE => return,
        c.GL_FRAMEBUFFER_UNDEFINED => {
            std.debug.print("Framebuffer undefined - probably means FBO 0 is bound {d}\n", .{self.name});
        },
        c.GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT => {
            std.debug.print("Framebuffer incomplete: attachment points are framebuffer incomplete {d}\n", .{self.name});
        },
        c.GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT => {
            std.debug.print("Framebuffer incomplete: no attachments set {d}\n", .{self.name});
        },
        c.GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER => {
            std.debug.print("Framebuffer incomplete: draw buffer {d}\n", .{self.name});
        },
        c.GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER => {
            std.debug.print("Framebuffer incomplete: read buffer {d}\n", .{self.name});
        },
        c.GL_FRAMEBUFFER_UNSUPPORTED => {
            std.debug.print("Framebuffer incomplete: unsupported format combination {d}\n", .{self.name});
        },
        c.GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE => {
            std.debug.print("Framebuffer incomplete: multisample settings mismatch {d}\n", .{self.name});
        },
        c.GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS => {
            std.debug.print("Framebuffer incomplete: layer targets mismatch {d}\n", .{self.name});
        },
        else => {
            std.debug.print("Framebuffer status unknown: {d} for {d}\n", .{ status, self.name });
        },
    }
    return FrameBufferError.FramebufferIncomplete;
}

pub fn bind(self: FrameBuffer) void {
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.name);
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
}

pub fn unbind(_: FrameBuffer) void {
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
}

const std = @import("std");
const c = @import("../c.zig").c;
const Texture = @import("Texture.zig");
