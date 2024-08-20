ui_state: PlaneDistanceUI,
allocator: std.mem.Allocator,
grid: *scenery.Grid = undefined,
pointer: *scenery.Pointer = undefined,
plane_visualization: object.object = undefined,
plane: math.geometry.Plane = undefined,
sphere: object.object = .{ .norender = .{} },
reflection: ?object.object = null,
parallelepiped: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*PlaneDistance, physics.Integrator(physics.SmoothDeceleration)),

const PlaneDistance = @This();

const default_normal: math.vector.vec3 = .{ 0, -1, 0 };
const default_distance: f32 = 0.0;
const origin_sphere: usize = 0;
const plane_origin_point_sphere: usize = 1;
const plane_cube_point_sphere: usize = 2;

const plane_vertex_shader: []const u8 = @embedFile("plane_vertex.glsl");
const plane_frag_shader: []const u8 = @embedFile("plane_frag.glsl");
const sphere_vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");
const sphere_frag_shader: []const u8 = @embedFile("sphere_frag.glsl");
const cube_vertex_shader: []const u8 = @embedFile("cube_vertex.glsl");
const cube_frag_shader: []const u8 = @embedFile("cube_frag.glsl");
const reflection_vertex_shader: []const u8 = @embedFile("reflection_vertex.glsl");
const reflection_frag_shader: []const u8 = @embedFile("reflection_frag.glsl");

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
    pd.renderSphere();
    pd.renderParallepiped();
    pd.renderReflection();
    pd.renderPlane();
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
        const objects: [2]object.object = .{
            self.sphere,
            self.parallelepiped,
        };
        rhi.drawObjects(objects[0..]);
    }
    if (self.reflection) |r| {
        const objects: [1]object.object = .{r};
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{self.plane_visualization};
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

pub fn updatePlane(self: *PlaneDistance, m: math.matrix) void {
    const p = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(
        @as(math.vector.vec3, self.plane_visualization.parallelepiped.attribute_data[0].position),
    )));
    const q = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(
        @as(math.vector.vec3, self.plane_visualization.parallelepiped.attribute_data[1].position),
    )));
    const r = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(
        @as(math.vector.vec3, self.plane_visualization.parallelepiped.attribute_data[3].position),
    )));
    const u = math.vector.sub(q, p);
    const v = math.vector.sub(r, p);
    const n = math.vector.normalize(math.vector.crossProduct(u, v));
    const d: f32 = -(n[0] * p[0] + n[1] * p[1] + n[2] * p[2]);
    self.plane = math.geometry.Plane.init(n, d);
}

pub fn updatePlaneTransform(self: *PlaneDistance, prog: u32) void {
    var m = math.matrix.identity();
    const scale_matrix = math.matrix.scale(20.0, 0.01, 40.0);
    m = math.matrix.transformMatrix(m, math.matrix.translate(
        self.ui_state.plane_translate[0],
        self.ui_state.plane_translate[1],
        self.ui_state.plane_translate[2],
    ));
    m = math.matrix.transformMatrix(m, math.matrix.translate(10, 0, 20));
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(self.ui_state.plane_rotation[0]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(self.ui_state.plane_rotation[1]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(self.ui_state.plane_rotation[2]));
    m = math.matrix.transformMatrix(m, math.matrix.translate(-10, 0, -20));
    self.updatePlane(m);
    {
        var pm = m;
        pm = math.matrix.transformMatrix(pm, math.matrix.translate(10, 0, 20));
        pm = math.matrix.transformMatrix(pm, math.matrix.rotationZ(std.math.pi / 2.0));
        for (self.pointer.programs()) |p| {
            rhi.setUniformMatrix(p, scenery.Pointer.pointer_uniform_name, pm);
        }
    }
    {
        var sm = math.matrix.identity();
        const po = self.plane.closestPointToOrigin();
        self.ui_state.closest_point_to_origin = po;
        self.ui_state.origin_distance = self.plane.distanceToPoint(.{ 0, 0, 0 });

        sm = math.matrix.transformMatrix(sm, math.matrix.translate(po[0], po[1], po[2]));
        sm = math.matrix.transformMatrix(sm, math.matrix.uniformScale(0.5));
        const i_data: rhi.instanceData = .{
            .t_column0 = sm.columns[0],
            .t_column1 = sm.columns[1],
            .t_column2 = sm.columns[2],
            .t_column3 = sm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        self.sphere.sphere.updateInstanceAt(plane_origin_point_sphere, i_data);
    }
    m = math.matrix.transformMatrix(m, scale_matrix);
    rhi.setUniformMatrix(prog, "f_plane_transform", m);
    self.updateCubePlanePoint();
}

fn updateCubePlanePoint(self: *PlaneDistance) void {
    const p: math.vector.vec4 = .{
        self.ui_state.cube_translate[0],
        self.ui_state.cube_translate[1],
        self.ui_state.cube_translate[2],
        1.0,
    };
    const pc = self.plane.closestPointToPoint(
        math.matrix.transformVector(math.matrix.translate(0.5, 0.5, 0.5), p),
    );
    const pp = math.vector.vec4ToVec3(pc);
    var cm = math.matrix.identity();
    cm = math.matrix.transformMatrix(cm, math.matrix.translate(pp[0], pp[1], pp[2]));
    cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(0.5));
    const i_data: rhi.instanceData = .{
        .t_column0 = cm.columns[0],
        .t_column1 = cm.columns[1],
        .t_column2 = cm.columns[2],
        .t_column3 = cm.columns[3],
        .color = .{ 1, 0, 1, 1 },
    };
    self.sphere.sphere.updateInstanceAt(plane_cube_point_sphere, i_data);
    self.ui_state.cube_point = pc;
    {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(
            self.ui_state.cube_translate[0],
            self.ui_state.cube_translate[1],
            self.ui_state.cube_translate[2],
        ));
        m = math.matrix.inverse(m);
        self.ui_state.cube_distance = self.plane.distanceToPoint(
            math.vector.vec4ToVec3(
                math.matrix.transformVector(m, .{ 0, 0, 0, 1 }),
            ),
        );
    }
    self.updateReflection();
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
    self.updateCubePlanePoint();
}

pub fn deleteReflection(self: *PlaneDistance) void {
    if (self.reflection) |r| {
        var objects: [1]object.object = .{r};
        rhi.deleteObjects(objects[0..]);
    }
}

pub fn updateReflection(self: *PlaneDistance) void {
    self.deleteReflection();
    self.renderReflection();
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
    self.plane_visualization = plane_vis;
    self.updatePlaneTransform(prog);
    self.view_camera.addProgram(prog, "f_mvp");
}

pub fn renderSphere(self: *PlaneDistance) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, sphere_vertex_shader, sphere_frag_shader);
    var i_datas: [3]rhi.instanceData = undefined;
    {
        const m = math.matrix.identity();
        i_datas[origin_sphere] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
    }
    {
        const m = math.matrix.identity();
        i_datas[plane_origin_point_sphere] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
    }
    {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(10, 10, 10));
        i_datas[plane_cube_point_sphere] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
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

pub fn renderReflection(self: *PlaneDistance) void {
    switch (self.parallelepiped) {
        .parallelepiped => {},
        else => return,
    }
    var p0: math.vector.vec4 = undefined;
    var p1: math.vector.vec4 = undefined;
    var p2: math.vector.vec4 = undefined;
    var n0: math.vector.vec3 = undefined;
    var n1: math.vector.vec3 = undefined;
    var n2: math.vector.vec3 = undefined;
    {
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

        p0 = math.vector.vec3ToVec4Point(self.parallelepiped.parallelepiped.attribute_data[0].position);
        p0 = math.matrix.transformVector(m, p0);
        p0 = self.plane.reflectPointAcross(p0);

        p1 = math.vector.vec3ToVec4Point(self.parallelepiped.parallelepiped.attribute_data[1].position);
        p1 = math.matrix.transformVector(m, p1);
        p1 = self.plane.reflectPointAcross(p1);

        p2 = math.vector.vec3ToVec4Point(self.parallelepiped.parallelepiped.attribute_data[3].position);
        p2 = math.matrix.transformVector(m, p2);
        p2 = self.plane.reflectPointAcross(p2);

        n0 = self.parallelepiped.parallelepiped.attribute_data[0].normals;
        n1 = self.parallelepiped.parallelepiped.attribute_data[1].normals;
        n2 = self.parallelepiped.parallelepiped.attribute_data[2].normals;
    }

    var triangle_positions: [3][3]f32 = undefined;
    triangle_positions[0] = math.vector.vec4ToVec3(p0);
    triangle_positions[1] = math.vector.vec4ToVec3(p1);
    triangle_positions[2] = math.vector.vec4ToVec3(p2);
    const triangle0: object.object = .{
        .triangle = object.Triangle.init(
            reflection_vertex_shader,
            reflection_frag_shader,
            triangle_positions,
            .{
                .{ 1, 0, 1, 1 },
                .{ 1, 0, 1, 1 },
                .{ 1, 0, 1, 1 },
            },
            .{ n0, n1, n2 },
        ),
    };
    const prog = triangle0.triangle.mesh.program;
    self.view_camera.addProgram(prog, "f_mvp");
    rhi.setUniformMatrix(prog, "f_reflection_transform", math.matrix.identity());
    self.reflection = triangle0;
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
