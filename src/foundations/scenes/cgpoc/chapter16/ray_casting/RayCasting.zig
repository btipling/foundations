view_camera: *physics.camera.Camera(*RayCasting, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
allocator: std.mem.Allocator,
ui_state: RayCastingUI,

cross: scenery.debug.Cross = undefined,

ray_cast_buffer: SSBO,

images: [2]Img = undefined,

const RayCasting = @This();

const Img = struct {
    prog: u32 = 0,
    tex: rhi.Texture = undefined,
    mem: []u8 = undefined,
    quad: object.object = .{ .norender = .{} },
    drawn: bool = false,
};

const texture_dims: usize = 512;
const num_channels: usize = 4;

pub const SceneData = extern struct {
    sphere_radius: [4]f32,
    sphere_position: [4]f32,
    sphere_color: [4]f32,
    box_position: [4]f32,
    box_dims: [4]f32,
    box_color: [4]f32,
    box_rotation: [4]f32,
};

pub const binding_point: rhi.storage_buffer.storage_binding_point = .{ .ubo = 3 };
const SSBO = rhi.storage_buffer.Buffer([]const SceneData, binding_point, c.GL_DYNAMIC_COPY);

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Ray Casting",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *RayCasting {
    const rc = allocator.create(RayCasting) catch @panic("OOM");
    errdefer allocator.destroy(rc);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*RayCasting, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        rc,
        integrator,
        .{ 0, -2, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const cd: [2]SceneData = .{
        .{
            .sphere_radius = .{ 2.5, 0, 0, 0 },
            .sphere_position = .{ 1, 0, -3, 1.0 },
            .sphere_color = .{ 0, 0, 1, 1 },
            .box_position = .{ 0.5, 0, 0, 0 },
            .box_dims = .{ 0.5, 0.5, 0.5, 0 },
            .box_color = .{ 1, 0, 0, 0 },
            .box_rotation = .{ 0, 0, 0, 0 },
        },
        .{
            .sphere_radius = .{ 2.5, 0, 0, 0 },
            .sphere_position = .{ 1, 0, -3, 1.0 },
            .sphere_color = .{ 0, 0, 1, 1 },
            .box_position = .{ 0.5, 0, 0, 0 },
            .box_dims = .{ 0.5, 0.5, 0.5, 0 },
            .box_color = .{ 1, 0, 0, 0 },
            .box_rotation = .{ 0, 0, 0, 0 },
        },
    };

    var rc_buf = SSBO.init(cd[0..], "scene_data");
    errdefer rc_buf.deinit();
    const ui_state: RayCastingUI = .{};

    rc.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .ctx = ctx,
        .view_camera = cam,
        .ray_cast_buffer = rc_buf,
    };

    rc.renderDebugCross();
    errdefer rc.deleteCross();

    rc.images[0] = rc.renderImg("img_1", @embedFile("img_1.comp.glsl"), math.matrix.translate(0, 0, 0));
    errdefer rc.deleteImg(rc.images[0]);
    rc.images[1] = rc.renderImg("img_2", @embedFile("img_2.comp.glsl"), math.matrix.translate(0, 0, 1.5));
    errdefer rc.deleteImg(rc.images[1]);

    return rc;
}

pub fn deinit(self: *RayCasting, allocator: std.mem.Allocator) void {
    self.ray_cast_buffer.deinit();
    for (self.images) |i| {
        self.deleteImg(i);
    }
    self.ray_cast_buffer.deinit();
    self.deleteCross();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *RayCasting) void {}

pub fn draw(self: *RayCasting, dt: f64) void {
    for (self.ui_state.data, 0..) |d, i| {
        if (!d.updated) continue;
        self.updateSceneData(i);
        self.ui_state.data[i].updated = false;
    }
    self.rayCastScene();
    self.view_camera.update(dt);
    for (self.images) |i| {
        i.tex.bind();
        rhi.drawObject(i.quad);
    }
    self.cross.draw(dt);
    self.ui_state.draw();
}

fn rayCastScene(self: *RayCasting) void {
    for (self.images, 0..) |img, i| {
        if (img.drawn) continue;
        img.tex.bindWritableImage();
        c.glUseProgram(img.prog);
        c.glDispatchCompute(texture_dims, texture_dims, 1);
        c.glMemoryBarrier(c.GL_ALL_BARRIER_BITS);
        self.images[i].drawn = true;
    }
}

fn deleteCross(self: *RayCasting) void {
    self.cross.deinit(self.allocator);
}

pub fn allocateTextureMemory(self: *RayCasting) []u8 {
    var mem = self.allocator.alloc(u8, texture_dims * texture_dims * num_channels) catch @panic("OOM");
    for (0..texture_dims) |i| {
        for (0..texture_dims) |j| {
            mem[i * texture_dims * num_channels + j * num_channels + 0] = 255;
            mem[i * texture_dims * num_channels + j * num_channels + 1] = 128;
            mem[i * texture_dims * num_channels + j * num_channels + 2] = 255;
            mem[i * texture_dims * num_channels + j * num_channels + 3] = 255;
        }
    }
    return mem;
}

fn renderDebugCross(self: *RayCasting) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0.0, 0.0, 0.0),
        5,
    );
}

fn deleteImg(self: *RayCasting, img: Img) void {
    c.glDeleteProgram(img.prog);
    self.allocator.free(img.mem);
    img.tex.deinit();
    rhi.deleteObject(img.quad);
}

fn renderImg(self: *RayCasting, name: [:0]const u8, compute_shader: []const u8, translation: math.matrix) Img {
    var img: Img = .{
        .mem = self.allocateTextureMemory(),
        .tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch @panic("unable to create reflection texture"),
    };
    {
        img.prog = rhi.createProgram(name);
        const comp = Compiler.runWithBytes(self.allocator, compute_shader) catch @panic("shader compiler");
        defer self.allocator.free(comp);

        const shaders = [_]rhi.Shader.ShaderData{
            .{ .source = comp, .shader_type = c.GL_COMPUTE_SHADER },
        };
        const s: rhi.Shader = .{
            .program = img.prog,
        };
        s.attachAndLinkAll(self.allocator, shaders[0..], name);
    }
    {
        img.tex.texture_unit = 1;
        const prog = rhi.createProgram(name);
        const frag_bindings = [_]usize{1};
        const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);

        const vert = Compiler.runWithBytes(self.allocator, @embedFile("quad_vert.glsl")) catch @panic("shader compiler");
        defer self.allocator.free(vert);

        var frag = Compiler.runWithBytes(self.allocator, @embedFile("quad_frag.glsl")) catch @panic("shader compiler");
        defer self.allocator.free(frag);
        frag = if (!disable_bindless) frag else rhi.Shader.disableBindless(
            frag,
            frag_bindings[0..],
        ) catch @panic("bindless");

        const shaders = [_]rhi.Shader.ShaderData{
            .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
            .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
        };
        const s: rhi.Shader = .{
            .program = prog,
        };
        s.attachAndLinkAll(self.allocator, shaders[0..], name);
        var m = translation;
        m = math.matrix.transformMatrix(m, math.matrix.rotationZ(-(std.math.pi / 2.0)));
        const i_datas = [_]rhi.instanceData{
            .{
                .t_column0 = m.columns[0],
                .t_column1 = m.columns[1],
                .t_column2 = m.columns[2],
                .t_column3 = m.columns[3],
                .color = .{ 1, 0, 1, 1 },
            },
        };
        var grid_obj: object.object = .{ .quad = object.Quad.initPlane(prog, i_datas[0..], name) };
        grid_obj.quad.mesh.linear_colorspace = false;
        img.quad = grid_obj;

        img.tex.setupWriteable(
            img.mem,
            prog,
            "f_texture",
            name,
            texture_dims,
            texture_dims,
        ) catch @panic("unable to setup reflection depth texture");
    }
    return img;
}

fn updateSceneData(self: *RayCasting, i: usize) void {
    var cd: [2]SceneData = undefined;
    for (cd, 0..) |_, j| {
        var sd = cd[j];
        const d = self.ui_state.data[j];
        const sp = d.sphere_pos;
        const bd = d.box_dim;
        const bp = d.box_pos;

        sd.sphere_radius = .{ d.sphere_radius, 0, 0, 0 };
        sd.sphere_position = .{ sp[0], sp[1], sp[2], 1.0 };
        sd.sphere_color = .{ 0, 0, 1, 1 };

        sd.box_position = .{ bp[0], bp[1], bp[2], 0 };
        sd.box_dims = .{ bd, bd, bd, 0 };
        sd.box_color = .{ 1, 0, 0, 0 };
        sd.box_rotation = .{ 0, 0, 0, 0 };
        cd[j] = sd;
    }
    self.images[i].drawn = false;
    self.ray_cast_buffer.update(cd[0..]);
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const physics = @import("../../../../physics/physics.zig");
const math = @import("../../../../math/math.zig");
const scenes = @import("../../../scenes.zig");
const scenery = @import("../../../../scenery/scenery.zig");
const Compiler = @import("../../../../../fssc/Compiler.zig");
const RayCastingUI = @import("RayCastingUI.zig");
const object = @import("../../../../object/object.zig");
const lighting = @import("../../../../lighting/lighting.zig");
const assets = @import("../../../../assets/assets.zig");
