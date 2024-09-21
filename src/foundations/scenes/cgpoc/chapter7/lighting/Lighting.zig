allocator: std.mem.Allocator,
ui_state: LightingUI,
model: object.object = .{ .norender = .{} },
sphere_1: object.object = .{ .norender = .{} },
sphere_2: object.object = .{ .norender = .{} },
bg: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Lighting, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
materials: rhi.Buffer,
lights: rhi.Buffer,
light_1_position: rhi.Uniform = undefined,
light_2_position: rhi.Uniform = undefined,
sphere_1_matrix: rhi.Uniform = undefined,
sphere_2_matrix: rhi.Uniform = undefined,
material_selection: rhi.Uniform = undefined,
torus_prog_index: ?usize = null,
sphere_1_prog_index: ?usize = null,
sphere_2_prog_index: ?usize = null,

const Lighting = @This();

const vertex_static_shader: []const u8 = @embedFile("../../../../shaders/i_obj_static_vert.glsl");
const sphere_vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");

const blinn_phong_vertex_shader: []const u8 = @embedFile("blinn_phong_vert.glsl");
const gouraud_vertex_shader: []const u8 = @embedFile("gouraud_vert.glsl");

const blinn_phong_frag_shader: []const u8 = @embedFile("blinn_phong_frag.glsl");
const phong_frag_shader: []const u8 = @embedFile("phong_frag.glsl");
const gouraud_frag_shader: []const u8 = @embedFile("gouraud_frag.glsl");

const mats = [_]lighting.Material{
    lighting.materials.Gold,
    lighting.materials.Jade,
    lighting.materials.Pearl,
    lighting.materials.Silver,
    lighting.materials.Copper,
    lighting.materials.Chrome,
    lighting.materials.Emerald,
    lighting.materials.Ruby,
    lighting.materials.Obsidian,
    lighting.materials.Brass,
};

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

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ -0.5, -1.0, -0.3, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ -0.5, -1.0, -0.3, 0.0 },
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
    pd.renderModel();
    pd.rendersphere_1();
    pd.rendersphere_2();
    return pd;
}

pub fn deinit(self: *Lighting, allocator: std.mem.Allocator) void {
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

fn updateLights(self: *Lighting) void {
    const ambient_factor: f32 = 0.1;
    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{
                self.ui_state.light_1.color[0] * ambient_factor,
                self.ui_state.light_1.color[1] * ambient_factor,
                self.ui_state.light_1.color[2] * ambient_factor,
                1.0,
            },
            .diffuse = [4]f32{
                self.ui_state.light_1.color[0],
                self.ui_state.light_1.color[1],
                self.ui_state.light_1.color[2],
                1.0,
            },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ -0.5, -1.0, -0.3, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
        .{
            .ambient = [4]f32{
                self.ui_state.light_2.color[0] * ambient_factor,
                self.ui_state.light_2.color[1] * ambient_factor,
                self.ui_state.light_2.color[2] * ambient_factor,
                1.0,
            },
            .diffuse = [4]f32{
                self.ui_state.light_2.color[0],
                self.ui_state.light_2.color[1],
                self.ui_state.light_2.color[2],
                1.0,
            },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ -0.5, -1.0, -0.3, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
    };
    self.lights.deinit();
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();
    self.lights = lights_buf;
}

pub fn draw(self: *Lighting, dt: f64) void {
    if (self.ui_state.light_1.position_updated) {
        const lp = self.ui_state.light_1.position;
        self.sphere_1_matrix.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
        self.light_1_position.setUniform3fv(lp);
        self.ui_state.light_1.position_updated = false;
    }
    if (self.ui_state.light_2.position_updated) {
        const lp = self.ui_state.light_2.position;
        self.sphere_2_matrix.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
        self.light_2_position.setUniform3fv(lp);
        self.ui_state.light_2.position_updated = false;
    }
    if (self.ui_state.model_updated) {
        self.deleteModel();
        self.renderModel();
        self.ui_state.model_updated = false;
    }
    if (self.ui_state.light_1.updated) {
        self.updateLights();
        self.deletesphere_1();
        self.rendersphere_1();
        self.ui_state.light_1.updated = false;
    }
    if (self.ui_state.light_2.updated) {
        self.updateLights();
        self.deletesphere_2();
        self.rendersphere_2();
        self.ui_state.light_2.updated = false;
    }
    self.view_camera.update(dt);
    {
        const objects: [1]object.object = .{
            self.bg,
        };
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [3]object.object = .{
            self.sphere_1,
            self.sphere_2,
            self.model,
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
            .color = .{ 0.01, 0.01, 0.01, 1 },
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

pub fn deleteModel(self: *Lighting) void {
    const objects: [1]object.object = .{
        self.model,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderModel(self: *Lighting) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .lighting,
        };
        var partials: [1][]const u8 = undefined;
        switch (self.ui_state.current_lighting) {
            0 => {
                s.lighting = .blinn_phong;
                s.frag_body = blinn_phong_frag_shader;
                partials = .{blinn_phong_vertex_shader};
            },
            1 => {
                s.lighting = .phong;
                s.frag_body = phong_frag_shader;
                partials = .{blinn_phong_vertex_shader};
            },
            else => {
                s.lighting = .gauraud;
                s.frag_body = gouraud_frag_shader;
                partials = .{gouraud_vertex_shader};
            },
        }
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
    var torus: object.object = .{
        .torus = object.Torus.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    torus.torus.mesh.linear_colorspace = false;

    if (self.torus_prog_index) |i| {
        self.view_camera.updateProgramMutable(prog, i);
    } else {
        self.torus_prog_index = self.view_camera.addProgramMutable(prog);
    }
    self.model = torus;

    var lp1: rhi.Uniform = .init(prog, "f_light_1_pos");
    lp1.setUniform3fv(self.ui_state.light_1.position);
    self.light_1_position = lp1;

    var lp2: rhi.Uniform = .init(prog, "f_light_2_pos");
    lp2.setUniform3fv(self.ui_state.light_2.position);
    self.light_2_position = lp2;

    var msu: rhi.Uniform = .init(prog, "f_material_selection");
    msu.setUniform1ui(self.ui_state.current_material);
    self.material_selection = msu;
}

pub fn deletesphere_1(self: *Lighting) void {
    const objects: [1]object.object = .{
        self.sphere_1,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn rendersphere_1(self: *Lighting) void {
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
        .color = .{
            self.ui_state.light_1.color[0],
            self.ui_state.light_1.color[1],
            self.ui_state.light_1.color[2],
            1,
        },
    };
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    const lp = self.ui_state.light_1.position;
    var sm: rhi.Uniform = .init(prog, "f_sphere_matrix");
    sm.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
    self.sphere_1_matrix = sm;
    if (self.sphere_1_prog_index) |i| {
        self.view_camera.updateProgramMutable(prog, i);
    } else {
        self.sphere_1_prog_index = self.view_camera.addProgramMutable(prog);
    }
    self.sphere_1 = sphere;
}

pub fn deletesphere_2(self: *Lighting) void {
    const objects: [1]object.object = .{
        self.sphere_2,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn rendersphere_2(self: *Lighting) void {
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
        .color = .{
            self.ui_state.light_2.color[0],
            self.ui_state.light_2.color[1],
            self.ui_state.light_2.color[2],
            1,
        },
    };
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    const lp = self.ui_state.light_2.position;
    var sm: rhi.Uniform = .init(prog, "f_sphere_matrix");
    sm.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
    self.sphere_2_matrix = sm;
    if (self.sphere_2_prog_index) |i| {
        self.view_camera.updateProgramMutable(prog, i);
    } else {
        self.sphere_2_prog_index = self.view_camera.addProgramMutable(prog);
    }
    self.sphere_2 = sphere;
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
