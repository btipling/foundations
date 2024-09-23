allocator: std.mem.Allocator,
pyramid: object.object = .{ .norender = .{} },
pyramid_uniform: rhi.Uniform = .empty,
parallelepiped: object.object = .{ .norender = .{} },
parallelepiped_uniform: rhi.Uniform = .empty,
cylinder: object.object = .{ .norender = .{} },
cylinder_uniform: rhi.Uniform = .empty,
view_camera: *physics.camera.Camera(*SimpleSolarSystem, physics.Integrator(physics.SmoothDeceleration)),
stack: [10]math.matrix = undefined,
current_stack_index: u8 = 0,
materials: rhi.Buffer,
lights: rhi.Buffer,

const SimpleSolarSystem = @This();

const num_cubes = 1;

const vertex_shader: []const u8 = @embedFile("blinn_phong_vert.glsl");
const frag_shader: []const u8 = @embedFile("blinn_phong_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Simple Solar System",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *SimpleSolarSystem {
    const pd = allocator.create(SimpleSolarSystem) catch @panic("OOM");

    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*SimpleSolarSystem, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 3, -15, 0 },
        0,
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
        .materials = mats_buf,
        .lights = lights_buf,
    };
    pd.stack[0] = math.matrix.identity();
    pd.renderPyramid();
    pd.renderParallepiped();
    pd.renderCylinder();
    return pd;
}

pub fn deinit(self: *SimpleSolarSystem, allocator: std.mem.Allocator) void {
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    self.materials.deinit();
    self.materials = undefined;
    self.lights.deinit();
    self.lights = undefined;
    allocator.destroy(self);
}

fn pushStack(self: *SimpleSolarSystem, m: math.matrix) void {
    const next_stack_index = self.current_stack_index + 1;
    self.stack[next_stack_index] = math.matrix.transformMatrix(self.stack[self.current_stack_index], m);
    self.current_stack_index = next_stack_index;
}

fn popStack(self: *SimpleSolarSystem) void {
    self.current_stack_index -= 1;
}

fn resetStack(self: *SimpleSolarSystem) void {
    self.current_stack_index = 0;
}

pub fn draw(self: *SimpleSolarSystem, dt: f64) void {
    // pyramid == sun
    // sun position already at 0
    // sun rotation
    self.pushStack(math.matrix.rotationX(@floatCast(dt)));
    self.pyramid_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.popStack(); // remove sun rotation
    // cube == planet
    self.pushStack(math.matrix.translate(
        0,
        @sin(@as(f32, @floatCast(dt))) * 8.0,
        @cos(@as(f32, @floatCast(dt))) * 8.0,
    ));
    self.pushStack(math.matrix.rotationX(@as(f32, @floatCast(dt)) * -2.0));
    self.pushStack(math.matrix.translate(
        -0.5,
        -0.5,
        -0.5,
    ));
    self.parallelepiped_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.popStack(); // remove earth rotation
    self.popStack();
    // cylinder == moon
    self.pushStack(math.matrix.translate(
        @cos(@as(f32, @floatCast(dt))) * 1.5,
        0,
        @sin(@as(f32, @floatCast(dt))) * 1.5,
    ));
    self.pushStack(math.matrix.rotationY(@as(f32, @floatCast(dt)) * 2.0));
    self.cylinder_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.resetStack();
    self.view_camera.update(dt);
    {
        const objects: [3]object.object = .{
            self.pyramid,
            self.parallelepiped,
            self.cylinder,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *SimpleSolarSystem) void {}

pub fn renderPyramid(self: *SimpleSolarSystem) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .xup = .wavefront,
            .lighting = .blinn_phong,
            .frag_body = frag_shader,
            // .fragment_shader = rhi.Texture.frag_shader(self.dolphin_texture),
            .fragment_shader = .lighting,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    const cm = math.matrix.identity();
    const i_data: rhi.instanceData = .{
        .t_column0 = cm.columns[0],
        .t_column1 = cm.columns[1],
        .t_column2 = cm.columns[2],
        .t_column3 = cm.columns[3],
        .color = .{ 1, 0, 1, 1 },
    };
    var i_datas: [num_cubes]rhi.instanceData = undefined;
    for (0..num_cubes) |i| {
        i_datas[i] = i_data;
    }
    const pyramid: object.object = .{
        .pyramid = object.Pyramid.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.pyramid = pyramid;
    self.pyramid_uniform = rhi.Uniform.init(prog, "f_model_transform");
}

pub fn renderParallepiped(self: *SimpleSolarSystem) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .xup = .wavefront,
            .lighting = .blinn_phong,
            .frag_body = frag_shader,
            // .fragment_shader = rhi.Texture.frag_shader(self.dolphin_texture),
            .fragment_shader = .lighting,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        const cm = math.matrix.identity();
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.parallelepiped = parallelepiped;
    self.parallelepiped_uniform = rhi.Uniform.init(prog, "f_model_transform");
}

pub fn renderCylinder(self: *SimpleSolarSystem) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .xup = .wavefront,
            .lighting = .blinn_phong,
            .frag_body = frag_shader,
            // .fragment_shader = rhi.Texture.frag_shader(self.dolphin_texture),
            .fragment_shader = .lighting,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(0.5));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const cylinder: object.object = .{
        .cylinder = object.Cylinder.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.cylinder = cylinder;
    self.cylinder_uniform = rhi.Uniform.init(prog, "f_model_transform");
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const scenes = @import("../../../scenes.zig");
const physics = @import("../../../../physics/physics.zig");
const assets = @import("../../../../assets/assets.zig");
const lighting = @import("../../../../lighting/lighting.zig");
