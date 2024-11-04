view_camera: *physics.camera.Camera(*Particles, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,
rand: std.Random.DefaultPrng = undefined,

cur_x_rand_dir: f32 = 0,
cur_y_rand_dir: f32 = 0,
cur_z_rand_dir: f32 = 0,
prev_mod: f32 = 0,

sphere: object.object = .{ .norender = .{} },
sphere_matrix: rhi.Uniform = undefined,
sphere_color: rhi.Uniform = undefined,

particles: object.object = .{ .norender = .{} },
particles_data: rhi.Uniform = undefined,
particles_count: usize = 0,
particles_list: [max_num_particles]ParticlesData = undefined,

materials: lighting.Material.SSBO,
lights: lighting.Light.SSBO,
particles_buffer: SSBO,

cubemap: object.object = .{ .norender = .{} },
cubemap_texture: ?rhi.Texture = null,

const Particles = @This();

const max_num_particles: usize = 1000;
const max_num_particles_f: f32 = @floatFromInt(max_num_particles);
const particle_per_frame: usize = 1;

const sphere_vert: []const u8 = @embedFile("sphere_vert.glsl");
const cubemap_vert: []const u8 = @embedFile("../../../shaders/cubemap_vert.glsl");

pub const ParticlesData = struct {
    ts: [4]f32 = .{ 0, 0, 0, 0 },
    color: [4]f32 = .{ 1, 0, 1, 1 },
};

pub const binding_point: rhi.storage_buffer.storage_binding_point = .{ .ssbo = 3 };
const SSBO = rhi.storage_buffer.Buffer([]const ParticlesData, binding_point, c.GL_DYNAMIC_DRAW);

const mats = [_]lighting.Material{
    lighting.materials.Silver,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .graphics,
        .name = "Particles",
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
        .{ -2, 15, 25 },
        std.math.pi + 1.0,
    );
    errdefer cam.deinit(allocator);

    const bd: []const lighting.Material = mats[0..];
    var mats_buf = lighting.Material.SSBO.init(bd, "materials");
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
    const ld: []const lighting.Light = lights[0..];
    var lights_buf = lighting.Light.SSBO.init(ld, "lights");
    errdefer lights_buf.deinit();

    const particles = [_]ParticlesData{
        .{
            .ts = .{ 2, 0, 1, 0.1 },
            .color = .{ 1, 0, 1, 1 },
        },
        .{
            .ts = .{ 2, 0, 1.5, 0.1 },
            .color = .{ 0, 1, 1, 1 },
        },
    };
    const pd: []const ParticlesData = particles[0..];
    var particles_buf = SSBO.init(pd, "materials");
    errdefer particles_buf.deinit();
    const prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch @panic("random fail");
        break :blk seed;
    });
    // var rand = std.Random.Xoshiro256.init(@intCast(std.time.microTimestamp()));
    pr.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
        .particles_buffer = particles_buf,
        .rand = prng,
    };
    pr.particles_list[0] = particles[0];
    pr.particles_list[1] = particles[1];
    pr.particles_count = 2;

    pr.renderParticles();
    errdefer pr.deleteParticles();

    pr.renderCubemap();
    errdefer pr.deleteCubemap();

    pr.renderSphere();
    errdefer pr.renderSphere();

    pr.renderDebugCross();
    errdefer pr.deleteCross();

    return pr;
}

pub fn deinit(self: *Particles, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.deleteCubemap();
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
    if (self.cubemap_texture) |t| {
        t.bind();
    }
    {
        rhi.drawHorizon(self.cubemap);
    }
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
    if (self.prev_mod == 0 or t < self.prev_mod) {
        self.cur_x_rand_dir = self.rand.random().float(f32) * 12.9898 / 2.0;
        self.cur_y_rand_dir = self.rand.random().float(f32) * 78.233 / 2.0;
        self.cur_z_rand_dir = self.rand.random().float(f32) * 43.758 / 2.0;
    }
    self.prev_mod = t;
    var positions: [7]math.vector.vec4 = undefined;
    var tangents: [7]math.vector.vec4 = undefined;
    var colors: [7]math.vector.vec4 = undefined;
    var times: [7]f32 = undefined;
    // zig fmt: off
    positions[0] = .{  5 + self.cur_x_rand_dir,     self.cur_y_rand_dir,        self.cur_z_rand_dir, 1 };
    positions[1] = .{  5 + self.cur_x_rand_dir,     5 + self.cur_y_rand_dir,    self.cur_z_rand_dir, 1 };
    positions[2] = .{  5 + self.cur_x_rand_dir,     5 + self.cur_y_rand_dir,    5 + self.cur_z_rand_dir, 1 };
    positions[3] = .{  self.cur_x_rand_dir,         5 + self.cur_y_rand_dir,    5 + self.cur_z_rand_dir, 1 };
    positions[4] = .{  self.cur_x_rand_dir,         self.cur_y_rand_dir,        5 + self.cur_z_rand_dir, 1 };
    positions[5] = .{  self.cur_x_rand_dir,         self.cur_y_rand_dir,        self.cur_z_rand_dir, 1 };
    positions[6] = .{  5 + self.cur_x_rand_dir,     self.cur_y_rand_dir,        self.cur_z_rand_dir, 1 };
    tangents[0] = .{ 15, 0, 5, 1 };
    tangents[1] = .{ 15, 0, 0, 1 };
    tangents[2] = .{ 0, 25, 0, 1 };
    tangents[3] = .{ 0, 15, 0, 1 };
    tangents[4] = .{ 0, 25, 0, 1 };
    tangents[5] = .{ 0, 0, 15, 1 };
    tangents[6] = .{ 0, 0,  5, 1 };
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
        var new_pl: [max_num_particles]ParticlesData = undefined;
        for (0..self.particles_count - particle_per_frame) |i| {
            const scale_change = 0.15 / max_num_particles_f;
            const vert_change = scale_change * 100;
            new_pl[i] = self.particles_list[i + 1];
            new_pl[i].ts[0] -= vert_change * new_pl[i].color[3];
            new_pl[i].ts[3] += scale_change;
        }
        for (0..particle_per_frame) |i| {
            const rand_value = self.rand.random().float(f32);
            const i_offset = particle_per_frame - i;
            new_pl[max_num_particles - i_offset] = .{
                .ts = .{ pos[0], pos[1], pos[2], 0.05 },
                .color = .{ color[0], color[1], color[2], rand_value },
            };
        }
        self.particles_list = new_pl;
    } else {
        var new_pl: [max_num_particles]ParticlesData = undefined;
        for (0..self.particles_count) |i| {
            const scale_change = 0.15 / max_num_particles_f;
            const vert_change = scale_change * 100;
            new_pl[i] = self.particles_list[i + 1];
            new_pl[i].ts[0] -= vert_change * new_pl[i].color[3];
            new_pl[i].ts[3] += scale_change;
        }
        for (0..particle_per_frame) |_| {
            const rand_value = self.rand.random().float(f32);
            self.particles_list = new_pl;
            self.particles_list[self.particles_count] = .{
                .ts = .{ pos[0], pos[1], pos[2], 0.05 },
                .color = .{ color[0], color[1], color[2], rand_value },
            };
            self.particles_count += 1;
            if (self.particles_count >= max_num_particles) break;
        }
    }
    const pd: []const ParticlesData = self.particles_list[0..self.particles_count];
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
    const prog = rhi.createProgram("particles");

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
    s.attachAndLinkAll(self.allocator, shaders[0..], "particles");

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
        .points = object.Points.init(prog, max_num_particles, "particles"),
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
    const prog = rhi.createProgram("party_ball");

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
    s.attachAndLinkAll(self.allocator, shaders[0..], "party_ball");
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
            "partyball",
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

pub fn deleteCubemap(self: *Particles) void {
    const objects: [1]object.object = .{
        self.cubemap,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderCubemap(self: *Particles) void {
    const prog = rhi.createProgram("cube_map");
    self.cubemap_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .cubemap = true,
            .instance_data = true,
            .fragment_shader = .texture,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(cubemap_vert)[0..], "cubemap");
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(20));
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(-0.5, -0.5, -0.5));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 0, 1 },
        };
        i_datas[0] = i_data;
    }
    var parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.initCubemap(
            prog,
            i_datas[0..],
            "cubemap",
        ),
    };
    parallelepiped.parallelepiped.mesh.linear_colorspace = false;
    if (self.cubemap_texture) |*bt| {
        var cm: assets.Cubemap = .{
            .path = "cgpoc\\cubemaps\\milkyway\\cubeMap",
            .textures_loader = self.ctx.textures_loader,
        };
        cm.names[0] = "xp.png";
        cm.names[1] = "xn.png";
        cm.names[2] = "yp.png";
        cm.names[3] = "yn.png";
        cm.names[4] = "zp.png";
        cm.names[5] = "zn.png";
        var images: ?[6]*assets.Image = null;
        if (cm.loadAll(self.allocator)) {
            images = cm.images;
        } else |_| {
            std.debug.print("failed to load textures\n", .{});
        }
        bt.setupCubemap(images, prog, "f_cubemap", "shadowmap_cubemap") catch {
            self.cubemap_texture = null;
        };
    }
    self.cubemap = parallelepiped;
}

const std = @import("std");
const c = @import("../../../c.zig").c;
const rhi = @import("../../../rhi/rhi.zig");
const ui = @import("../../../ui/ui.zig");
const scenes = @import("../../scenes.zig");
const math = @import("../../../math/math.zig");
const physics = @import("../../../physics/physics.zig");
const scenery = @import("../../../scenery/scenery.zig");
const Compiler = @import("../../../../fssc/Compiler.zig");
const object = @import("../../../object/object.zig");
const lighting = @import("../../../lighting/lighting.zig");
const assets = @import("../../../assets/assets.zig");
