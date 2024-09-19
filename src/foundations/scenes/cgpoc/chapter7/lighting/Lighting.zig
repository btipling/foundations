allocator: std.mem.Allocator,
ui_state: LightingUI,
torus: object.object = .{ .norender = .{} },
sphere: object.object = .{ .norender = .{} },
bg: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Lighting, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
materials: rhi.Buffer,
lights: rhi.Buffer,
light_position: rhi.Uniform = undefined,
sphere_matrix: rhi.Uniform = undefined,

const Lighting = @This();

const vertex_shader: []const u8 = @embedFile("../../../../shaders/i_obj_light_vert.glsl");
const vertex_static_shader: []const u8 = @embedFile("../../../../shaders/i_obj_static_vert.glsl");
const sphere_vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Lighting",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Lighting {
    const pd = allocator.create(Lighting) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*Lighting, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 0, -15, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const mats = [_]lighting.Material{lighting.materials.Gold};
    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{.{
        .ambient = [4]f32{ 0.1, 0.1, 0.3, 1.0 }, // Slight blue tint for ambient
        .diffuse = [4]f32{ 0.7, 0.7, 1.0, 1.0 }, // Cool blue-white for diffuse
        .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 }, // Bright white specular
        .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 }, // Not used for directional lights
        .direction = [4]f32{ -0.5, -1.0, -0.3, 0.0 }, // Coming from above and slightly to the side
        .cutoff = 0.0, // Not used for directional lights
        .exponent = 0.0, // Not used for directional lights
        .attenuation_constant = 1.0, // No attenuation for directional lights
        .attenuation_linear = 0.0, // No attenuation for directional lights
        .attenuation_quadratic = 0.0, // No attenuation for directional lights
        .light_kind = .direction, // Set the light type to directional
    }};
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    errdefer mats_buf.deinit();
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();

    const ui_state: LightingUI = .{};
    pd.* = .{
        .allocator = allocator,
        .ui_state = ui_state,
        .view_camera = cam,
        .ctx = ctx,
        .materials = mats_buf,
        .lights = lights_buf,
    };
    pd.renderBG();
    pd.renderTorus();
    pd.renderSphere();
    return pd;
}

pub fn deinit(self: *Lighting, allocator: std.mem.Allocator) void {
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *Lighting, dt: f64) void {
    if (self.ui_state.light_updated) {
        const lp = self.ui_state.light_position;
        self.sphere_matrix.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
        self.light_position.setUniform3fv(lp);
        self.ui_state.light_updated = false;
    }
    self.view_camera.update(dt);
    {
        const objects: [1]object.object = .{
            self.bg,
        };
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [2]object.object = .{
            self.sphere,
            self.torus,
        };
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

pub fn updateCamera(_: *Lighting) void {}

pub fn renderBG(self: *Lighting) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_static_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.leftHandedXUpToNDC());
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(-1, 0.9999, -3));
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(6));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 0, 0, 0.05, 1 },
        };
        i_datas[0] = i_data;
    }
    var bg: object.object = .{
        .instanced_triangle = object.InstancedTriangle.init(
            prog,
            i_datas[0..],
        ),
    };
    bg.instanced_triangle.mesh.cull = false;
    self.bg = bg;
}

pub fn renderTorus(self: *Lighting) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .lighting,
        };
        const partials = [_][]const u8{vertex_shader};
        s.attach(self.allocator, @ptrCast(partials[0..]));
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, -10, -1));
        cm = math.matrix.transformMatrix(cm, math.matrix.rotationZ(std.math.pi / -4.0));
        cm = math.matrix.transformMatrix(cm, math.matrix.rotationX(std.math.pi / 3.0));
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
    const torus: object.object = .{
        .torus = object.Torus.init(
            prog,
            i_datas[0..],
            false,
        ),
    };

    self.view_camera.addProgram(prog);
    self.torus = torus;
    var lp: rhi.Uniform = .init(prog, "f_light_pos");
    lp.setUniform3fv(self.ui_state.light_position);
    self.light_position = lp;
}

pub fn renderSphere(self: *Lighting) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(sphere_vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    const m = math.matrix.uniformScale(0.125);
    i_datas[0] = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 1, 1, 1, 1 },
    };
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    const lp = self.ui_state.light_position;
    var sm: rhi.Uniform = .init(prog, "f_sphere_matrix");
    sm.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
    self.sphere_matrix = sm;
    self.view_camera.addProgram(prog);
    self.sphere = sphere;
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
const lighting = @import("../../../../lighting/lighting.zig");
const LightingUI = @import("LightingUI.zig");
