view_camera: *physics.camera.Camera(*Particles, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,
rand: std.Random = undefined,

sphere: object.object = .{ .norender = .{} },
sphere_matrix: rhi.Uniform = undefined,
sphere_color: rhi.Uniform = undefined,

particles: object.object = .{ .norender = .{} },
particles_data: rhi.Uniform = undefined,
particles_count: usize = 0,
particles_list: [max_num_particles]rhi.Buffer.ParticlesData = undefined,

materials: rhi.Buffer,
lights: rhi.Buffer,
particles_buffer: rhi.Buffer,

const Particles = @This();

const max_num_particles = 15;
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

    const particles = [_]rhi.Buffer.ParticlesData{
        .{
            .ts = .{ 2, 0, 1, 0.1 },
            .color = .{ 1, 0, 1, 1 },
        },
        .{
            .ts = .{ 2, 0, 1.5, 0.1 },
            .color = .{ 0, 1, 1, 1 },
        },
    };
    const pd: rhi.Buffer.buffer_data = .{ .particles = particles[0..] };
    var particles_buf = rhi.Buffer.init(pd);
    errdefer particles_buf.deinit();

    var rand = std.Random.Xoshiro256.init(@intCast(std.time.microTimestamp()));
    pr.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
        .particles_buffer = particles_buf,
        .rand = rand.random(),
    };
    pr.particles_list[0] = particles[0];
    pr.particles_list[1] = particles[1];
    pr.particles_count = 2;

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
    self.particles_buffer.deinit();
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
        c.glDisable(c.GL_CULL_FACE);
        rhi.drawObjects(objects[0..]);
        c.glEnable(c.GL_CULL_FACE);
    }
    self.cross.draw(dt);
}

fn animateSphere(self: *Particles, dt: f64) void {
    const dtf: f32 = @floatCast(dt);
    const t: f32 = @mod(dtf / 2, 6.0);
    var positions: [7]math.vector.vec4 = undefined;
    var tangents: [7]math.vector.vec4 = undefined;
    var colors: [7]math.vector.vec4 = undefined;
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

    colors[0] = .{ 1.0, 0.278, 0.698, 1 };
    colors[1] = .{ 0, 1.0, 0.698, 1 };
    colors[2] = .{ 1.0, 0.655, 0.149, 1 };
    colors[3] = .{ 0.392, 0.867, 0.090, 1 };
    colors[4] = .{ 0.0, 0.690, 1.0, 1 };
    colors[5] = .{ 0.702, 0.533, 1.0, 1 };
    colors[6] = .{ 1.0, 0.278, 0.698, 1 };
    times[0] = 0;
    times[1] = 1;
    times[2] = 2;
    times[3] = 3;
    times[4] = 4;
    times[5] = 5;
    times[6] = 6;

    const sp = math.interpolation.hermiteCurve(t, positions[0..], tangents[0..], times[0..]);
    self.sphere_matrix.setUniformMatrix(math.matrix.translate(sp[0], sp[1], sp[2]));

    const sphere_color = math.interpolation.linear(t, colors[0..], times[0..]);
    self.sphere_color.setUniform4fv(sphere_color);
    self.updateParticlesBuffer(sp, sphere_color);
}

pub fn updateParticlesBuffer(self: *Particles, pos: math.vector.vec4, color: math.vector.vec4) void {
    if (self.particles_count >= max_num_particles) {
        var new_pl: [max_num_particles]rhi.Buffer.ParticlesData = undefined;
        for (0..max_num_particles - 1) |i| {
            new_pl[i] = self.particles_list[i + 1];
            new_pl[i].ts[3] -= 0.01;
        }
        new_pl[max_num_particles - 1] = .{
            .ts = .{ pos[0], pos[1], pos[2], 0.15 },
            .color = color,
        };
        self.particles_list = new_pl;
    } else {
        self.particles_list[self.particles_count] = .{
            .ts = .{ pos[0], pos[1], pos[2], 0.15 },
            .color = .{ color[0], color[1], color[2], self.rand.float(f32) },
        };
        self.particles_count += 1;
    }
    const pd: rhi.Buffer.buffer_data = .{ .particles = self.particles_list[0..self.particles_count] };
    self.particles_buffer.update(pd);
    self.particles_data.setUniform1i(self.particles_count);
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
        const m = math.matrix.identity();
        const i_data: rhi.instanceData = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const points: object.object = .{
        .points = object.Points.init(prog, 15),
    };
    var pd: rhi.Uniform = rhi.Uniform.init(prog, "f_particles_data") catch @panic("uniform failed");
    pd.setUniform1i(self.particles_count);
    self.particles_data = pd;
    self.particles = points;
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
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    var sm: rhi.Uniform = rhi.Uniform.init(prog, "f_sphere_matrix") catch @panic("uniform failed");
    sm.setUniformMatrix(math.matrix.translate(1, 5, 0));
    self.sphere_matrix = sm;
    var sc: rhi.Uniform = rhi.Uniform.init(prog, "f_sphere_color") catch @panic("uniform failed");
    sc.setUniform4fv(.{ 1, 1, 1, 1 });
    self.sphere_color = sc;
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
