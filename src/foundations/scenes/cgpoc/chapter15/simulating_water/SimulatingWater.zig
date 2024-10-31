view_camera: *physics.camera.Camera(*SimulatingWater, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

grid: object.object = .{ .norender = .{} },

materials: rhi.Buffer,
lights: rhi.Buffer,

const SimulatingWater = @This();

const mats = [_]lighting.Material{
    lighting.materials.Silver,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Simulating Water",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *SimulatingWater {
    const t3d = allocator.create(SimulatingWater) catch @panic("OOM");
    errdefer allocator.destroy(t3d);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*SimulatingWater, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        t3d,
        integrator,
        .{ 2, -5, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd, "materials");
    errdefer mats_buf.deinit();

    var light_direction: math.vector.vec4 = .{ 0, 1, 0, 0 };
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(std.math.pi));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(std.math.pi / 2.0));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(std.math.pi / 2.0));
    light_direction = math.matrix.transformVector(m, light_direction);
    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = light_direction,
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
    };
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld, "lights");
    errdefer lights_buf.deinit();

    t3d.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    t3d.renderDebugCross();
    errdefer t3d.deleteCross();

    t3d.renderGrid();
    errdefer rhi.deleteObject(t3d.grid);

    return t3d;
}

pub fn deinit(self: *SimulatingWater, allocator: std.mem.Allocator) void {
    rhi.deleteObject(self.grid);
    self.deleteCross();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *SimulatingWater) void {}

pub fn draw(self: *SimulatingWater, dt: f64) void {
    self.view_camera.update(dt);
    // {
    //     if (self.sky_tex) |t| {
    //         t.bind();
    //     }
    //     const dtt = dt * 0.1;
    //     self.sky_rot.?.setUniformMatrix(math.matrix.rotationX(@floatCast(dtt)));
    //     self.sky_depth += @floatCast(dtt * 0.00003);
    //     if (self.sky_depth >= 0.99) {
    //         self.sky_depth = 0.01;
    //     }
    //     self.sky_dep.?.setUniform1f(self.sky_depth);
    //     rhi.drawHorizon(self.sphere);
    // }
    {
        rhi.drawObject(self.grid);
    }
    self.cross.draw(dt);
}

fn deleteCross(self: *SimulatingWater) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *SimulatingWater) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0.05, -0.025, -0.025),
        5,
    );
}

fn renderGrid(self: *SimulatingWater) void {
    var grid_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\grid\\grid.obj") catch null) |o| {
        grid_model = o;
    } else {
        return;
    }
    const prog = rhi.createProgram("floor");

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("floor_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    const frag = Compiler.runWithBytes(self.allocator, @embedFile("floor_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..], "floor");
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translateVec(.{ -0.5, -500, -500 }));
    m = math.matrix.transformMatrix(m, math.matrix.scale(0.5, 1000, 1000));
    const i_datas = [_]rhi.instanceData{
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        },
    };

    var grid_obj = .{ .parallelepiped = object.Parallelepiped.init(prog, i_datas[0..], "floor") };
    grid_obj.parallelepiped.mesh.linear_colorspace = true;
    self.grid = grid_obj;
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
const assets = @import("../../../../assets/assets.zig");
const rendering = @import("../../../../rendering/rendering.zig");
