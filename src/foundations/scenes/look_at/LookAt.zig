ui_state: LookAtUI,
allocator: std.mem.Allocator,
grid: *scenery.Grid = undefined,
cube: object.object = undefined,
camera: object.object = undefined,
view_camera: *physics.camera.Camera(*LookAt, physics.Integrator(physics.SmoothDeceleration)),
initialized: bool = false,

const LookAt = @This();

const cube_vertex_shader: []const u8 = @embedFile("look_at_cube_vertex.glsl");
const cube_frag_shader: []const u8 = @embedFile("look_at_cube_frag.glsl");
const camera_vertex_shader: []const u8 = @embedFile("look_at_camera_vertex.glsl");
const camera_frag_shader: []const u8 = @embedFile("look_at_camera_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "lookAt",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *LookAt {
    const lkt = allocator.create(LookAt) catch @panic("OOM");
    errdefer allocator.destroy(lkt);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*LookAt, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        cfg,
        lkt,
        integrator,
        .{ 1, 3.5, 1 },
        null,
    );
    errdefer cam.deinit(allocator);
    const grid = scenery.Grid.init(allocator);
    errdefer grid.deinit();
    const ui_state: LookAtUI = .{};

    lkt.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera = cam,
        .grid = grid,
    };
    lkt.renderCube();
    lkt.renderCamera();
    cam.addProgram(grid.program(), scenery.Grid.mvp_uniform_name);
    cam.can_toggle_view = true;
    lkt.initialized = true;
    return lkt;
}

pub fn deinit(self: *LookAt, allocator: std.mem.Allocator) void {
    self.deleteCamera();
    self.deleteCube();
    self.grid.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *LookAt, dt: f64) void {
    self.view_camera.update(dt);
    self.grid.draw(dt);
    {
        const objects: [1]object.object = .{self.cube};
        rhi.drawObjects(objects[0..]);
    }
    if (!self.view_camera.use_camera) {
        const objects: [1]object.object = .{self.camera};
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

pub fn deleteCube(self: *LookAt) void {
    var objects: [1]object.object = .{self.cube};
    rhi.deleteObjects(objects[0..]);
    self.cube = undefined;
}

pub fn deleteCamera(self: *LookAt) void {
    var objects: [1]object.object = .{self.camera};
    rhi.deleteObjects(objects[0..]);
    self.camera = undefined;
}

pub fn updateCamera(self: *LookAt) void {
    if (!self.initialized) return;
    const m = math.matrix.transformMatrix(math.matrix.identity(), self.view_camera.camera_matrix);
    rhi.setUniformMatrix(self.camera.cube.mesh.program, "f_camera_transform", m);
}

pub fn renderCube(self: *LookAt) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, cube_vertex_shader, cube_frag_shader);
    const cube: object.object = .{
        .cube = object.Cube.init(
            program,
            object.Cube.default_positions,
            .{ 1, 0, 1, 1 },
        ),
    };
    var m = math.matrix.transformMatrix(math.matrix.identity(), math.matrix.translate(0.0, 10.5, 0.0));
    m = math.matrix.transformMatrix(
        m,
        math.matrix.translate(
            self.ui_state.cube_translate[0],
            self.ui_state.cube_translate[1],
            self.ui_state.cube_translate[2],
        ),
    );
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(self.ui_state.cube_rot[0]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(self.ui_state.cube_rot[1]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(self.ui_state.cube_rot[2]));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(1));
    rhi.setUniformMatrix(program, "f_transform", m);
    self.view_camera.addProgram(program, "f_mvp");
    self.cube = cube;
}

pub fn renderCamera(self: *LookAt) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, camera_vertex_shader, camera_frag_shader);
    const camera: object.object = .{
        .cube = object.Cube.init(
            program,
            object.Cube.default_positions,
            .{ 1, 0, 1, 1 },
        ),
    };
    const m = math.matrix.transformMatrix(math.matrix.identity(), self.view_camera.camera_matrix);
    rhi.setUniformMatrix(program, "f_camera_transform", m);
    self.view_camera.addProgram(program, "f_mvp");
    self.camera = camera;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const LookAtUI = @import("LookAtUI.zig");
const object = @import("../../object/object.zig");
const config = @import("../../config/config.zig");
const physics = @import("../../physics/physics.zig");
const scenery = @import("../../scenery/scenery.zig");
