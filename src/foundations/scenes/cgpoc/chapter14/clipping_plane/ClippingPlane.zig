view_camera: *physics.camera.Camera(*ClippingPlane, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

sphere: object.object = .{ .norender = .{} },

torus: object.object = .{ .norender = .{} },
torus_clip_plane: rhi.Uniform = undefined,

plane: object.object = .{ .norender = .{} },

materials: rhi.Buffer,
lights: rhi.Buffer,

const ClippingPlane = @This();

const mats = [_]lighting.Material{
    lighting.materials.Gold,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Clipping Plane",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *ClippingPlane {
    const clipping_plane = allocator.create(ClippingPlane) catch @panic("OOM");
    errdefer allocator.destroy(clipping_plane);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*ClippingPlane, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        clipping_plane,
        integrator,
        .{ 2, -3, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 0.5, 0.5, 0.5, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 5, -10.0, -0.3, 0.0 },
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

    clipping_plane.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    clipping_plane.renderDebugCross();
    errdefer clipping_plane.deleteCross();

    clipping_plane.renderSphere();
    errdefer rhi.deleteObject(clipping_plane.sphere);

    clipping_plane.renderTorus();
    errdefer rhi.deleteObject(clipping_plane.torus);

    clipping_plane.renderPlane();
    errdefer rhi.deleteObject(clipping_plane.plane);

    return clipping_plane;
}

pub fn deinit(self: *ClippingPlane, allocator: std.mem.Allocator) void {
    rhi.deleteObject(self.torus);
    rhi.deleteObject(self.plane);
    self.deleteCross();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *ClippingPlane) void {}

pub fn draw(self: *ClippingPlane, dt: f64) void {
    self.view_camera.update(dt);
    {
        rhi.drawHorizon(self.sphere);
    }
    {
        c.glEnable(c.GL_CLIP_DISTANCE0);
        rhi.drawObject(self.torus);
        c.glEnable(c.GL_CLIP_DISTANCE1);
    }
    {
        rhi.drawObject(self.plane);
    }
    self.cross.draw(dt);
}

fn deleteCross(self: *ClippingPlane) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *ClippingPlane) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

fn renderSphere(self: *ClippingPlane) void {
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

fn renderPlane(self: *ClippingPlane) void {
    const prog = rhi.createProgram();

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("plane_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    const frag = Compiler.runWithBytes(self.allocator, @embedFile("plane_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    const m = math.matrix.translateVec(.{ 1, 0, 2.5 });
    const i_datas = [_]rhi.instanceData{
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        },
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        },
    };

    var plane = .{ .parallelepiped = object.Parallelepiped.init(prog, i_datas[0..], false) };
    plane.parallelepiped.mesh.blend = true;
    plane.parallelepiped.mesh.linear_colorspace = false;
    self.plane = plane;
}

fn renderTorus(self: *ClippingPlane) void {
    const prog = rhi.createProgram();

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("torus_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    const frag = Compiler.runWithBytes(self.allocator, @embedFile("torus_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    const m = math.matrix.translateVec(.{ 1, 0, -2.5 });
    const i_datas = [_]rhi.instanceData{.{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 1, 0, 1, 0.25 },
    }};

    var torus = .{ .torus = object.Torus.init(prog, i_datas[0..], false) };
    torus.torus.mesh.cull = false;
    torus.torus.mesh.linear_colorspace = false;
    var cpu = rhi.Uniform.init(prog, "f_torus_clip") catch @panic("uniform");
    cpu.setUniform4fv(.{ 0.0, 0.0, -1.0, 0.5 });
    self.torus_clip_plane = cpu;
    self.torus = torus;
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