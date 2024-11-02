view_camera: *physics.camera.Camera(*Blend, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,
ready: bool = false,

sphere: object.object = .{ .norender = .{} },

bobble: object.object = .{ .norender = .{} },
bobble_positions: [num_bobbles]math.vector.vec3 = undefined,

materials: rhi.Buffer,
lights: rhi.Buffer,

const Blend = @This();

const num_bobbles: usize = 5;

const mats = [_]lighting.Material{
    lighting.materials.GlassyPastelBlue,
    lighting.materials.GlassyPastelLavender,
    lighting.materials.GlassyPastelLemon,
    lighting.materials.GlassyPastelMint,
    lighting.materials.GlassyPastelPink,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Blend",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Blend {
    const blend = allocator.create(Blend) catch @panic("OOM");
    errdefer allocator.destroy(blend);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*Blend, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        blend,
        integrator,
        .{ 1, -25, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd, "materials");
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 0.01 },
            .diffuse = [4]f32{ 0.1, 0.1, 0.1, 0.01 },
            .specular = [4]f32{ 0.1, 0.1, 0.1, 0.01 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 0.05 },
            .direction = [4]f32{ 5, -1.0, -0.3, 0.0 },
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

    blend.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    for (0..num_bobbles) |i| {
        blend.bobble_positions[i] = .{ 1, @as(f32, @floatFromInt(i * 3)) - 20.0, 0 };
    }

    blend.renderDebugCross();
    errdefer blend.deleteCross();

    blend.renderSphere();
    errdefer rhi.deleteObject(blend.sphere);

    blend.renderBobbles();
    errdefer rhi.deleteObject(blend.bobble);

    blend.ready = true;
    blend.sortBobbles();

    return blend;
}

pub fn deinit(self: *Blend, allocator: std.mem.Allocator) void {
    rhi.deleteObject(self.bobble);
    rhi.deleteObject(self.sphere);
    self.deleteCross();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(self: *Blend) void {
    self.sortBobbles();
}

fn sortBobbles(self: *Blend) void {
    const SortData = struct {
        position: math.vector.vec3,
        distance: f32,
        instance: usize,
        fn sort(_: void, lhs: @This(), rhs: @This()) bool {
            return lhs.distance > rhs.distance;
        }
    };
    if (!self.ready) return;
    var distances: [num_bobbles]SortData = undefined;
    std.debug.print("\n", .{});
    for (0..num_bobbles) |i| {
        distances[i] = .{
            .position = self.bobble_positions[i],
            .distance = math.vector.distance(self.bobble_positions[i], self.view_camera.camera_pos),
            .instance = i,
        };
    }
    std.mem.sort(SortData, distances[0..], {}, SortData.sort);
    std.debug.print("\n", .{});
    for (0..num_bobbles) |i| {
        const d = distances[i];
        const m = math.matrix.translateVec(d.position);
        self.bobble.sphere.updateInstanceAt(i, .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ @floatFromInt(d.instance), 0, 0, 0 },
        });
    }
    std.debug.print("\n\n", .{});
}

pub fn draw(self: *Blend, dt: f64) void {
    self.view_camera.update(dt);
    {
        rhi.drawHorizon(self.sphere);
    }
    self.cross.draw(dt);
    {
        c.glDisable(c.GL_DEPTH_TEST);
        rhi.drawObject(self.bobble);
        c.glEnable(c.GL_DEPTH_TEST);
    }
}

fn deleteCross(self: *Blend) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *Blend) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

fn renderSphere(self: *Blend) void {
    const prog = rhi.createProgram("sphere");

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("sphere_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);
    const frag = Compiler.runWithBytes(self.allocator, @embedFile("sphere_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..], "sphere");
    const m = math.matrix.uniformScale(1);
    var i_datas: [1]rhi.instanceData = .{.{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 0.007, 0.008, 0.009, 1 },
    }};
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            "sphere",
        ),
    };
    self.sphere = sphere;
}

fn renderBobbles(self: *Blend) void {
    const prog = rhi.createProgram("bobble");

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("blend_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    const frag = Compiler.runWithBytes(self.allocator, @embedFile("blend_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..], "bobble");
    var i_datas: [num_bobbles]rhi.instanceData = undefined;
    for (0..num_bobbles) |i| {
        const m = math.matrix.translateVec(self.bobble_positions[i]);
        i_datas[i] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ @floatFromInt(i), 0, 0, 0 },
        };
    }

    var bobble: object.object = .{ .sphere = object.Sphere.init(prog, i_datas[0..], "bobble") };
    bobble.sphere.mesh.blend = true;
    bobble.sphere.mesh.cull = false;
    self.bobble = bobble;
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
