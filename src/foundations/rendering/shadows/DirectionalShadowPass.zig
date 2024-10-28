shadowmap: rhi.Texture = undefined,
shadowmap_program: u32 = 0,
shadow_uniform: rhi.Uniform = undefined,
shadow_x_up: rhi.Uniform = undefined,
shadow_framebuffer: rhi.Framebuffer = undefined,
f_shadow_m: rhi.Uniform = undefined,

light_direction: math.vector.vec3 = undefined,
light_view_shadowpass: math.matrix = undefined,
light_view_renderpass: math.matrix = undefined,

scene_objects: []ShadowObject = undefined,

texture_unit: c.GLuint = 0,

const DirectionalShadowPass = @This();

const ShadowObject = struct {
    transform: math.matrix = math.matrix.identity(),
    x_up: math.matrix = math.matrix.identity(),
    polygon_factor: f32 = 0,
    polygon_unit: f32 = 0,
    obj: object.object,
};

const num_maps: usize = 12;

const shadow_vertex_shader: []const u8 = @embedFile("shadow_vert.glsl");

fn init(allocator: std.mem.allocator) *DirectionalShadowPass {
    const dsp = allocator.create(DirectionalShadowPass) catch @panic("OOM");
    errdefer dsp.deinit(allocator);
    return dsp;
}

fn deinit(self: *DirectionalShadowPass, allocator: std.mem.Allocator) void {
    c.glDeleteProgram(self.shadowmap_program);
    self.shadow_framebuffer.deinit();
    allocator.destroy(self);
}

fn setupShadowmaps(self: *DirectionalShadowPass) void {
    self.shadowmap_program = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = self.shadowmap_program,
            .instance_data = true,
            .fragment_shader = .shadow,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(shadow_vertex_shader)[0..]);
    }

    var shadow_uniform: rhi.Uniform = rhi.Uniform.init(self.shadowmap_program, "f_shadow_vp") catch @panic("uniform failed");
    shadow_uniform.setUniformMatrix(math.matrix.identity());
    self.shadow_uniform = shadow_uniform;

    var f_shadow_m: rhi.Uniform = rhi.Uniform.init(self.shadowmap_program, "f_shadow_m") catch @panic("uniform failed");
    f_shadow_m.setUniformMatrix(math.matrix.identity());
    self.f_shadow_m = f_shadow_m;

    var shadow_x_up: rhi.Uniform = rhi.Uniform.init(self.shadowmap_program, "f_xup_shadow") catch @panic("uniform failed");
    shadow_x_up.setUniformMatrix(math.matrix.transpose(math.matrix.identity()));
    self.shadow_x_up = shadow_x_up;
    for (0..self.shadowmaps.len) |i| {
        self.genShadowmapTexture(i);
    }
}

fn genShadowmapTexture(self: *DirectionalShadowPass) void {
    var shadow_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch @panic("unable to create shadow texture");
    errdefer shadow_texture.deinit();
    shadow_texture.setupShadow(
        self.ctx.cfg.fb_width,
        self.ctx.cfg.fb_height,
    ) catch @panic("unable to setup shadow texture");
    shadow_texture.texture_unit = self.texture_unit;
    self.shadowmap = shadow_texture;

    var shadow_framebuffer = rhi.Framebuffer.init();
    errdefer shadow_framebuffer.deinit();

    shadow_framebuffer.setupForShadowMap(shadow_texture) catch @panic("unable to setup shadow map framebuffer");
    self.shadow_framebuffer = shadow_framebuffer;
}

pub fn genShadowMap(self: *DirectionalShadowPass) void {
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LEQUAL);

    c.glEnable(c.GL_POLYGON_OFFSET_FILL);
    self.shadow_framebuffer.bind();

    const sm = self.light_view_shadowpass;
    self.shadow_uniform.setUniformMatrix(sm);

    c.glClear(c.GL_DEPTH_BUFFER_BIT);

    for (self.scene_objects) |so| {
        self.shadow_x_up.setUniformMatrix(so.x_up);
        c.glPolygonOffset(
            @floatCast(so.polygon_factor),
            @floatCast(so.polygon_unit),
        );
        self.f_shadow_m.setUniformMatrix(so.transform);
        var sobj = so.obj;
        switch (sobj) {
            inline else => |*o| {
                o.mesh.gen_shadowmap = true;
            },
        }
        const objects: [1]object.object = .{sobj};
        rhi.drawObjects(objects[0..]);
    }
    self.shadow_framebuffer.unbind();
    c.glClear(c.GL_DEPTH_BUFFER_BIT);
    c.glDisable(c.GL_POLYGON_OFFSET_FILL);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LEQUAL);
}

fn setLightViewMatrix(self: *DirectionalShadowPass, tm: math.matrix) void {
    var P = math.matrix.orthographicProjection(
        0,
        9,
        0,
        6,
        self.ctx.cfg.near,
        self.ctx.cfg.far,
    );
    P = math.matrix.transformMatrix(P, math.matrix.leftHandedXUpToNDC());
    const m = math.matrix.transformMatrix(P, tm);
    const light_view = math.matrix.transformMatrix(math.matrix.transpose(math.matrix.mc(.{
        0.5, 0.0, 0.0, 0.0,
        0.0, 0.5, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.5, 0.5, 0.0, 1.0,
    })), m).array();
    self.light_view_shadowpass = m;
    self.light_view_renderpass = light_view;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
