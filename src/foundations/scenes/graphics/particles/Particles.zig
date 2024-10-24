view_camera: *physics.camera.Camera(*Particles, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

sphere: object.object = .{ .norender = .{} },
sphere_matrix: rhi.Uniform = undefined,
sphere_position: math.vector.vec4 = .{ 1, 5, 0, 1 },

particles: object.object = .{ .norender = .{} },

materials: rhi.Buffer,
lights: rhi.Buffer,

const Particles = @This();

const sphere_vert: []const u8 = @embedFile("sphere_vert.glsl");

const mats = [_]lighting.Material{
    lighting.materials.Silver,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Torus Geometry",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Particles {
    const pr = allocator.create(Particles) catch @panic("OOM");
    errdefer allocator.destroy(pr);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*Particles, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pr,
        integrator,
        .{ 0, 0, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 0.5, -1.0, -0.3, 0.0 },
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

    pr.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    pr.renderParticles();
    errdefer pr.deleteParticles();

    pr.renderSphere();
    errdefer pr.renderSphere();

    pr.renderDebugCross();
    errdefer pr.deleteCross();

    return pr;
}

pub fn deinit(self: *Particles, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.deleteSphere();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *Particles) void {}

pub fn draw(self: *Particles, dt: f64) void {
    self.animateSphere(dt);
    self.view_camera.update(dt);
    {
        const objects: [1]object.object = .{
            self.sphere,
        };
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{
            self.particles,
        };
        rhi.drawObjects(objects[0..]);
    }
    self.cross.draw(dt);
}

fn animateSphere(self: *Particles, dt: f64) void {
    const t: f64 = @mod(dt / 2, 6.0);
    var positions: [7]math.vector.vec4 = undefined;
    var tangents: [7]math.vector.vec4 = undefined;
    var times: [7]f32 = undefined;
    // zig fmt: off
    positions[0] = .{  5,    0,    0, 1 };
    positions[1] = .{  5,    5,    0, 1 };
    positions[2] = .{  5,    5,    5, 1 };
    positions[3] = .{  0,    5,    5, 1 };
    positions[4] = .{  0,    0,    5, 1 };
    positions[5] = .{  0,    0,    0, 1 };
    positions[6] = .{  5,    0,    0, 1 };
    tangents[0] = .{ 15, 0, 5, 1 };
    tangents[1] = .{ 15, 0, 0, 1 };
    tangents[2] = .{ 0, 25, 0, 1 };
    tangents[3] = .{ 0, 15, 0, 1 };
    tangents[4] = .{ 0, 25, 0, 1 };
    tangents[5] = .{ 0, 0, 15, 1 };
    tangents[6] = .{ 0, 0, 5, 1 };
    // zig fmt: on
    times[0] = 0;
    times[1] = 1;
    times[2] = 2;
    times[3] = 3;
    times[4] = 4;
    times[5] = 5;
    times[6] = 6;
    const sp = math.interpolation.hermiteCurve(@floatCast(t), positions[0..], tangents[0..], times[0..]);
    self.sphere_position = sp;
    self.sphere_matrix.setUniformMatrix(math.matrix.translate(sp[0], sp[1], sp[2]));
}

pub fn deleteCross(self: *Particles) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *Particles) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

pub fn deleteParticles(self: *Particles) void {
    const objects: [1]object.object = .{self.sphere};
    rhi.deleteObjects(objects[0..]);
}

pub fn renderParticles(self: *Particles) void {
    const prog = rhi.createProgram();

    const particles_vert = Compiler.runWithBytes(self.allocator, @embedFile("particles_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(particles_vert);

    const particles_frag = Compiler.runWithBytes(self.allocator, @embedFile("particles_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(particles_frag);

    const particles_geo = Compiler.runWithBytes(self.allocator, @embedFile("particles_geo.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(particles_geo);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = particles_vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = particles_frag, .shader_type = c.GL_FRAGMENT_SHADER },
        .{ .source = particles_geo, .shader_type = c.GL_GEOMETRY_SHADER },
    };

    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);

    var i_datas: [1]rhi.instanceData = undefined;
    {
        const m = math.matrix.translate(0, 2.5, 2.5);
        const i_data: rhi.instanceData = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    var torus: object.object = .{
        .torus = object.Torus.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    torus.torus.mesh.linear_colorspace = false;
    self.particles = torus;
}

pub fn deleteSphere(self: *Particles) void {
    const objects: [1]object.object = .{
        self.sphere,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderSphere(self: *Particles) void {
    const prog = rhi.createProgram();

    const particles_vert = Compiler.runWithBytes(self.allocator, @embedFile("sphere_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(particles_vert);

    const particles_frag = Compiler.runWithBytes(self.allocator, @embedFile("sphere_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(particles_frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = particles_vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = particles_frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };

    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    var i_datas: [1]rhi.instanceData = undefined;
    const m = math.matrix.uniformScale(0.125);
    i_datas[0] = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 1, 0, 1, 1 },
    };
    var sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    sphere.sphere.mesh.linear_colorspace = false;
    const sp = self.sphere_position;
    var sm: rhi.Uniform = rhi.Uniform.init(prog, "f_sphere_matrix") catch @panic("uniform failed");
    sm.setUniformMatrix(math.matrix.translate(sp[0], sp[1], sp[2]));
    self.sphere_matrix = sm;
    self.sphere = sphere;
}

const std = @import("std");
const c = @import("../../../c.zig").c;
const rhi = @import("../../../rhi/rhi.zig");
const ui = @import("../../../ui/ui.zig");
const scenes = @import("../../scenes.zig");
const math = @import("../../../math/math.zig");
const physics = @import("../../../physics/physics.zig");
const scenery = @import("../../../scenery/scenery.zig");
const Compiler = @import("../../../../compiler/Compiler.zig");
const object = @import("../../../object/object.zig");
const lighting = @import("../../../lighting/lighting.zig");
