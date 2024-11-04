allocator: std.mem.Allocator,
ui_state: ShadowsUI,
bg: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Shadows, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,

materials: lighting.Material.SSBO,
lights: lighting.Light.SSBO,

// Shadows
shadowmaps: [num_maps]rhi.Texture = undefined,
shadowmap_program: u32 = 0,
shadow_uniform: rhi.Uniform = undefined,
shadow_x_up: rhi.Uniform = undefined,
shadow_framebuffers: [num_maps]rhi.Framebuffer = undefined,
f_shadow_m: rhi.Uniform = undefined,

// Objects
object_1: object.object = .{ .norender = .{} },
object_1_m: rhi.Uniform = undefined,
object_1_material_selection: rhi.Uniform = undefined,
obj_1_m: math.matrix = math.matrix.identity(),
obj_1_xup: math.matrix = math.matrix.identity(),

object_2: object.object = .{ .norender = .{} },
object_2_m: rhi.Uniform = undefined,
object_2_material_selection: rhi.Uniform = undefined,
obj_2_m: math.matrix = math.matrix.identity(),
obj_2_xup: math.matrix = math.matrix.identity(),

// Lights
sphere_1: object.object = .{ .norender = .{} },
sphere_1_matrix: rhi.Uniform = undefined,
light_1_view_ms: [6]math.matrix = undefined,

sphere_2: object.object = .{ .norender = .{} },
sphere_2_matrix: rhi.Uniform = undefined,
light_2_view_ms: [6]math.matrix = undefined,

scene_data_buffer: rhi.storage_buffer.Buffer(SceneData, rhi.storage_buffer.bbp_chapter8_shadows, c.GL_DYNAMIC_DRAW) = undefined,
scene_data: SceneData = .{},
should_gen_shadow_map: bool = false,
generated_shadow_map: bool = false,

cross: scenery.debug.Cross = undefined,

const num_maps: usize = 12;

const empty_4: [4]f32 = .{ 0, 0, 0, 0 };
const empty_m: [16]f32 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

pub const SceneData = struct {
    light_1_position: [4]f32 = empty_4,
    light_1_attenuation: [4]f32 = empty_4,
    light_1_views: [6][16]f32 = .{ empty_m, empty_m, empty_m, empty_m, empty_m, empty_m },
    light_2_position: [4]f32 = empty_4,
    light_2_attenuation: [4]f32 = empty_4,
    light_2_views: [6][16]f32 = .{ empty_m, empty_m, empty_m, empty_m, empty_m, empty_m },
};

// light views
// index 0 is z pos
// index 1 is y neg
// index 2 is z neg
// index 3 is y pos
// index 4 is x pos
// index 5 is x neg

const Shadows = @This();

const shadow_vertex_shader: []const u8 = @embedFile("shadow_vert.glsl");
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
        .name = "Shadows",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Shadows {
    const pd = allocator.create(Shadows) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*Shadows, physics.Integrator(physics.SmoothDeceleration)).init(
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

    const sd: SceneData = .{};
    var scene_data_buffer = rhi.storage_buffer.Buffer(SceneData, rhi.storage_buffer.bbp_chapter8_shadows, c.GL_DYNAMIC_DRAW).init(sd, "scene_data");
    errdefer scene_data_buffer.deinit();

    const ui_state: ShadowsUI = .{};
    pd.* = .{
        .allocator = allocator,
        .ui_state = ui_state,
        .view_camera = cam,
        .ctx = ctx,
        .materials = mats_buf,
        .lights = lights_buf,
        .scene_data_buffer = scene_data_buffer,
    };

    pd.lightDataToMat();

    pd.renderBG();
    errdefer pd.deleteBG();

    pd.setupShadowmaps();

    pd.renderObject_1();
    errdefer pd.deleteObject_1();

    pd.renderObject_2();
    errdefer pd.deleteObject_2();

    pd.rendersphere_1();
    errdefer pd.deletesphere_1();

    pd.rendersphere_2();
    errdefer pd.deletesphere_2();

    pd.renderDebugCross();
    errdefer pd.deleteCross();

    pd.generateLightViewMatrices(pd.ui_state.light_1, 1);
    pd.generateLightViewMatrices(pd.ui_state.light_2, 2);
    pd.updateSceneData();
    pd.genShadowMap();

    return pd;
}

pub fn deinit(self: *Shadows, allocator: std.mem.Allocator) void {
    // objects
    self.deleteCross();
    self.deleteBG();
    self.deleteObject_1();
    self.deleteObject_2();
    self.deletesphere_1();
    self.deletesphere_2();
    // camera
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    // buffers
    self.scene_data_buffer.deinit();
    self.scene_data = undefined;
    self.materials.deinit();
    self.materials = undefined;
    self.lights.deinit();
    self.lights = undefined;
    // self
    allocator.destroy(self);
}

fn updateLights(self: *Shadows) void {
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

fn getObjectMatrix(object_settings: ShadowsUI.objectSetting) math.matrix {
    const op = object_settings.position;
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(op[0], op[1], op[2]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(object_settings.rotation[0]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(object_settings.rotation[1]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(object_settings.rotation[2]));
    return m;
}

fn threeToFour(v: [3]f32, w: f32) [4]f32 {
    return .{ v[0], v[1], v[2], w };
}

fn lightDataToMat(self: *Shadows) void {
    const l1 = self.ui_state.light_1;
    const l2 = self.ui_state.light_2;
    self.scene_data.light_1_position = threeToFour(l1.position, 1);
    self.scene_data.light_1_attenuation = threeToFour(l1.attenuation, 0);
    self.scene_data.light_2_position = threeToFour(l2.position, 1);
    self.scene_data.light_2_attenuation = threeToFour(l2.attenuation, 0);
}

fn updateSceneData(self: *Shadows) void {
    self.scene_data_buffer.update(self.scene_data);
}

pub fn draw(self: *Shadows, dt: f64) void {
    if (self.ui_state.light_1.data_updated) {
        self.generateLightViewMatrices(self.ui_state.light_1, 1);
        const lp = self.ui_state.light_1.position;
        self.sphere_1_matrix.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
        self.lightDataToMat();
        self.updateSceneData();
        self.ui_state.light_1.data_updated = false;
        self.should_gen_shadow_map = true;
    }
    if (self.ui_state.light_2.data_updated) {
        self.generateLightViewMatrices(self.ui_state.light_2, 2);
        const lp = self.ui_state.light_2.position;
        self.sphere_2_matrix.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
        self.lightDataToMat();
        self.updateSceneData();
        self.ui_state.light_2.data_updated = false;
        self.should_gen_shadow_map = true;
    }
    if (self.ui_state.object_1.transform_updated) {
        self.obj_1_m = getObjectMatrix(self.ui_state.object_1);
        self.object_1_m.setUniformMatrix(self.obj_1_m);
        self.ui_state.object_1.transform_updated = false;
        self.should_gen_shadow_map = true;
    }
    if (self.ui_state.object_2.transform_updated) {
        self.obj_2_m = getObjectMatrix(self.ui_state.object_2);
        self.object_2_m.setUniformMatrix(self.obj_2_m);
        self.ui_state.object_2.transform_updated = false;
        self.should_gen_shadow_map = true;
    }
    if (self.ui_state.object_1.updated) {
        self.deleteObject_1();
        self.renderObject_1();
        self.ui_state.object_1.updated = false;
        self.should_gen_shadow_map = true;
    }
    if (self.ui_state.object_2.updated) {
        self.deleteObject_2();
        self.renderObject_2();
        self.ui_state.object_2.updated = false;
        self.should_gen_shadow_map = true;
    }
    if (self.ui_state.light_1.updated) {
        self.updateLights();
        self.deletesphere_1();
        self.rendersphere_1();
        self.ui_state.light_1.updated = false;
        self.should_gen_shadow_map = true;
    }
    if (self.ui_state.light_2.updated) {
        self.updateLights();
        self.deletesphere_2();
        self.rendersphere_2();
        self.ui_state.light_2.updated = false;
        self.should_gen_shadow_map = true;
    }
    if (!self.generated_shadow_map and self.should_gen_shadow_map) {
        self.genShadowMap();
        self.should_gen_shadow_map = false;
    }
    self.view_camera.update(dt);

    for (self.shadowmaps) |t| {
        t.bind();
    }

    {
        const objects: [1]object.object = .{
            self.bg,
        };
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [4]object.object = .{
            self.sphere_1,
            self.sphere_2,
            self.object_1,
            self.object_2,
        };
        rhi.drawObjects(objects[0..]);
    }
    self.generated_shadow_map = false;
    self.cross.draw(dt);
    self.ui_state.draw();
    if (self.should_gen_shadow_map) {
        self.genShadowMap();
        self.should_gen_shadow_map = false;
    }
}

pub fn updateCamera(_: *Shadows) void {}

pub fn deleteBG(self: *Shadows) void {
    const objects: [1]object.object = .{
        self.bg,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderBG(self: *Shadows) void {
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

pub fn deleteObject_1(self: *Shadows) void {
    self.deleteObject(self.object_1);
}

pub fn deleteObject_2(self: *Shadows) void {
    self.deleteObject(self.object_2);
}

pub fn deleteObject(self: *Shadows, obj: object.object) void {
    switch (obj) {
        inline else => |o| {
            for (0..self.shadowmaps.len) |i| {
                var t = self.shadowmaps[i];
                t.removeUniform(o.mesh.program);
                self.shadowmaps[i] = t;
            }
        },
    }
    const objects: [1]object.object = .{
        obj,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderObject(self: *Shadows, obj_setting: ShadowsUI.objectSetting, prog: u32) object.object {
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .shadowmaps = true,
            .fragment_shader = if (self.shadowmaps[0].disable_bindless == false) .bindless else .texture,
        };
        switch (obj_setting.model) {
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
        switch (self.ui_state.current_lights) {
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
        s.attach(self.allocator, @ptrCast(partials[0..]), "object");
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

    var render_object: object.object = s: switch (obj_setting.model) {
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
                    "cone_model",
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
    switch (render_object) {
        inline else => |*o| {
            o.mesh.shadowmap_program = self.shadowmap_program;
        },
    }
    switch (render_object) {
        inline else => |o| {
            std.debug.assert(o.mesh.shadowmap_program != 0);
        },
    }

    for (0..self.shadowmaps.len) |i| {
        var t = self.shadowmaps[i];
        _ = switch (i) {
            0 => t.addUniform(prog, "f_shadow_texture0"),
            1 => t.addUniform(prog, "f_shadow_texture1"),
            2 => t.addUniform(prog, "f_shadow_texture2"),
            3 => t.addUniform(prog, "f_shadow_texture3"),
            4 => t.addUniform(prog, "f_shadow_texture4"),
            5 => t.addUniform(prog, "f_shadow_texture5"),
            6 => t.addUniform(prog, "f_shadow_texture6"),
            7 => t.addUniform(prog, "f_shadow_texture7"),
            8 => t.addUniform(prog, "f_shadow_texture8"),
            9 => t.addUniform(prog, "f_shadow_texture9"),
            10 => t.addUniform(prog, "f_shadow_texture10"),
            11 => t.addUniform(prog, "f_shadow_texture11"),
            else => {},
        } catch @panic("uniform failed");
        self.shadowmaps[i] = t;
    }
    return render_object;
}

pub fn renderObject_1(self: *Shadows) void {
    const prog = rhi.createProgram("object1");
    self.object_1 = self.renderObject(self.ui_state.object_1, prog);

    switch (self.object_1) {
        .obj => {
            self.obj_1_xup = math.matrix.transpose(math.matrix.mc(.{
                0, 0, -1, 0,
                1, 0, 0,  0,
                0, 1, 0,  0,
                0, 0, 0,  1,
            }));
        },
        else => {
            self.obj_1_xup = math.matrix.identity();
        },
    }

    var msu: rhi.Uniform = rhi.Uniform.init(prog, "f_material_selection") catch @panic("uniform failed");
    msu.setUniform1ui(self.ui_state.object_1.material);
    self.object_1_material_selection = msu;

    var om: rhi.Uniform = rhi.Uniform.init(prog, "f_object_m") catch @panic("uniform failed");
    self.obj_1_m = getObjectMatrix(self.ui_state.object_1);
    om.setUniformMatrix(self.obj_1_m);
    self.object_1_m = om;
}

pub fn renderObject_2(self: *Shadows) void {
    const prog = rhi.createProgram("object2");
    self.object_2 = self.renderObject(self.ui_state.object_2, prog);

    switch (self.object_2) {
        .obj => {
            self.obj_2_xup = math.matrix.transpose(math.matrix.mc(.{
                0, 0, -1, 0,
                1, 0, 0,  0,
                0, 1, 0,  0,
                0, 0, 0,  1,
            }));
        },
        else => {
            self.obj_2_xup = math.matrix.identity();
        },
    }

    var msu: rhi.Uniform = rhi.Uniform.init(prog, "f_material_selection") catch @panic("uniform failed");
    msu.setUniform1ui(self.ui_state.object_2.material);
    self.object_2_material_selection = msu;

    var om: rhi.Uniform = rhi.Uniform.init(prog, "f_object_m") catch @panic("uniform failed");
    self.obj_2_m = getObjectMatrix(self.ui_state.object_2);
    om.setUniformMatrix(self.obj_2_m);
    self.object_2_m = om;
}

pub fn deletesphere_1(self: *Shadows) void {
    const objects: [1]object.object = .{
        self.sphere_1,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn rendersphere_1(self: *Shadows) void {
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

pub fn deletesphere_2(self: *Shadows) void {
    const objects: [1]object.object = .{
        self.sphere_2,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn rendersphere_2(self: *Shadows) void {
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

fn setupShadowmaps(self: *Shadows) void {
    self.shadowmap_program = rhi.createProgram("shadow_map");
    {
        var s: rhi.Shader = .{
            .program = self.shadowmap_program,
            .instance_data = true,
            .fragment_shader = .shadow,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(shadow_vertex_shader)[0..], "shadowmap");
    }

    var shadow_uniform: rhi.Uniform = rhi.Uniform.init(self.shadowmap_program, "f_shadow_vp") catch @panic("uniform failed");
    shadow_uniform.setUniformMatrix(math.matrix.identity());
    self.shadow_uniform = shadow_uniform;

    var f_shadow_m: rhi.Uniform = rhi.Uniform.init(self.shadowmap_program, "f_shadow_m") catch @panic("uniform failed");
    f_shadow_m.setUniformMatrix(math.matrix.identity());
    self.f_shadow_m = f_shadow_m;

    var shadow_x_up: rhi.Uniform = rhi.Uniform.init(self.shadowmap_program, "f_xup_shadow") catch @panic("uniform failed");
    shadow_x_up.setUniformMatrix(math.matrix.transpose(math.matrix.identity()));
    self.shadow_x_up = shadow_x_up;
    for (0..self.shadowmaps.len) |i| {
        self.genShadowmapTexture(i);
    }
}

fn genShadowmapTexture(self: *Shadows, i: usize) void {
    var shadow_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch @panic("unable to create shadow texture");
    errdefer shadow_texture.deinit();
    shadow_texture.setupShadow(
        self.ctx.cfg.fb_width,
        self.ctx.cfg.fb_height,
        "shadowmap",
    ) catch @panic("unable to setup shadow texture");
    shadow_texture.texture_unit = @intCast(4 + i);
    self.shadowmaps[i] = shadow_texture;

    var shadow_framebuffer = rhi.Framebuffer.init();
    errdefer shadow_framebuffer.deinit();

    shadow_framebuffer.setupForShadowMap(shadow_texture) catch @panic("unable to setup shadow map framebuffer");
    self.shadow_framebuffers[i] = shadow_framebuffer;
}

pub fn genShadowMap(self: *Shadows) void {
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LEQUAL);

    c.glEnable(c.GL_POLYGON_OFFSET_FILL);
    for (self.shadowmaps, 0..) |_, i| {
        self.shadow_framebuffers[i].bind();
        if (i < 6) {
            const sm = self.light_1_view_ms[i];
            self.shadow_uniform.setUniformMatrix(sm);
        } else {
            const sm = self.light_2_view_ms[i - 6];
            self.shadow_uniform.setUniformMatrix(sm);
        }
        c.glClear(c.GL_DEPTH_BUFFER_BIT);

        {
            self.shadow_x_up.setUniformMatrix(self.obj_1_xup);
            c.glPolygonOffset(
                @floatCast(self.ui_state.object_1.polygon_factor),
                @floatCast(self.ui_state.object_1.polygon_unit),
            );
            self.f_shadow_m.setUniformMatrix(self.obj_1_m);
            var o1 = self.object_1;
            switch (o1) {
                inline else => |*o| {
                    o.mesh.gen_shadowmap = true;
                },
            }
            const objects: [1]object.object = .{o1};
            rhi.drawObjects(objects[0..]);
        }
        {
            self.shadow_x_up.setUniformMatrix(self.obj_2_xup);
            c.glPolygonOffset(
                @floatCast(self.ui_state.object_2.polygon_factor),
                @floatCast(self.ui_state.object_2.polygon_unit),
            );
            self.f_shadow_m.setUniformMatrix(self.obj_2_m);
            var o2 = self.object_2;
            switch (o2) {
                inline else => |*o| {
                    o.mesh.gen_shadowmap = true;
                },
            }
            const objects: [1]object.object = .{o2};
            rhi.drawObjects(objects[0..]);
        }
        self.shadow_framebuffers[i].unbind();
    }
    c.glClear(c.GL_DEPTH_BUFFER_BIT);
    c.glDisable(c.GL_POLYGON_OFFSET_FILL);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LEQUAL);
}

fn setLightViewMatrix(self: *Shadows, tm: math.matrix, light_num: usize, i: usize) void {
    const s = @as(f32, @floatFromInt(self.ctx.cfg.width)) / @as(f32, @floatFromInt(self.ctx.cfg.height));
    const g: f32 = 1.0 / @tan(self.ctx.cfg.fovy * 0.5);
    var P = math.matrix.perspectiveProjectionCamera(g, s, 0.01, 750);
    P = math.matrix.transformMatrix(P, math.matrix.leftHandedXUpToNDC());
    const m = math.matrix.transformMatrix(P, tm);
    const light_view = math.matrix.transformMatrix(math.matrix.transpose(math.matrix.mc(.{
        0.5, 0.0, 0.0, 0.0,
        0.0, 0.5, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.5, 0.5, 0.0, 1.0,
    })), m).array();
    if (light_num == 1) {
        self.light_1_view_ms[i] = m;
        self.scene_data.light_1_views[i] = light_view;
    } else {
        self.light_2_view_ms[i] = m;
        self.scene_data.light_2_views[i] = light_view;
    }
}

fn generateLightViewMatrices(self: *Shadows, light: ShadowsUI.lightSetting, light_num: usize) void {
    const pos = light.position;
    // const angle_1: f32 = 0;
    var angle: f32 = 0;
    for (0..4) |i| {
        // const i_f: f32 = @floatFromInt(i);
        angle += std.math.pi / 2.0;
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(pos[0], pos[1], pos[2]));
        m = math.matrix.transformMatrix(m, math.matrix.rotationX(angle));
        m = math.matrix.cameraInverse(m);
        self.setLightViewMatrix(m, light_num, i);
    }
    {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(pos[0], pos[1], pos[2]));
        m = math.matrix.transformMatrix(m, math.matrix.rotationZ(std.math.pi / 2.0));
        m = math.matrix.cameraInverse(m);
        self.setLightViewMatrix(m, light_num, 4);
    }
    {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(pos[0], pos[1], pos[2]));
        m = math.matrix.transformMatrix(m, math.matrix.rotationZ(-std.math.pi / 2.0));
        m = math.matrix.cameraInverse(m);
        self.setLightViewMatrix(m, light_num, 5);
    }
}

pub fn deleteCross(self: *Shadows) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *Shadows) void {
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
const ShadowsUI = @import("ShadowsUI.zig");
const assets = @import("../../../../assets/assets.zig");
