allocator: std.mem.Allocator,
ui_state: LightingUI,
model: object.object = .{ .norender = .{} },
sphere_1: object.object = .{ .norender = .{} },
sphere_2: object.object = .{ .norender = .{} },
bg: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Lighting, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,

materials: lighting.Material.SSBO,
lights: lighting.Light.SSBO,

light_1_position: rhi.Uniform = undefined,
light_2_position: rhi.Uniform = undefined,
sphere_1_matrix: rhi.Uniform = undefined,
sphere_2_matrix: rhi.Uniform = undefined,
material_selection: rhi.Uniform = undefined,
model_prog_index: ?usize = null,
sphere_1_prog_index: ?usize = null,
sphere_2_prog_index: ?usize = null,
cross: scenery.debug.Cross = undefined,

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
        .{ 1.5, -16, 3 },
        -(std.math.pi / 8.0),
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
    const ld: []const lighting.Light = lights[0..];
    var lights_buf = lighting.Light.SSBO.init(ld, "lights");
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
    errdefer pd.deleteBG();

    pd.renderModel();
    errdefer pd.deleteModel();

    pd.rendersphere_1();
    errdefer pd.deletesphere_1();

    pd.rendersphere_2();
    errdefer pd.deletesphere_2();

    pd.renderDebugCross();
    errdefer pd.deleteCross();

    return pd;
}

pub fn deinit(self: *Lighting, allocator: std.mem.Allocator) void {
    self.deleteBG();
    self.deleteModel();
    self.deletesphere_1();
    self.deletesphere_2();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    self.materials.deinit();
    self.materials = undefined;
    self.lights.deinit();
    self.lights = undefined;
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
    const ld: []const lighting.Light = lights[0..];
    var lights_buf = lighting.Light.SSBO.init(ld, "lights");
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
    self.cross.draw(dt);
    self.ui_state.draw();
}

pub fn updateCamera(_: *Lighting) void {}

pub fn deleteBG(self: *Lighting) void {
    const objects: [1]object.object = .{
        self.bg,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderBG(self: *Lighting) void {
    const prog = rhi.createProgram("background");
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_static_shader)[0..], "background");
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
            "background",
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
    const prog = rhi.createProgram("model");
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .lighting,
        };
        switch (self.ui_state.current_model) {
            6 => {
                s.xup = .wavefront;
            },
            7 => {
                s.xup = .wavefront;
            },
            8 => {
                s.xup = .wavefront;
            },
            else => {},
        }
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
        s.attach(self.allocator, @ptrCast(partials[0..]), "model");
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        switch (self.ui_state.current_model) {
            6 => {
                cm = math.matrix.transformMatrix(cm, math.matrix.translate(1, -10, 0));
            },
            else => {
                cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, -10, -1));
            },
        }
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

    const model: object.object = s: switch (self.ui_state.current_model) {
        0 => {
            var torus: object.object = .{
                .torus = object.Torus.init(
                    prog,
                    i_datas[0..],
                    "torus_model",
                ),
            };
            torus.torus.mesh.linear_colorspace = false;
            break :s torus;
        },
        1 => {
            var parallelepiped: object.object = .{
                .parallelepiped = object.Parallelepiped.init(
                    prog,
                    i_datas[0..],
                    "parallelepiped_model",
                ),
            };
            parallelepiped.parallelepiped.mesh.linear_colorspace = false;
            break :s parallelepiped;
        },
        2 => {
            var sphere: object.object = .{
                .sphere = object.Sphere.init(
                    prog,
                    i_datas[0..],
                    "sphere_model",
                ),
            };
            sphere.sphere.mesh.linear_colorspace = false;
            break :s sphere;
        },
        3 => {
            var cone: object.object = .{
                .cone = object.Cone.init(
                    prog,
                    i_datas[0..],
                    "object_model",
                ),
            };
            cone.cone.mesh.linear_colorspace = false;
            break :s cone;
        },
        4 => {
            var cylinder: object.object = .{
                .cylinder = object.Cylinder.init(
                    prog,
                    i_datas[0..],
                    "cylinder_model",
                ),
            };
            cylinder.cylinder.mesh.linear_colorspace = false;
            break :s cylinder;
        },
        5 => {
            var pyramid: object.object = .{
                .pyramid = object.Pyramid.init(
                    prog,
                    i_datas[0..],
                    "pyramid_model",
                ),
            };
            pyramid.pyramid.mesh.linear_colorspace = false;
            break :s pyramid;
        },
        6 => {
            var shuttle_model: *assets.Obj = undefined;
            if (self.ctx.obj_loader.loadAsset("cgpoc\\NasaShuttle\\shuttle.obj") catch null) |o| {
                shuttle_model = o;
            } else {
                break :s .{ .norender = .{} };
            }
            break :s shuttle_model.toObject(prog, i_datas[0..], "shuttle_model");
        },
        7 => {
            var dolphin_model: *assets.Obj = undefined;
            if (self.ctx.obj_loader.loadAsset("cgpoc\\Dolphin\\dolphinLowPoly.obj") catch null) |o| {
                dolphin_model = o;
            } else {
                break :s .{ .norender = .{} };
            }
            break :s dolphin_model.toObject(prog, i_datas[0..], "lowpoly_dolphin_model");
        },
        8 => {
            var dolphin_model: *assets.Obj = undefined;
            if (self.ctx.obj_loader.loadAsset("cgpoc\\Dolphin\\dolphinHighPoly.obj") catch null) |o| {
                dolphin_model = o;
            } else {
                break :s .{ .norender = .{} };
            }
            break :s dolphin_model.toObject(prog, i_datas[0..], "highpoly_dolphin_model");
        },
        else => .{ .norender = .{} },
    };

    self.model = model;

    var lp1: rhi.Uniform = rhi.Uniform.init(prog, "f_light_1_pos") catch @panic("uniform failed");
    lp1.setUniform3fv(self.ui_state.light_1.position);
    self.light_1_position = lp1;

    var lp2: rhi.Uniform = rhi.Uniform.init(prog, "f_light_2_pos") catch @panic("uniform failed");
    lp2.setUniform3fv(self.ui_state.light_2.position);
    self.light_2_position = lp2;

    var msu: rhi.Uniform = rhi.Uniform.init(prog, "f_material_selection") catch @panic("uniform failed");
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
    const prog = rhi.createProgram("light1");
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(sphere_vertex_shader)[0..], "light1");
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
            "light1",
        ),
    };
    const lp = self.ui_state.light_1.position;
    var sm: rhi.Uniform = rhi.Uniform.init(prog, "f_sphere_matrix") catch @panic("uniform failed");
    sm.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
    self.sphere_1_matrix = sm;
    self.sphere_1 = sphere;
}

pub fn deletesphere_2(self: *Lighting) void {
    const objects: [1]object.object = .{
        self.sphere_2,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn rendersphere_2(self: *Lighting) void {
    const prog = rhi.createProgram("light2");
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(sphere_vertex_shader)[0..], "light2");
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
            "light2",
        ),
    };
    const lp = self.ui_state.light_2.position;
    var sm: rhi.Uniform = rhi.Uniform.init(prog, "f_sphere_matrix") catch @panic("uniform failed");
    sm.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
    self.sphere_2_matrix = sm;
    self.sphere_2 = sphere;
}

pub fn deleteCross(self: *Lighting) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *Lighting) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
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
const assets = @import("../../../../assets/assets.zig");
