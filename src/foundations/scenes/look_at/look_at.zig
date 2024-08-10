ui_state: look_at_ui,
allocator: std.mem.Allocator,
cfg: *config,
grid: object.object = undefined,
cube: object.object = undefined,
camera: object.object = undefined,
camera_matrix: math.matrix = undefined,
camera_pos: math.vector.vec3 = .{ 1, 3.5, 1 },
camera_orientation_pitch: math.rotation.Quat = .{ 1, 0, 0, 0 },
camera_orientation_heading: math.rotation.Quat = .{ 1, 0, 0, 0 },
camera_orientation: math.rotation.Quat = .{ 1, 0, 0, 0 },
cursor_pos: math.vector.vec3 = .{ 0, 0, 0 },
cursor_mode: bool = false,
use_camera: bool = false,
fly_mode: bool = false,
step: ?physics.step = null,
persp_m: math.matrix,
mvp: math.matrix,

const LookAt = @This();

const num_grid_lines: usize = 500;
const grid_len: usize = 2;
const grid_increments: usize = 25;
const world_up: math.vector.vec3 = .{ 1, 0, 0 };
const world_right: math.vector.vec3 = .{ 0, 0, 1 };
const world_forward: math.vector.vec3 = .{ 0, 1, 0 };
const speed: f32 = 0.05;

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
        math.matrix.perspectiveProjection(cfg.fovy, s, 0.01, 750),
        math.matrix.leftHandedXUpToNDC(),
    );

    lkt.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .cfg = cfg,
        .persp_m = mvp,
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

pub fn draw(self: *LookAt, dt: f64) void {
    if (self.step) |s| {
        const new_step = physics.timestep(s, dt);
        if (math.float.equal(new_step.state.position, s.state.position, 0.00001)) {
            self.step = null;
        } else {
            // do something
            self.step = new_step;
        }
    }
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
    if (!self.use_camera) {
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
            c.GLFW_KEY_V => {
                if (input.key_action) |action| {
                    if (action == c.GLFW_RELEASE) self.toggleView();
                }
            },
            c.GLFW_KEY_B => {
                if (input.key_action) |action| {
                    if (action == c.GLFW_RELEASE) self.fly_mode = !self.fly_mode;
                }
            },
            else => {},
        }
    }
    if (ui.input.keyPressed(c.GLFW_KEY_W)) self.moveCameraForward();
    if (ui.input.keyPressed(c.GLFW_KEY_S)) self.moveCameraBackward();
    if (ui.input.keyPressed(c.GLFW_KEY_A)) if (self.fly_mode) self.turnRight() else self.moveCameraLeft();
    if (ui.input.keyPressed(c.GLFW_KEY_D)) if (self.fly_mode) self.turnLeft() else self.moveCameraRight();
    if (ui.input.keyPressed(c.GLFW_KEY_LEFT_SHIFT)) self.moveCameraUp();
    if (ui.input.keyPressed(c.GLFW_KEY_LEFT_CONTROL)) self.moveCameraDown();
    if (ui.input.keyPressed(c.GLFW_KEY_J)) if (self.fly_mode) self.rollLeft();
    if (ui.input.keyPressed(c.GLFW_KEY_SEMICOLON)) if (self.fly_mode) self.rollRight();
    if (ui.input.keyPressed(c.GLFW_KEY_L)) if (self.fly_mode) self.turnUp();
    if (ui.input.keyPressed(c.GLFW_KEY_K)) if (self.fly_mode) self.turnDown();
    if (new_cursor_coords) |cc| self.handleCursor(cc);
}

fn handleCursor(self: *LookAt, new_cursor_coords: math.vector.vec3) void {
    if (!self.cursor_mode) {
        self.cursor_pos = new_cursor_coords;
        return;
    }
    if (self.fly_mode) {
        {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_up,
                new_cursor_coords[2],
                self.cursor_pos[2],
            );
        }
        {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_right,
                self.cursor_pos[0],
                new_cursor_coords[0],
            );
        }
    } else {
        {
            self.camera_orientation_heading = updateOrientation(
                self.camera_orientation_heading,
                world_up,
                new_cursor_coords[2],
                self.cursor_pos[2],
            );
        }
        {
            self.camera_orientation_pitch = updateOrientation(
                self.camera_orientation_pitch,
                world_right,
                self.cursor_pos[0],
                new_cursor_coords[0],
            );
        }
        self.camera_orientation = math.rotation.multiplyQuaternions(
            self.camera_orientation_heading,
            self.camera_orientation_pitch,
        );
    }
    self.cursor_pos = new_cursor_coords;
    self.updateCameraMatrix();
    self.updateCamera();
    self.updateMVP();
}

fn turnUp(self: *LookAt) void {
    self.camera_orientation = updateOrientation(
        self.camera_orientation,
        world_right,
        0,
        0.01,
    );
}

fn turnDown(self: *LookAt) void {
    self.camera_orientation = updateOrientation(
        self.camera_orientation,
        world_right,
        0.01,
        0,
    );
}

fn turnRight(self: *LookAt) void {
    self.camera_orientation = updateOrientation(
        self.camera_orientation,
        world_up,
        0,
        0.01,
    );
}

fn turnLeft(self: *LookAt) void {
    self.camera_orientation = updateOrientation(
        self.camera_orientation,
        world_up,
        0.01,
        0,
    );
}

fn rollRight(self: *LookAt) void {
    self.camera_orientation = updateOrientation(
        self.camera_orientation,
        world_forward,
        0,
        0.01,
    );
}

fn rollLeft(self: *LookAt) void {
    self.camera_orientation = updateOrientation(
        self.camera_orientation,
        world_forward,
        0.01,
        0,
    );
}

fn updateOrientation(
    orientation: math.rotation.Quat,
    axis: math.vector.vec3,
    a_pos: f32,
    b_pos: f32,
) math.rotation.Quat {
    const change = a_pos - b_pos;
    const a: math.rotation.AxisAngle = .{
        .angle = change,
        .axis = axis,
    };
    var q = math.rotation.axisAngleToQuat(a);
    q = math.vector.normalize(q);
    q = math.rotation.multiplyQuaternions(orientation, q);
    return math.vector.normalize(q);
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

fn toggleView(self: *LookAt) void {
    if (self.use_camera) {
        self.use_camera = false;
        return;
    }
    self.use_camera = true;
    return;
}

fn moveCameraUp(self: *LookAt) void {
    const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
    const velocity = math.vector.mul(speed, orientation_vector);
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraComplex();
}

fn moveCameraDown(self: *LookAt) void {
    const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
    const velocity = math.vector.negate(math.vector.mul(speed, orientation_vector));
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraComplex();
}

fn moveCameraForward(self: *LookAt) void {
    const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
    const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
    const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
    const velocity = math.vector.mul(speed, left_vector);
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraComplex();
}

fn moveCameraBackward(self: *LookAt) void {
    const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
    const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
    const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
    const velocity = math.vector.negate(math.vector.mul(speed, left_vector));
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraComplex();
}

fn moveCameraRight(self: *LookAt) void {
    const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
    const velocity = math.vector.mul(speed, direction_vector);
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraComplex();
}

fn moveCameraLeft(self: *LookAt) void {
    const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
    const velocity = math.vector.negate(math.vector.mul(speed, direction_vector));
    self.camera_pos = math.vector.add(self.camera_pos, velocity);
    self.updateCameraComplex();
}

fn updateCameraComplex(self: *LookAt) void {
    self.updateCameraMatrix();
    self.updateCamera();
    self.updateMVP();
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
    m = math.matrix.transformMatrix(m, math.matrix.normalizedQuaternionToMatrix(self.camera_orientation));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(0.1));
    self.camera_matrix = m;
}

pub fn updateMVP(self: *LookAt) void {
    if (self.use_camera) {
        var m = math.matrix.translate(self.camera_pos[0], self.camera_pos[1], self.camera_pos[2]);
        m = math.matrix.transformMatrix(m, math.matrix.normalizedQuaternionToMatrix(self.camera_orientation));
        m = math.matrix.inverse(m);
        self.mvp = math.matrix.transformMatrix(self.persp_m, m);
    } else self.mvp = self.persp_m;
    rhi.setUniformMatrix(self.grid.parallelepiped.mesh.program, "f_mvp", self.mvp);
    rhi.setUniformMatrix(self.cube.cube.mesh.program, "f_mvp", self.mvp);
    rhi.setUniformMatrix(self.camera.cube.mesh.program, "f_mvp", self.mvp);
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
    rhi.setUniformMatrix(program, "f_mvp", self.mvp);
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
    const m = math.matrix.transformMatrix(math.matrix.identity(), self.camera_matrix);
    rhi.setUniformMatrix(program, "f_camera_transform", m);
    rhi.setUniformMatrix(program, "f_mvp", self.mvp);
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
    rhi.setUniformMatrix(program, "f_mvp", self.mvp);
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
