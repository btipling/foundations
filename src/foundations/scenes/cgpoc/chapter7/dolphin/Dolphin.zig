allocator: std.mem.Allocator,
dolphin: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Dolphin, physics.Integrator(physics.SmoothDeceleration)),
dolphin_texture: ?rhi.Texture,
ctx: scenes.SceneContext,
materials: rhi.Buffer,
lights: rhi.Buffer,
global_lighting: rhi.Uniform = undefined,

const Dolphin = @This();

const vertex_shader: []const u8 = @embedFile("blinn_phong_vert.glsl");
const frag_shader: []const u8 = @embedFile("blinn_phong_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Dolphin",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Dolphin {
    const pd = allocator.create(Dolphin) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*Dolphin, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 0, 2, -3 },
        std.math.pi - std.math.pi / 4.0,
    );
    errdefer cam.deinit(allocator);

    const mats = [_]lighting.Material{
        .{
            .ambient = [4]f32{ 0.2, 0.2, 0.2, 1.0 },
            .diffuse = [4]f32{ 0.8, 0.8, 0.8, 1.0 },
            .specular = [4]f32{ 0.5, 0.5, 0.5, 1.0 },
            .shininess = 32.0,
        },
    };

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 0.75, -0.5, -0.5, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .direction,
        },
    };
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
        .dolphin_texture = null,
        .ctx = ctx,
        .materials = mats_buf,
        .lights = lights_buf,
    };
    pd.renderDolphin();
    return pd;
}

pub fn deinit(self: *Dolphin, allocator: std.mem.Allocator) void {
    if (self.dolphin_texture) |et| {
        et.deinit();
    }
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *Dolphin, dt: f64) void {
    self.view_camera.update(dt);
    if (self.dolphin_texture) |et| {
        et.bind();
    }
    {
        const objects: [1]object.object = .{
            self.dolphin,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *Dolphin) void {}

pub fn renderDolphin(self: *Dolphin) void {
    var dolphin_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\Dolphin\\dolphinHighPoly.obj") catch null) |o| {
        dolphin_model = o;
    } else {
        return;
    }

    const prog = rhi.createProgram();
    self.dolphin_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .xup = .wavefront,
            .lighting = .blinn_phong,
            .frag_body = frag_shader,
            .fragment_shader = rhi.Texture.frag_shader(self.dolphin_texture),
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, -1, -1));
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(2));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    if (self.dolphin_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\Dolphin\\Dolphin_HighPolyUV.png") catch null, prog, "f_samp") catch {
            self.dolphin_texture = null;
        };
    }
    const dolphin_object: object.object = dolphin_model.toObject(prog, i_datas[0..]);
    self.view_camera.addProgram(prog);

    var gau: rhi.Uniform = .init(prog, "f_global_ambient");
    gau.setUniform4fv(.{ 0.7, 0.7, 0.7, 1 });
    self.global_lighting = gau;

    self.dolphin = dolphin_object;
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const scenes = @import("../../../scenes.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");
const assets = @import("../../../../assets/assets.zig");
const lighting = @import("../../../../lighting/lighting.zig");
