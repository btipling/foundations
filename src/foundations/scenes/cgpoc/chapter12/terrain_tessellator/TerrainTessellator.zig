view_camera: *physics.camera.Camera(*TerrainTessallator, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,
ui_state: TerrainTesselatorUI,

terrain_program: u32 = undefined,
terrain_vao: u32 = undefined,
terrain_m: math.matrix = math.matrix.identity(),
terrain_u: rhi.Uniform = undefined,
terrain_t_map: ?rhi.Texture = null,
terrain_t_tex: ?rhi.Texture = null,
terrain_t_nor: ?rhi.Texture = null,

sphere_1: object.object = .{ .norender = .{} },
light_1_position: rhi.Uniform = undefined,
sphere_1_matrix: rhi.Uniform = undefined,
normals_matrix: rhi.Uniform = undefined,

materials: rhi.Buffer,
lights: rhi.Buffer,

const TerrainTessallator = @This();

const sphere_vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");

const mats = [_]lighting.Material{
    lighting.materials.Obsidian,
    lighting.materials.Silver,
    lighting.materials.Gold,
    lighting.materials.Jade,
    lighting.materials.Pearl,
    lighting.materials.Copper,
    lighting.materials.Chrome,
    lighting.materials.Emerald,
    lighting.materials.Ruby,
    lighting.materials.Brass,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Terrain Tessellator",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *TerrainTessallator {
    const tt = allocator.create(TerrainTessallator) catch @panic("OOM");
    errdefer allocator.destroy(tt);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*TerrainTessallator, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        tt,
        integrator,
        .{ 2, -4, 2 },
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
    };
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();

    const ui_state: TerrainTesselatorUI = .{};
    tt.* = .{
        .ui_state = ui_state,
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    tt.rendersphere_1();
    errdefer tt.deletesphere_1();

    tt.renderTerrain();
    errdefer tt.deleteTerrain();

    tt.renderDebugCross();
    errdefer tt.deleteCross();

    return tt;
}

pub fn deinit(self: *TerrainTessallator, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.deleteTerrain();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *TerrainTessallator) void {}

pub fn draw(self: *TerrainTessallator, dt: f64) void {
    if (self.ui_state.light_1.position_updated) {
        const lp = self.ui_state.light_1.position;
        self.sphere_1_matrix.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
        self.light_1_position.setUniform3fv(lp);
        self.ui_state.light_1.position_updated = false;
    }
    if (self.ui_state.light_1.updated) {
        self.updateLights();
        self.deletesphere_1();
        self.rendersphere_1();
        self.ui_state.light_1.updated = false;
    }
    self.view_camera.update(dt);
    {
        const objects: [1]object.object = .{
            self.sphere_1,
        };
        rhi.drawObjects(objects[0..]);
    }
    if (self.terrain_t_tex) |t| {
        t.bind();
    }
    if (self.terrain_t_map) |t| {
        t.bind();
    }
    if (self.terrain_t_nor) |t| {
        t.bind();
    }
    {
        if (self.ui_state.wire_frame) {
            c.glLineWidth(5.0);
            c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
        }
        rhi.runTessalationInstanced(self.terrain_program, 4, 64 * 64);
        if (self.ui_state.wire_frame) {
            c.glLineWidth(1.0);
            c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
        }
    }
    self.cross.draw(dt);
    self.ui_state.draw();
}

pub fn deleteCross(self: *TerrainTessallator) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *TerrainTessallator) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(5, 50, 50),
        5,
    );
}

pub fn deleteTerrain(self: *TerrainTessallator) void {
    rhi.deletePrimitive(self.terrain_program, self.terrain_vao, 0);
}

fn updateLights(self: *TerrainTessallator) void {
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
            .attenuation_constant = self.ui_state.light_1.attenuation_constant,
            .attenuation_linear = self.ui_state.light_1.attenuation_linear,
            .attenuation_quadratic = self.ui_state.light_1.attenuation_quadratic,
            .light_kind = .positional,
        },
    };
    self.lights.deinit();
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();
    self.lights = lights_buf;
}

pub fn renderTerrain(self: *TerrainTessallator) void {
    const prog = rhi.createProgram();
    const vao = rhi.createVAO();

    self.terrain_t_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.terrain_t_tex.?.texture_unit = 2;
    self.terrain_t_map = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.terrain_t_map.?.texture_unit = 3;
    self.terrain_t_nor = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.terrain_t_nor.?.texture_unit = 4;

    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);
    const frag_bindings = [_]usize{ 2, 4 };
    const tes_bindings = [_]usize{3};
    const terrain_vert = Compiler.runWithBytes(self.allocator, @embedFile("terrain_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_vert);
    var terrain_frag = Compiler.runWithBytes(self.allocator, @embedFile("terrain_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_frag);
    terrain_frag = if (!disable_bindless) terrain_frag else rhi.Shader.disableBindless(
        terrain_frag,
        frag_bindings[0..],
    ) catch @panic("bindless");
    const terrain_tcs = Compiler.runWithBytes(self.allocator, @embedFile("terrain_tcs.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_tcs);
    var terrain_tes = Compiler.runWithBytes(self.allocator, @embedFile("terrain_tes.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_tes);
    terrain_tes = if (!disable_bindless) terrain_tes else rhi.Shader.disableBindless(
        terrain_tes,
        tes_bindings[0..],
    ) catch @panic("bindless");

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = terrain_vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = terrain_frag, .shader_type = c.GL_FRAGMENT_SHADER },
        .{ .source = terrain_tcs, .shader_type = c.GL_TESS_CONTROL_SHADER },
        .{ .source = terrain_tes, .shader_type = c.GL_TESS_EVALUATION_SHADER },
    };

    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);

    if (self.terrain_t_tex) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\tessellation\\square_moon_map.jpg") catch null, prog, "f_terrain_samp") catch {
            self.terrain_t_tex = null;
        };
    }
    if (self.terrain_t_map) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\tessellation\\square_moon_bump.jpg") catch null, prog, "f_height_samp") catch {
            self.terrain_t_map = null;
        };
    }
    if (self.terrain_t_nor) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\tessellation\\square_moon_normal.jpg") catch null, prog, "f_normal_samp") catch {
            self.terrain_t_nor = null;
        };
    }
    {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(0, 0, 0));
        m = math.matrix.transformMatrix(m, math.matrix.uniformScale(100));
        var u = rhi.Uniform.init(prog, "f_terrain_m") catch @panic("uniform");
        u.setUniformMatrix(m);
        self.terrain_u = u;
    }
    {
        const m = math.matrix.identity();
        var u = rhi.Uniform.init(prog, "f_normal_rot_m") catch @panic("uniform");
        u.setUniformMatrix(m);
        self.normals_matrix = u;
    }
    {
        var lp1: rhi.Uniform = rhi.Uniform.init(prog, "f_light_1_pos") catch .{ .program = prog, .location = 0 };
        lp1.setUniform3fv(self.ui_state.light_1.position);
        self.light_1_position = lp1;
    }
    self.terrain_program = prog;
    self.terrain_vao = vao;
}

pub fn deletesphere_1(self: *TerrainTessallator) void {
    const objects: [1]object.object = .{
        self.sphere_1,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn rendersphere_1(self: *TerrainTessallator) void {
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
    var sm: rhi.Uniform = rhi.Uniform.init(prog, "f_sphere_matrix") catch @panic("uniform failed");
    sm.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
    self.sphere_1_matrix = sm;
    self.sphere_1 = sphere;
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
const TerrainTesselatorUI = @import("TerrainTessellatorUI.zig");
