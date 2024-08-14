ui_state: PlaneDistanceUI,
allocator: std.mem.Allocator,
grid: *scenery.Grid = undefined,
plane: object.object = undefined,
view_camera: *physics.camera.Camera(*PlaneDistance, physics.Integrator(physics.SmoothDeceleration)),

const PlaneDistance = @This();

const grid_vertex_shader: []const u8 = @embedFile("plane_vertex.glsl");
const grid_frag_shader: []const u8 = @embedFile("plane_frag.glsl");

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
        .{ 0, 0, 0 },
    );
    errdefer cam.deinit(allocator);
    const grid = scenery.Grid.init(allocator);
    errdefer grid.deinit();
    const ui_state: PlaneDistanceUI = .{};

    pd.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera = cam,
        .grid = grid,
    };
    grid.renderGrid();
    pd.renderPlane();
    cam.addProgram(grid.program(), scenery.Grid.mvp_uniform_name);
    return pd;
}

pub fn deinit(self: *PlaneDistance, allocator: std.mem.Allocator) void {
    self.grid.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *PlaneDistance, dt: f64) void {
    self.view_camera.update(dt);
    self.grid.draw(dt);
    const objects: [1]object.object = .{self.plane};
    rhi.drawObjects(objects[0..]);
    self.ui_state.draw();
}

pub fn updateCamera(_: *PlaneDistance) void {}

pub fn renderPlane(self: *PlaneDistance) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, grid_vertex_shader, grid_frag_shader);
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
    const plane: object.object = .{
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..],
            true,
        ),
    };
    {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(-100, 300, -200));
        m = math.matrix.transformMatrix(m, math.matrix.scale(200.0, 0.01, 400.0));
        rhi.setUniformMatrix(prog, "f_plane_transform", m);
    }
    self.view_camera.addProgram(prog, "f_mvp");
    self.plane = plane;
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
