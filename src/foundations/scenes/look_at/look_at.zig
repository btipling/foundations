ui_state: look_at_ui,
allocator: std.mem.Allocator,
grid: object.object = undefined,
cube: object.object = undefined,
camera: object.object = undefined,
view_camera: *physics.camera.Camera(*LookAt),

const LookAt = @This();

const num_grid_lines: usize = 500;
const grid_len: usize = 2;
const grid_increments: usize = 25;

const grid_vertex_shader: []const u8 = @embedFile("look_at_grid_vertex.glsl");
const grid_frag_shader: []const u8 = @embedFile("look_at_grid_frag.glsl");
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
    const cam = physics.camera.Camera(*LookAt).init(allocator, cfg, lkt);
    errdefer cam.deinit(allocator);
    const ui_state: look_at_ui = .{};

    lkt.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera = cam,
    };
    lkt.renderGrid();
    lkt.renderCube();
    lkt.renderCamera();
    return lkt;
}

pub fn deinit(self: *LookAt, allocator: std.mem.Allocator) void {
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *LookAt, dt: f64) void {
    if (self.ui_state.grid_updated) self.updateGrid();
    if (self.ui_state.cube_updated) self.updateCube();
    self.view_camera.update(dt);
    {
        const objects: [1]object.object = .{self.grid};
        rhi.drawObjects(objects[0..]);
    }
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

pub fn updateCube(self: *LookAt) void {
    self.ui_state.cube_updated = false;
    self.deleteCube();
    self.renderCube();
}

pub fn updateCamera(self: *LookAt) void {
    const m = math.matrix.transformMatrix(math.matrix.identity(), self.view_camera.camera_matrix);
    rhi.setUniformMatrix(self.camera.cube.mesh.program, "f_camera_transform", m);
}

pub fn renderCube(self: *LookAt) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, cube_vertex_shader, cube_frag_shader);
    const cube: object.object = .{
        .cube = object.cube.init(
            program,
            object.cube.default_positions,
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
        .cube = object.cube.init(
            program,
            object.cube.default_positions,
            .{ 1, 0, 1, 1 },
        ),
    };
    const m = math.matrix.transformMatrix(math.matrix.identity(), self.view_camera.camera_matrix);
    rhi.setUniformMatrix(program, "f_camera_transform", m);
    self.view_camera.addProgram(program, "f_mvp");
    self.camera = camera;
}

pub fn deleteGrid(self: *LookAt) void {
    var objects: [1]object.object = .{self.grid};
    rhi.deleteObjects(objects[0..]);
    self.grid = undefined;
}

pub fn updateGrid(self: *LookAt) void {
    self.ui_state.grid_updated = false;
    self.deleteGrid();
    self.renderGrid();
}

pub fn renderGrid(self: *LookAt) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, grid_vertex_shader, grid_frag_shader);
    var i_datas: [num_grid_lines * 2]rhi.instanceData = undefined;
    var i_data_i: usize = 0;
    for (0..2) |axis| {
        for (0..num_grid_lines) |i| {
            const grid_pos: f32 = @floatFromInt(i);
            var m = math.matrix.identity();
            if (axis == 0) {
                m = math.matrix.transformMatrix(
                    m,
                    math.matrix.translate(
                        self.ui_state.grid_y_translate[0],
                        self.ui_state.grid_y_translate[1],
                        self.ui_state.grid_y_translate[2] + grid_pos * grid_increments,
                    ),
                );
                m = math.matrix.transformMatrix(m, math.matrix.rotationZ(std.math.pi / 2.0));
                m = math.matrix.transformMatrix(m, math.matrix.scale(
                    self.ui_state.grid_y_scale[0],
                    self.ui_state.grid_y_scale[1],
                    self.ui_state.grid_y_scale[2],
                ));
            } else {
                m = math.matrix.transformMatrix(
                    m,
                    math.matrix.translate(
                        self.ui_state.grid_z_translate[0],
                        self.ui_state.grid_z_translate[1] + grid_pos * grid_increments,
                        self.ui_state.grid_z_translate[2],
                    ),
                );
                m = math.matrix.transformMatrix(m, math.matrix.rotationX(self.ui_state.grid_z_rot[0]));
                m = math.matrix.transformMatrix(m, math.matrix.rotationY(self.ui_state.grid_z_rot[1]));
                m = math.matrix.transformMatrix(m, math.matrix.rotationZ(self.ui_state.grid_z_rot[2]));
                m = math.matrix.transformMatrix(m, math.matrix.scale(
                    self.ui_state.grid_z_scale[0],
                    self.ui_state.grid_z_scale[1],
                    self.ui_state.grid_z_scale[2],
                ));
            }
            const i_data: rhi.instanceData = .{
                .t_column0 = m.columns[0],
                .t_column1 = m.columns[1],
                .t_column2 = m.columns[2],
                .t_column3 = m.columns[3],
                .color = .{ 0.15, 0.15, 0.25, 1 },
            };
            i_datas[i_data_i] = i_data;
            i_data_i += 1;
        }
    }
    const grid: object.object = .{
        .parallelepiped = object.parallelepiped.init(
            program,
            i_datas[0..],
        ),
    };
    self.view_camera.addProgram(program, "f_mvp");
    self.grid = grid;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const look_at_ui = @import("look_at_ui.zig");
const object = @import("../../object/object.zig");
const config = @import("../../config/config.zig");
const physics = @import("../../physics/physics.zig");
