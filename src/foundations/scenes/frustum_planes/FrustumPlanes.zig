ui_state: FrustumPlanesUI,
allocator: std.mem.Allocator,
grid: *scenery.Grid = undefined,
sphere: object.object = .{ .norender = .{} },
parallelepiped: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*FrustumPlanes, physics.Integrator(physics.SmoothDeceleration)),

const voxel_dimension: usize = 30;

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
    const cam = physics.camera.Camera(*FrustumPlanes, physics.Integrator(physics.SmoothDeceleration)).init(
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
    const ui_state: FrustumPlanesUI = .{};

    pd.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera = cam,
        .grid = grid,
    };
    pd.renderSphere();
    pd.renderParallepiped();
    cam.addProgram(grid.program(), scenery.Grid.mvp_uniform_name);
    return pd;
}

pub fn deinit(self: *FrustumPlanes, allocator: std.mem.Allocator) void {
    self.grid.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *FrustumPlanes, dt: f64) void {
    self.view_camera.update(dt);
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

pub fn updateCamera(_: *FrustumPlanes) void {}

fn genObject(
    _: FrustumPlanes,
    i_datas: *[voxel_dimension * voxel_dimension * voxel_dimension]rhi.instanceData,
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
    var i_datas: [voxel_dimension * voxel_dimension * voxel_dimension]rhi.instanceData = undefined;
    const i = self.genObject(&i_datas, 3.0, 1.5, 2.0, 0.5, 1, 6);
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..i],
            false,
        ),
    };
    self.view_camera.addProgram(prog, "f_mvp");
    self.sphere = sphere;
}

pub fn updateParallepipedTransform(_: *FrustumPlanes, prog: u32) void {
    const m = math.matrix.identity();
    rhi.setUniformMatrix(prog, "f_cube_transform", m);
}

pub fn renderParallepiped(self: *FrustumPlanes) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, voxel_vertex_shader, voxel_frag_shader);
    var i_datas: [voxel_dimension * voxel_dimension * voxel_dimension]rhi.instanceData = undefined;
    const i = self.genObject(&i_datas, 2.0, 2.0, 2.0, 0.45, 1, 4);
    const parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..i],
            false,
        ),
    };
    self.updateParallepipedTransform(prog);
    self.view_camera.addProgram(prog, "f_mvp");
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
