view_camera: *physics.camera.Camera(*TorusGeometry, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

inflated_torus: object.object = .{ .norender = .{} },
add_torus: object.object = .{ .norender = .{} },
del_torus: object.object = .{ .norender = .{} },
change_torus: object.object = .{ .norender = .{} },
expode_torus: object.object = .{ .norender = .{} },

materials: rhi.Buffer,
lights: rhi.Buffer,

const TorusGeometry = @This();

const mats = [_]lighting.Material{
    lighting.materials.Gold,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Torus Geometry",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *TorusGeometry {
    const tg = allocator.create(TorusGeometry) catch @panic("OOM");
    errdefer allocator.destroy(tg);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*TorusGeometry, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        tg,
        integrator,
        .{ 2, -10, 0 },
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

    tg.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    tg.renderInflated();
    errdefer tg.deleteInflated();

    tg.renderAdd();
    errdefer tg.deleteAdd();

    tg.renderDel();
    errdefer tg.deleteDel();

    tg.renderChange();
    errdefer tg.deleteChange();

    tg.renderExplode();
    errdefer tg.deleteExplode();

    tg.renderDebugCross();
    errdefer tg.deleteCross();

    return tg;
}

pub fn deinit(self: *TorusGeometry, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.deleteInflated();
    self.deleteAdd();
    self.deleteDel();
    self.deleteChange();
    self.deleteExplode();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *TorusGeometry) void {}

pub fn draw(self: *TorusGeometry, dt: f64) void {
    self.view_camera.update(dt);
    {
        const objects: [5]object.object = .{
            self.inflated_torus,
            self.add_torus,
            self.del_torus,
            self.change_torus,
            self.expode_torus,
        };
        rhi.drawObjects(objects[0..]);
    }
    self.cross.draw(dt);
}

pub fn deleteCross(self: *TorusGeometry) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *TorusGeometry) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

pub fn deleteInflated(self: *TorusGeometry) void {
    self.deleteTorus(self.inflated_torus);
}

pub fn renderInflated(self: *TorusGeometry) void {
    const m = math.matrix.translate(-0.5, 0, 0);
    self.inflated_torus = self.renderTorus(@embedFile("inflated_geo.glsl"), m);
}

pub fn deleteAdd(self: *TorusGeometry) void {
    self.deleteTorus(self.add_torus);
}

pub fn renderAdd(self: *TorusGeometry) void {
    const m = math.matrix.translate(0, -1, -1);
    self.add_torus = self.renderTorus(@embedFile("add_geo.glsl"), m);
}

pub fn deleteDel(self: *TorusGeometry) void {
    self.deleteTorus(self.del_torus);
}

pub fn renderDel(self: *TorusGeometry) void {
    const m = math.matrix.translate(0, 1, -1);
    self.del_torus = self.renderTorus(@embedFile("del_geo.glsl"), m);
}

pub fn deleteChange(self: *TorusGeometry) void {
    self.deleteTorus(self.change_torus);
}

pub fn renderChange(self: *TorusGeometry) void {
    const m = math.matrix.translate(0, -1, 1);
    self.change_torus = self.renderTorus(@embedFile("change_geo.glsl"), m);
}

pub fn deleteExplode(self: *TorusGeometry) void {
    self.deleteTorus(self.expode_torus);
}

pub fn renderExplode(self: *TorusGeometry) void {
    const m = math.matrix.translate(0, 1, 1);
    self.expode_torus = self.renderTorus(@embedFile("explode_geo.glsl"), m);
}

pub fn deleteTorus(_: *TorusGeometry, obj: object.object) void {
    const objects: [1]object.object = .{obj};
    rhi.deleteObjects(objects[0..]);
}

pub fn renderTorus(self: *TorusGeometry, geo_shader: []const u8, m: math.matrix) object.object {
    const prog = rhi.createProgram();

    const torus_vert = Compiler.runWithBytes(self.allocator, @embedFile("torus_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(torus_vert);

    const torus_frag = Compiler.runWithBytes(self.allocator, @embedFile("torus_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(torus_frag);

    const torus_geo = Compiler.runWithBytes(self.allocator, geo_shader) catch @panic("shader compiler");
    defer self.allocator.free(torus_geo);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = torus_vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = torus_frag, .shader_type = c.GL_FRAGMENT_SHADER },
        .{ .source = torus_geo, .shader_type = c.GL_GEOMETRY_SHADER },
    };

    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);

    var i_datas: [1]rhi.instanceData = undefined;
    {
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
    torus.torus.mesh.cull = false;
    return torus;
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const rhi = @import("../../../../rhi/rhi.zig");
const ui = @import("../../../../ui/ui.zig");
const scenes = @import("../../../scenes.zig");
const math = @import("../../../../math/math.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");
const Compiler = @import("../../../../../fssc/Compiler.zig");
const object = @import("../../../../object/object.zig");
const lighting = @import("../../../../lighting/lighting.zig");
