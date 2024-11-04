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

const vertex_shader: []const u8 = @embedFile("po_vertex.glsl");

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
        .{ 1.5, -1, 3 },
        (std.math.pi),
    );
    errdefer cam.deinit(allocator);

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
        self.object_1_m.setUniformMatrix(m);
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

    c.glEnable(c.GL_POLYGON_OFFSET_FILL);
    {
        c.glPolygonOffset(
            @floatCast(self.ui_state.object_1.polygon_factor),
            @floatCast(self.ui_state.object_1.polygon_unit),
        );
        const objects: [1]object.object = .{
            self.object_1,
        };
        rhi.drawObjects(objects[0..]);
    }
    {
        c.glPolygonOffset(
            @floatCast(self.ui_state.object_2.polygon_factor),
            @floatCast(self.ui_state.object_2.polygon_unit),
        );
        const objects: [1]object.object = .{
            self.object_2,
        };
        rhi.drawObjects(objects[0..]);
    }
    c.glDisable(c.GL_POLYGON_OFFSET_FILL);
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
            .fragment_shader = .normal,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..], "object");
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

    const render_object: object.object = s: switch (obj_setting.model) {
        0 => {
            var torus: object.object = .{
                .torus = object.Torus.init(
                    prog,
                    i_datas[0..],
                    "torus",
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
                    "parallelepiped",
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
                    "sphere",
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
                    "cone",
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
                    "cylinder",
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
                    "pyramid",
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
            break :s shuttle_model.toObject(prog, i_datas[0..], "shuttle");
        },
        7 => {
            var dolphin_model: *assets.Obj = undefined;
            if (self.ctx.obj_loader.loadAsset("cgpoc\\Dolphin\\dolphinLowPoly.obj") catch null) |o| {
                dolphin_model = o;
            } else {
                break :s .{ .norender = .{} };
            }
            break :s dolphin_model.toObject(prog, i_datas[0..], "lowdolphin");
        },
        8 => {
            var dolphin_model: *assets.Obj = undefined;
            if (self.ctx.obj_loader.loadAsset("cgpoc\\Dolphin\\dolphinHighPoly.obj") catch null) |o| {
                dolphin_model = o;
            } else {
                break :s .{ .norender = .{} };
            }
            break :s dolphin_model.toObject(prog, i_datas[0..], "highdolphin");
        },
        else => .{ .norender = .{} },
    };

    return render_object;
}

pub fn renderObject_1(self: *PolygonOffset) void {
    const prog = rhi.createProgram("object1");
    self.object_1 = self.renderObject(self.ui_state.object_1, prog);

    var om: rhi.Uniform = rhi.Uniform.init(prog, "f_object_m") catch @panic("uniform failed");
    const m = getObjectMatrix(self.ui_state.object_1);
    om.setUniformMatrix(m);
    self.object_1_m = om;
}

pub fn renderObject_2(self: *PolygonOffset) void {
    const prog = rhi.createProgram("object2");
    self.object_2 = self.renderObject(self.ui_state.object_2, prog);

    var om: rhi.Uniform = rhi.Uniform.init(prog, "f_object_m") catch @panic("uniform failed");
    const m = getObjectMatrix(self.ui_state.object_2);
    om.setUniformMatrix(m);
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
