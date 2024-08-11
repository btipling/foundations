ui_state: PlaneDistanceUI,
allocator: std.mem.Allocator,
grid: *scenery.grid = undefined,
view_camera: *physics.camera.Camera(*PlaneDistance),

const PlaneDistance = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Plane distance",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *PlaneDistance {
    const pd = allocator.create(PlaneDistance) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const cam = physics.camera.Camera(*PlaneDistance).init(allocator, cfg, pd);
    errdefer cam.deinit(allocator);
    const grid = scenery.grid.init(allocator);
    errdefer grid.deinit();
    const ui_state: PlaneDistanceUI = .{};

    pd.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera = cam,
        .grid = grid,
    };
    grid.renderGrid();
    cam.addProgram(grid.program(), scenery.grid.mvp_uniform_name);
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
    self.ui_state.draw();
}

pub fn updateCamera(_: *PlaneDistance) void {}

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
