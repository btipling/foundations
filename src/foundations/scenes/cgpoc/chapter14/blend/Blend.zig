view_camera: *physics.camera.Camera(*Blend, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

sphere: object.object = .{ .norender = .{} },

bobble: object.object = .{ .norender = .{} },

materials: rhi.Buffer,
lights: rhi.Buffer,

const Blend = @This();

const num_bobbles: usize = 2;

const mats = [_]lighting.Material{
    lighting.materials.GlassyPastelBlue,
    lighting.materials.GlassyPastelLavender,
    lighting.materials.GlassyPastelLemon,
    lighting.materials.GlassyPastelMint,
    lighting.materials.GlassyPastelPink,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Blend",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Blend {
    const blend = allocator.create(Blend) catch @panic("OOM");
    errdefer allocator.destroy(blend);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*Blend, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        blend,
        integrator,
        .{ 2, -10, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 0.01 },
            .diffuse = [4]f32{ 0.1, 0.1, 0.1, 0.01 },
            .specular = [4]f32{ 0.1, 0.1, 0.1, 0.01 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 0.05 },
            .direction = [4]f32{ 5, -1.0, -0.3, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
    };
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();

    blend.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    blend.renderDebugCross();
    errdefer blend.deleteCross();

    blend.renderSphere();
    errdefer rhi.deleteObject(blend.sphere);

    blend.renderBobbles();
    errdefer rhi.deleteObject(blend.bobble);

    return blend;
}

pub fn deinit(self: *Blend, allocator: std.mem.Allocator) void {
    rhi.deleteObject(self.bobble);
    rhi.deleteObject(self.sphere);
    self.deleteCross();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *Blend) void {}

pub fn draw(self: *Blend, dt: f64) void {
    self.view_camera.update(dt);
    {
        rhi.drawHorizon(self.sphere);
    }
    self.cross.draw(dt);
    {
        c.glDisable(c.GL_DEPTH_TEST);
        rhi.drawObject(self.bobble);
        c.glEnable(c.GL_DEPTH_TEST);
    }
}

fn deleteCross(self: *Blend) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *Blend) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

fn renderSphere(self: *Blend) void {
    const prog = rhi.createProgram();

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("sphere_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);
    const frag = Compiler.runWithBytes(self.allocator, @embedFile("sphere_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    const m = math.matrix.uniformScale(1);
    var i_datas: [1]rhi.instanceData = .{.{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 0.07, 0.08, 0.09, 1 },
    }};
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.sphere = sphere;
}

fn renderBobbles(self: *Blend) void {
    const prog = rhi.createProgram();

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("blend_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    const frag = Compiler.runWithBytes(self.allocator, @embedFile("blend_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    var i_datas: [num_bobbles]rhi.instanceData = undefined;
    for (0..num_bobbles) |i| {
        const m = math.matrix.translate(1, @floatFromInt(i * 3), 3);
        i_datas[i] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
    }

    var bobble = .{ .sphere = object.Sphere.init(prog, i_datas[0..], false) };
    bobble.sphere.mesh.blend = true;
    self.bobble = bobble;
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const rhi = @import("../../../../rhi/rhi.zig");
const ui = @import("../../../../ui/ui.zig");
const scenes = @import("../../../scenes.zig");
const math = @import("../../../../math/math.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");
const Compiler = @import("../../../../../compiler/Compiler.zig");
const object = @import("../../../../object/object.zig");
const lighting = @import("../../../../lighting/lighting.zig");
const assets = @import("../../../../assets/assets.zig");
