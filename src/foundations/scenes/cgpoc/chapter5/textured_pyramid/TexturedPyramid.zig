ui_state: TexturedPyramidUI,
allocator: std.mem.Allocator,
bg: object.object = .{ .norender = .{} },
pyramid: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*TexturedPyramid, physics.Integrator(physics.SmoothDeceleration)),
brick_texture: ?rhi.Texture,
ice_texture: ?rhi.Texture,

const TexturedPyramid = @This();

const vertex_shader: []const u8 = @embedFile("../../../../shaders/i_obj_vert.glsl");
const frag_shader: []const u8 = @embedFile("../../../../shaders/i_obj_frag.glsl");
const vertex_static_shader: []const u8 = @embedFile("../../../../shaders/i_obj_static_vert.glsl");
const frag_color_shader: []const u8 = @embedFile("../../../../shaders/i_obj_color_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Textured Pyramid",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *TexturedPyramid {
    const pd = allocator.create(TexturedPyramid) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*TexturedPyramid, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 3, -15, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    var brick_texture: ?rhi.Texture = null;
    if (ctx.textures_loader.loadAsset("cgpoc\\luna\\brick1.jpg") catch null) |img| {
        brick_texture = rhi.Texture.init(img);
    } else {
        std.debug.print("no brick image\n", .{});
    }

    var ice_texture: ?rhi.Texture = null;
    if (ctx.textures_loader.loadAsset("cgpoc\\luna\\ice.jpg") catch null) |img| {
        ice_texture = rhi.Texture.init(img);
    } else {
        std.debug.print("no ice image\n", .{});
    }

    const ui_state: TexturedPyramidUI = .{};
    pd.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera = cam,
        .brick_texture = brick_texture,
        .ice_texture = ice_texture,
    };
    pd.renderBG();
    pd.renderParallepiped();
    return pd;
}

pub fn deinit(self: *TexturedPyramid, allocator: std.mem.Allocator) void {
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *TexturedPyramid, dt: f64) void {
    self.view_camera.update(dt);
    switch (self.ui_state.active_texture) {
        0 => if (self.brick_texture) |bt| {
            bt.bind();
        },
        else => if (self.ice_texture) |bt| {
            bt.bind();
        },
    }
    {
        const objects: [1]object.object = .{
            self.bg,
        };
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{
            self.pyramid,
        };
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

pub fn updateCamera(_: *TexturedPyramid) void {}

pub fn renderParallepiped(self: *TexturedPyramid) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, vertex_shader, frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, -1, -1));
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
    const pyramid: object.object = .{
        .pyramid = object.Pyramid.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.view_camera.addProgram(prog, "f_mvp");
    self.pyramid = pyramid;
}

pub fn renderBG(self: *TexturedPyramid) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, vertex_static_shader, frag_color_shader);
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

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const scenes = @import("../../../scenes.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");
const TexturedPyramidUI = @import("TexturedPyramidUI.zig");
