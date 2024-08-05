ui_state: look_at_ui,
allocator: std.mem.Allocator,
cfg: *config,
grid: object.object = undefined,
cube: object.object = undefined,
camera: object.object = undefined,
camera_matrix: math.matrix = undefined,
camera_pos: math.vector.vec3 = .{ 1, 3.5, 1 },
camera_orientation: math.vector.vec3 = .{ 1, 0, 0 },
cursor_pos: math.vector.vec3 = .{ 0, 0, 0 },
cursor_mode: bool = false,
mvp: math.matrix,

const LookAt = @This();

const num_grid_lines: usize = 10000;
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
    const ui_state: look_at_ui = .{};
    const s = @as(f32, @floatFromInt(cfg.width)) / @as(f32, @floatFromInt(cfg.height));
    const mvp = math.matrix.transformMatrix(
        math.matrix.perspectiveProjection(cfg.fovy, s, 1, 1000),
        math.matrix.leftHandedXUpToNDC(),
    );
    lkt.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .cfg = cfg,
        .mvp = mvp,
    };
    lkt.renderGrid();
    lkt.renderCube();
    lkt.updateCameraMatrix();
    lkt.renderCamera();
    return lkt;
}

pub fn deinit(self: *LookAt, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *LookAt, _: f64) void {
    if (self.ui_state.grid_updated) self.updateGrid();
    if (self.ui_state.cube_updated) self.updateCube();
    self.handleInput();
    {
        const objects: [1]object.object = .{self.grid};
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{self.cube};
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{self.camera};
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

fn handleInput(self: *LookAt) void {
    const input = ui.input.getReadOnly() orelse return;
    var new_cursor_coords: ?math.vector.vec3 = null;
    cursor: {
        const x = input.coord_x orelse break :cursor;
        const z = input.coord_z orelse break :cursor;
        new_cursor_coords = .{ x, 0, z };
    }
    if (input.key) |k| {
        switch (k) {
            c.GLFW_KEY_C => {
                if (input.key_action) |action| {
                    if (action == c.GLFW_RELEASE) self.toggleCursor();
                }
            },
            c.GLFW_KEY_W => self.moveCameraForward(),
            c.GLFW_KEY_S => self.moveCameraBackward(),
            c.GLFW_KEY_A => self.moveCameraLeft(),
            c.GLFW_KEY_D => self.moveCameraRight(),
            c.GLFW_KEY_LEFT_SHIFT => self.moveCameraUp(),
            c.GLFW_KEY_LEFT_CONTROL => self.moveCameraDown(),
            else => {},
        }
    }
    if (new_cursor_coords) |cc| self.handleCursor(cc);
}

fn handleCursor(self: LookAt, new_cursor_coords: math.vector.vec3) void {
    if (!self.cursor_mode) return;
    std.debug.print("new cursor pos ({d}, {d}, {d})\n", .{
        new_cursor_coords[0],
        new_cursor_coords[1],
        new_cursor_coords[2],
    });
}

fn toggleCursor(self: *LookAt) void {
    if (self.cursor_mode) {
        self.cursor_mode = false;
        ui.showCursor();
        return;
    }
    self.cursor_mode = true;
    ui.hideCursor();
    return;
}

fn moveCameraUp(self: *LookAt) void {
    const speed: f32 = 0.01;
    const orientation_vector = math.vector.normalize(self.camera_orientation);
    const velocity = math.vector.mul(speed, orientation_vector);
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraMatrix();
    self.updateCamera();
}

fn moveCameraDown(self: *LookAt) void {
    const speed: f32 = 0.01;
    const orientation_vector = math.vector.normalize(self.camera_orientation);
    const velocity = math.vector.negate(math.vector.mul(speed, orientation_vector));
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraMatrix();
    self.updateCamera();
}

fn moveCameraLeft(self: *LookAt) void {
    const speed: f32 = 0.01;
    const direction_vector = math.vector.normalize(self.camera_pos);
    const orientation_vector = math.vector.normalize(self.camera_orientation);
    const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
    const velocity = math.vector.mul(speed, left_vector);
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraMatrix();
    self.updateCamera();
}

fn moveCameraRight(self: *LookAt) void {
    const speed: f32 = 0.01;
    const direction_vector = math.vector.normalize(self.camera_pos);
    const orientation_vector = math.vector.normalize(self.camera_orientation);
    const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
    const velocity = math.vector.negate(math.vector.mul(speed, left_vector));
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraMatrix();
    self.updateCamera();
}

fn moveCameraForward(self: *LookAt) void {
    const speed: f32 = 0.01;
    const direction_vector = math.vector.normalize(self.camera_pos);
    const velocity = math.vector.mul(speed, direction_vector);
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraMatrix();
    self.updateCamera();
}

fn moveCameraBackward(self: *LookAt) void {
    const speed: f32 = 0.01;
    const direction_vector = math.vector.normalize(self.camera_pos);
    const velocity = math.vector.negate(math.vector.mul(speed, direction_vector));
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraMatrix();
    self.updateCamera();
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

pub fn updateCameraMatrix(self: *LookAt) void {
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(
        self.camera_pos[0],
        self.camera_pos[1],
        self.camera_pos[2],
    ));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(0.1));
    self.camera_matrix = m;
}

pub fn updateCamera(self: *LookAt) void {
    self.deleteCamera();
    self.renderCamera();
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
    var m = math.matrix.transformMatrix(self.lookAt(), math.matrix.translate(0.0, 10.5, 0.0));
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
    const m = math.matrix.transformMatrix(self.lookAt(), self.camera_matrix);
    rhi.setUniformMatrix(program, "f_camera_transform", m);
    self.camera = camera;
}

pub fn lookAt(self: *LookAt) math.matrix {
    return self.mvp;
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
            var m = self.lookAt();
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
