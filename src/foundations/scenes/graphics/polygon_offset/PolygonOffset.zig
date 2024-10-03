allocator: std.mem.Allocator,
ui_state: ShadowsUI,
bg: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*PolygonOffset, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,

// Objects
object_1: object.object = .{ .norender = .{} },
object_1_m: rhi.Uniform = undefined,

object_2: object.object = .{ .norender = .{} },
object_2_m: rhi.Uniform = undefined,

const PolygonOffset = @This();

const vertex_shader: []const u8 = @embedFile("ca_vertex.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .graphics,
        .name = "PolygonOffset",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *PolygonOffset {
    const pd = allocator.create(PolygonOffset) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*PolygonOffset, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 1.5, -16, 3 },
        -(std.math.pi / 8.0),
    );
    errdefer cam.deinit(allocator);

    const sd: rhi.Buffer.buffer_data = .{ .chapter8_shadows = .{} };
    var scene_data_buffer = rhi.Buffer.init(sd);
    errdefer scene_data_buffer.deinit();

    const ui_state: ShadowsUI = .{};
    pd.* = .{
        .allocator = allocator,
        .ui_state = ui_state,
        .view_camera = cam,
        .ctx = ctx,
    };
    pd.renderObject_1();
    errdefer pd.deleteObject_1();

    pd.renderObject_2();
    errdefer pd.deleteObject_2();

    return pd;
}

pub fn deinit(self: *PolygonOffset, allocator: std.mem.Allocator) void {
    // objects
    self.deleteObject_1();
    self.deleteObject_2();
    // camera
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    // self
    allocator.destroy(self);
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

pub fn draw(self: *PolygonOffset, dt: f64) void {
    if (self.ui_state.object_1.transform_updated) {
        const m = getObjectMatrix(self.ui_state.object_1);
        self.object_2_m.setUniformMatrix(m);
        self.ui_state.object_1.transform_updated = false;
    }
    if (self.ui_state.object_2.transform_updated) {
        const m = getObjectMatrix(self.ui_state.object_2);
        self.object_2_m.setUniformMatrix(m);
        self.ui_state.object_2.transform_updated = false;
    }
    if (self.ui_state.object_1.updated) {
        self.deleteObject_1();
        self.renderObject_1();
        self.ui_state.object_1.updated = false;
    }
    if (self.ui_state.object_2.updated) {
        self.deleteObject_2();
        self.renderObject_2();
        self.ui_state.object_2.updated = false;
    }
    self.view_camera.update(dt);
    {
        const objects: [2]object.object = .{
            self.object_1,
            self.object_2,
        };
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

pub fn updateCamera(_: *PolygonOffset) void {}

pub fn deleteObject_1(self: *PolygonOffset) void {
    self.deleteObject(self.object_1);
}

pub fn deleteObject_2(self: *PolygonOffset) void {
    self.deleteObject(self.object_2);
}

pub fn deleteObject(_: *PolygonOffset, obj: object.object) void {
    const objects: [1]object.object = .{
        obj,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderObject(self: *PolygonOffset, obj_setting: ShadowsUI.objectSetting, prog: u32) object.object {
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .normals,
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

    var render_object: object.object = s: switch (obj_setting.model) {
        0 => {
            var torus: object.object = .{
                .torus = object.Torus.init(
                    prog,
                    i_datas[0..],
                    false,
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
                    true,
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
                    false,
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
                    false,
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
                    false,
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
            break :s shuttle_model.toObject(prog, i_datas[0..]);
        },
        7 => {
            var dolphin_model: *assets.Obj = undefined;
            if (self.ctx.obj_loader.loadAsset("cgpoc\\Dolphin\\dolphinLowPoly.obj") catch null) |o| {
                dolphin_model = o;
            } else {
                break :s .{ .norender = .{} };
            }
            break :s dolphin_model.toObject(prog, i_datas[0..]);
        },
        8 => {
            var dolphin_model: *assets.Obj = undefined;
            if (self.ctx.obj_loader.loadAsset("cgpoc\\Dolphin\\dolphinHighPoly.obj") catch null) |o| {
                dolphin_model = o;
            } else {
                break :s .{ .norender = .{} };
            }
            break :s dolphin_model.toObject(prog, i_datas[0..]);
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

    var buf: [50]u8 = undefined;
    for (0..self.shadowmaps.len) |i| {
        var t = self.shadowmaps[i];
        const b = std.fmt.bufPrint(&buf, "f_shadow_texture{d};\n", .{i}) catch @panic("failed create uniform");
        t.addUniform(prog, b);
        self.shadowmaps[i] = t;
    }
    return render_object;
}

pub fn renderObject_1(self: *PolygonOffset) void {
    const prog = rhi.createProgram();
    self.object_1 = self.renderObject(self.ui_state.object_1, prog);

    var om: rhi.Uniform = .init(prog, "f_object_m");
    self.obj_1_m = getObjectMatrix(self.ui_state.object_1);
    om.setUniformMatrix(self.obj_1_m);
    self.object_1_m = om;
}

pub fn renderObject_2(self: *PolygonOffset) void {
    const prog = rhi.createProgram();
    self.object_2 = self.renderObject(self.ui_state.object_2, prog);

    var om: rhi.Uniform = .init(prog, "f_object_m");
    self.obj_2_m = getObjectMatrix(self.ui_state.object_2);
    om.setUniformMatrix(self.obj_2_m);
    self.object_2_m = om;
}

const std = @import("std");
const c = @import("../../../c.zig").c;
const ui = @import("../../../ui/ui.zig");
const rhi = @import("../../../rhi/rhi.zig");
const math = @import("../../../math/math.zig");
const object = @import("../../../object/object.zig");
const scenes = @import("../../scenes.zig");
const physics = @import("../../../physics/physics.zig");
const scenery = @import("../../../scenery/scenery.zig");
const ShadowsUI = @import("PolygonOffsetUI.zig");
const assets = @import("../../../assets/assets.zig");
