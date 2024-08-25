ui_state: FrustumPlanesUI,
allocator: std.mem.Allocator,
grid: *scenery.Grid = undefined,
sphere: object.object = .{ .norender = .{} },
parallelepiped: object.object = .{ .norender = .{} },
view_camera_0: *physics.camera.Camera(*FrustumPlanes, physics.Integrator(physics.SmoothDeceleration)),
view_camera_1: *physics.camera.Camera(*FrustumPlanes, physics.Integrator(physics.SmoothDeceleration)),
voxel_map: [voxel_max]math.vector.vec3 = undefined,
voxel_transforms: [voxel_max]math.matrix = undefined,
voxel_visible: [voxel_max]u8 = undefined,
num_voxels: usize = 0,
sphere_map: [voxel_max]math.vector.vec3 = undefined,
sphere_visible: [voxel_max]u8 = undefined,
sphere_transforms: [voxel_max]math.matrix = undefined,
num_spheres: usize = 0,

const voxel_dimension: usize = 30;
const voxel_max = voxel_dimension * voxel_dimension * voxel_dimension;
const invisible = math.matrix.translate(-500, -500, -500);

const FrustumPlanes = @This();

const sphere_vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");
const sphere_frag_shader: []const u8 = @embedFile("sphere_frag.glsl");
const voxel_vertex_shader: []const u8 = @embedFile("voxel_vertex.glsl");
const voxel_frag_shader: []const u8 = @embedFile("voxel_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Frustum planes",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *FrustumPlanes {
    const pd = allocator.create(FrustumPlanes) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam1 = physics.camera.Camera(*FrustumPlanes, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        cfg,
        pd,
        integrator,
        .{ 15, 30, -30 },
        std.math.pi * 0.75,
    );
    var cam2 = physics.camera.Camera(*FrustumPlanes, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        cfg,
        pd,
        integrator,
        .{ 15, -30, 30 },
        std.math.pi * -0.25,
    );
    cam2.emit_matrix = false;
    cam2.input_inactive = true;
    errdefer cam1.deinit(allocator);
    const grid = scenery.Grid.init(allocator);
    errdefer grid.deinit();
    const ui_state: FrustumPlanesUI = .{};

    pd.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera_0 = cam1,
        .view_camera_1 = cam2,
        .grid = grid,
        .voxel_visible = std.mem.zeroes([voxel_max]u8),
        .sphere_visible = std.mem.zeroes([voxel_max]u8),
    };
    pd.renderSphere();
    pd.renderParallepiped();
    cam1.addProgram(grid.program(), scenery.Grid.mvp_uniform_name);
    cam2.addProgram(grid.program(), scenery.Grid.mvp_uniform_name);
    return pd;
}

pub fn deinit(self: *FrustumPlanes, allocator: std.mem.Allocator) void {
    self.grid.deinit();
    self.view_camera_0.deinit(allocator);
    self.view_camera_0 = undefined;
    self.view_camera_1.deinit(allocator);
    self.view_camera_1 = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *FrustumPlanes, dt: f64) void {
    self.view_camera_0.setViewActivation(self.ui_state.active_view_camera == 0);
    self.view_camera_1.setViewActivation(self.ui_state.active_view_camera == 1);
    self.view_camera_0.setInputActivation(self.ui_state.active_input_camera == 0);
    self.view_camera_1.setInputActivation(self.ui_state.active_input_camera == 1);
    self.view_camera_0.update(dt);
    self.view_camera_1.update(dt);
    self.grid.draw(dt);
    {
        const objects: [2]object.object = .{
            self.sphere,
            self.parallelepiped,
        };
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

fn pointVisible(
    p: math.vector.vec3,
    left_plane: math.geometry.Plane,
    right_plane: math.geometry.Plane,
    bot_plane: math.geometry.Plane,
    top_plane: math.geometry.Plane,
) bool {
    if (left_plane.distanceToPoint(p) < 0) return false;
    if (right_plane.distanceToPoint(p) < 0) return false;
    if (bot_plane.distanceToPoint(p) < 0) return false;
    if (top_plane.distanceToPoint(p) < 0) return false;
    return true;
}

pub fn updateCamera(self: *FrustumPlanes) void {
    const cam = self.view_camera_0;
    const cm = cam.camera_matrix;

    const nl: math.vector.vec3 = math.vector.add(
        math.vector.mul(cam.aspect_ratio_s, math.vector.vec4ToVec3(cm.columns[1])),
        math.vector.mul(cam.perspective_plane_distance_g, math.vector.vec4ToVec3(cm.columns[2])),
    );
    const dl = math.vector.dotProduct(nl, math.vector.vec4ToVec3(cm.columns[3]));
    const left_plane = math.geometry.Plane.init(nl, dl);

    const nr: math.vector.vec3 = math.vector.add(
        math.vector.mul(cam.aspect_ratio_s, math.vector.vec4ToVec3(cm.columns[1])),
        math.vector.mul(-cam.perspective_plane_distance_g, math.vector.vec4ToVec3(cm.columns[2])),
    );
    const dr = math.vector.dotProduct(nr, math.vector.vec4ToVec3(cm.columns[3]));
    const right_plane = math.geometry.Plane.init(nr, dr);

    const nb: math.vector.vec3 = math.vector.add(
        math.vector.mul(-cam.perspective_plane_distance_g, math.vector.vec4ToVec3(cm.columns[0])),
        math.vector.vec4ToVec3(cm.columns[1]),
    );
    const db = math.vector.dotProduct(nb, math.vector.vec4ToVec3(cm.columns[3]));
    const bot_plane = math.geometry.Plane.init(nb, db);

    const nt: math.vector.vec3 = math.vector.add(
        math.vector.mul(cam.perspective_plane_distance_g, math.vector.vec4ToVec3(cm.columns[0])),
        math.vector.vec4ToVec3(cm.columns[1]),
    );
    const dt = math.vector.dotProduct(nt, math.vector.vec4ToVec3(cm.columns[3]));
    const top_plane = math.geometry.Plane.init(nt, dt);

    for (0..self.num_voxels) |i| {
        const vox = self.voxel_map[i];
        const visible = pointVisible(vox, left_plane, right_plane, bot_plane, top_plane);
        if (!visible) {
            const m = invisible;
            const i_data: rhi.instanceData = .{
                .t_column0 = m.columns[0],
                .t_column1 = m.columns[1],
                .t_column2 = m.columns[2],
                .t_column3 = m.columns[3],
                .color = .{ 1, 0, 1, 1 },
            };
            self.parallelepiped.parallelepiped.updateInstanceAt(i, i_data);
            self.voxel_visible[i] = 0;
        } else {
            const m = self.voxel_transforms[i];
            const i_data: rhi.instanceData = .{
                .t_column0 = m.columns[0],
                .t_column1 = m.columns[1],
                .t_column2 = m.columns[2],
                .t_column3 = m.columns[3],
                .color = .{ 1, 0, 1, 1 },
            };
            self.parallelepiped.parallelepiped.updateInstanceAt(i, i_data);
            self.voxel_visible[i] = 1;
        }
    }
    for (0..self.num_spheres) |i| {
        const sp = self.sphere_map[i];
        const visible = pointVisible(sp, left_plane, right_plane, bot_plane, top_plane);
        if (!visible) {
            const m = invisible;
            const i_data: rhi.instanceData = .{
                .t_column0 = m.columns[0],
                .t_column1 = m.columns[1],
                .t_column2 = m.columns[2],
                .t_column3 = m.columns[3],
                .color = .{ 1, 0, 1, 1 },
            };
            self.sphere.sphere.updateInstanceAt(i, i_data);
            self.sphere_visible[i] = 0;
        } else {
            const m = self.sphere_transforms[i];
            const i_data: rhi.instanceData = .{
                .t_column0 = m.columns[0],
                .t_column1 = m.columns[1],
                .t_column2 = m.columns[2],
                .t_column3 = m.columns[3],
                .color = .{ 1, 0, 1, 1 },
            };
            self.sphere.sphere.updateInstanceAt(i, i_data);
            self.sphere_visible[i] = 1;
        }
    }
}

fn genObject(
    map: *[voxel_max]math.vector.vec3,
    transforms: *[voxel_max]math.matrix,
    i_datas: *[voxel_max]rhi.instanceData,
    offset_horizontal: f32,
    offset_vertical: f32,
    acunarity: f32,
    gain: f32,
    offset: f32,
    octaves: c_int,
) usize {
    var i: usize = 0;
    const vdf: f32 = @floatFromInt(voxel_dimension);
    for (0..voxel_dimension) |z| {
        const fz: f32 = @floatFromInt(z);
        for (0..voxel_dimension) |y| {
            const fy: f32 = @floatFromInt(y);
            const result = c.stb_perlin_ridge_noise3(fz * 0.01, fy * 0.1, fz * 0.1, acunarity, gain, offset, octaves);
            const x: usize = @intFromFloat(@floor(result * 10));
            for (0..x) |xi| {
                const fx: f32 = @floatFromInt(xi);
                var m = math.matrix.identity();
                m = math.matrix.transformMatrix(m, math.matrix.translate(
                    fx * offset_vertical,
                    (fy - vdf / 2.0) * offset_horizontal,
                    (fz - vdf / 2.0) * offset_horizontal,
                ));
                i_datas[i] = .{
                    .t_column0 = m.columns[0],
                    .t_column1 = m.columns[1],
                    .t_column2 = m.columns[2],
                    .t_column3 = m.columns[3],
                    .color = .{ 1, 0, 1, 1 },
                };
                map[i] = math.vector.vec4ToVec3(math.matrix.transformVector(m, .{ 0, 0, 0, 1 }));
                transforms[i] = m;
                i += 1;
                if (i == i_datas.len) return i;
            }
        }
    }
    return i;
}

pub fn renderSphere(self: *FrustumPlanes) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, sphere_vertex_shader, sphere_frag_shader);
    var i_datas: [voxel_max]rhi.instanceData = undefined;
    const i = genObject(&self.sphere_map, &self.sphere_transforms, &i_datas, 3.0, 1.5, 2.0, 0.5, 1, 6);
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..i],
            false,
        ),
    };
    self.view_camera_0.addProgram(prog, "f_mvp");
    self.view_camera_1.addProgram(prog, "f_mvp");
    self.num_spheres = i;
    self.sphere = sphere;
}

pub fn updateParallepipedTransform(_: *FrustumPlanes, prog: u32) void {
    const m = math.matrix.identity();
    rhi.setUniformMatrix(prog, "f_cube_transform", m);
}

pub fn renderParallepiped(self: *FrustumPlanes) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, voxel_vertex_shader, voxel_frag_shader);
    var i_datas: [voxel_max]rhi.instanceData = undefined;
    const i = genObject(&self.voxel_map, &self.voxel_transforms, &i_datas, 2.0, 2.0, 2.0, 0.45, 1, 4);
    const parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..i],
            false,
        ),
    };
    self.updateParallepipedTransform(prog);
    self.view_camera_0.addProgram(prog, "f_mvp");
    self.view_camera_1.addProgram(prog, "f_mvp");
    self.num_voxels = i;
    self.parallelepiped = parallelepiped;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const FrustumPlanesUI = @import("FrustumPlanesUI.zig");
const object = @import("../../object/object.zig");
const config = @import("../../config/config.zig");
const physics = @import("../../physics/physics.zig");
const scenery = @import("../../scenery/scenery.zig");
