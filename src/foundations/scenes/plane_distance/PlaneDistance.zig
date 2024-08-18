ui_state: PlaneDistanceUI,
allocator: std.mem.Allocator,
grid: *scenery.Grid = undefined,
pointer: *scenery.Pointer = undefined,
plane_visualization: object.object = undefined,
plane: math.geometry.Plane = undefined,
sphere: object.object = undefined,
parallelepiped: object.object = undefined,
view_camera: *physics.camera.Camera(*PlaneDistance, physics.Integrator(physics.SmoothDeceleration)),

const PlaneDistance = @This();

const default_normal: math.vector.vec3 = .{ 0, -1, 0 }; // points out of the screen.
const default_distance: f32 = 0.0; // always intersects with origin for now

const plane_vertex_shader: []const u8 = @embedFile("plane_vertex.glsl");
const plane_frag_shader: []const u8 = @embedFile("plane_frag.glsl");
const sphere_vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");
const sphere_frag_shader: []const u8 = @embedFile("sphere_frag.glsl");
const cube_vertex_shader: []const u8 = @embedFile("cube_vertex.glsl");
const cube_frag_shader: []const u8 = @embedFile("cube_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Plane distance",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *PlaneDistance {
    const pd = allocator.create(PlaneDistance) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*PlaneDistance, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        cfg,
        pd,
        integrator,
        .{ 5, 30, -30 },
        std.math.pi * 0.75,
    );
    errdefer cam.deinit(allocator);
    const grid = scenery.Grid.init(allocator);
    errdefer grid.deinit();
    const pointer = scenery.Pointer.init(allocator);
    errdefer pointer.deinit();
    const ui_state: PlaneDistanceUI = .{};

    pd.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera = cam,
        .grid = grid,
        .pointer = pointer,
        .plane = math.geometry.Plane.init(default_normal, default_distance),
    };
    pd.renderPlane();
    pd.renderSphere();
    pd.renderParallepiped();
    cam.addProgram(grid.program(), scenery.Grid.mvp_uniform_name);
    {
        const progs = pointer.programs();
        for (progs) |p| {
            cam.addProgram(p, scenery.Pointer.mvp_uniform_name);
        }
    }
    return pd;
}

pub fn deinit(self: *PlaneDistance, allocator: std.mem.Allocator) void {
    self.grid.deinit();
    self.pointer.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *PlaneDistance, dt: f64) void {
    if (self.ui_state.plane_updated) {
        self.updatePlaneTransform(self.plane_visualization.parallelepiped.mesh.program);
        self.ui_state.plane_updated = false;
    }
    if (self.ui_state.cube_updated) {
        self.updateCubeTransform(self.parallelepiped.parallelepiped.mesh.program);
        self.ui_state.cube_updated = false;
    }
    self.view_camera.update(dt);
    self.grid.draw(dt);
    self.pointer.draw(dt);
    {
        const objects: [2]object.object = .{ self.sphere, self.parallelepiped };
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{self.plane_visualization};
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

pub fn updatePlane(self: *PlaneDistance, m: math.matrix) void {
    const p = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(object.Parallelepiped.pp.v1)));
    const q = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(object.Parallelepiped.pp.v0)));
    const r = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(object.Parallelepiped.pp.v2)));
    const u = math.vector.sub(q, p);
    const v = math.vector.sub(r, p);
    const n = math.vector.normalize(math.vector.crossProduct(u, v));
    const d: f32 = math.vector.dotProduct(math.vector.negate(n), q);
    self.plane = math.geometry.Plane.init(n, d);
}

pub fn updatePlaneTransform(self: *PlaneDistance, prog: u32) void {
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(
        self.ui_state.plane_translate[0],
        self.ui_state.plane_translate[1],
        self.ui_state.plane_translate[2],
    ));
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(self.ui_state.plane_rotation[0]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(self.ui_state.plane_rotation[1]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(self.ui_state.plane_rotation[2]));
    self.updatePlane(m);
    {
        var pm = m;
        pm = math.matrix.transformMatrix(pm, math.matrix.translate(10, 0, 20));
        pm = math.matrix.transformMatrix(pm, math.matrix.rotationZ(std.math.pi / 2.0));
        for (self.pointer.programs()) |p| {
            rhi.setUniformMatrix(p, scenery.Pointer.pointer_uniform_name, pm);
        }
    }
    m = math.matrix.transformMatrix(m, math.matrix.scale(20.0, 0.01, 40.0));
    rhi.setUniformMatrix(prog, "f_plane_transform", m);
}

pub fn updateCubeTransform(self: *PlaneDistance, prog: u32) void {
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(
        self.ui_state.cube_translate[0],
        self.ui_state.cube_translate[1],
        self.ui_state.cube_translate[2],
    ));
    m = math.matrix.transformMatrix(m, math.matrix.translate(0.5, 0.5, 0.5));
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(self.ui_state.cube_rotation[0]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(self.ui_state.cube_rotation[1]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(self.ui_state.cube_rotation[2]));
    m = math.matrix.transformMatrix(m, math.matrix.translate(-0.5, -0.5, -0.5));
    rhi.setUniformMatrix(prog, "f_cube_transform", m);
}

pub fn updateCamera(_: *PlaneDistance) void {}

pub fn renderPlane(self: *PlaneDistance) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, plane_vertex_shader, plane_frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    {
        const m = math.matrix.identity();
        i_datas[0] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 0, 0.1 },
        };
    }
    const plane_vis: object.object = .{
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..],
            true,
        ),
    };
    self.updatePlaneTransform(prog);
    self.view_camera.addProgram(prog, "f_mvp");
    self.plane_visualization = plane_vis;
}

pub fn renderSphere(self: *PlaneDistance) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, sphere_vertex_shader, sphere_frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    {
        const m = math.matrix.identity();
        i_datas[0] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 0, 0.1 },
        };
    }
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.view_camera.addProgram(prog, "f_mvp");
    self.sphere = sphere;
}

pub fn renderParallepiped(self: *PlaneDistance) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, cube_vertex_shader, cube_frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    {
        const m = math.matrix.identity();
        i_datas[0] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 0, 0.1 },
        };
    }
    const parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.updateCubeTransform(prog);
    self.view_camera.addProgram(prog, "f_mvp");
    self.parallelepiped = parallelepiped;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const PlaneDistanceUI = @import("PlaneDistanceUI.zig");
const object = @import("../../object/object.zig");
const config = @import("../../config/config.zig");
const physics = @import("../../physics/physics.zig");
const scenery = @import("../../scenery/scenery.zig");
