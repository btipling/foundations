const turn_sensitivity: f32 = 1.0;
const roll_sensitivity: f32 = 1.0;
const pitch_sensitivity: f32 = 1.5;
const cursor_vertical_sensitivity: f32 = 0.4;
const cursor_horizontal_sensitivity: f32 = 0.65;

pub const world_up: math.vector.vec3 = .{ 1, 0, 0 };
pub const world_right: math.vector.vec3 = .{ 0, 0, 1 };
pub const world_forward: math.vector.vec3 = .{ 0, 1, 0 };

pub const CameraData = struct {
    f_mvp: [16]f32,
    v_matrix: [16]f32,
    f_camera_pos: [4]f32,
    f_global_ambient: [4]f32,
    f_shadow_view_m: [16]f32,
};

pub fn Camera(comptime T: type, comptime IntegratorT: type) type {
    return struct {
        allocator: std.mem.Allocator,
        cfg: *const config,
        camera_matrix: math.matrix = math.matrix.identity(),
        camera_pos: math.vector.vec3 = undefined,
        camera_orientation_pitch: math.rotation.Quat = .{ 1, 0, 0, 0 },
        camera_orientation_heading: math.rotation.Quat = .{ 1, 0, 0, 0 },
        camera_orientation: math.rotation.Quat = .{ 1, 0, 0, 0 },
        cursor_pos: math.vector.vec3 = .{ 0, 0, 0 },
        cursor_mode: bool = false,
        fly_mode: bool = false,
        persp_m: math.matrix,
        view_m: math.matrix,
        mvp: math.matrix,
        movement: physics.movement,
        scene: T,
        integrator: IntegratorT,
        emit_matrix: bool = true,
        input_inactive: bool = false,
        perspective_plane_distance_g: f32 = 0,
        aspect_ratio_s: f32 = 0,
        camera_buffer: rhi.Buffer,
        global_ambient: [4]f32,
        name: []const u8 = "main camera",
        owns_buffer: bool,
        updated: bool = false,

        f_shadow_view_m: math.matrix = math.matrix.identity(),

        const Self = @This();

        pub const program = struct {
            program: u32,
            uniform: []const u8,
        };

        fn initS(cfg: *const config) f32 {
            return @as(f32, @floatFromInt(cfg.width)) / @as(f32, @floatFromInt(cfg.height));
        }

        fn initG(cfg: *const config) f32 {
            return 1.0 / @tan(cfg.fovy * 0.5);
        }

        fn initPerspective(cfg: *const config) math.matrix {
            var P = math.matrix.perspectiveProjectionCamera(initG(cfg), initS(cfg), 0.01, 750);
            P = math.matrix.transformMatrix(P, math.matrix.leftHandedXUpToNDC());
            return P;
        }

        pub fn init(
            allocator: std.mem.Allocator,
            cfg: *const config,
            scene: T,
            integrator: IntegratorT,
            pos: math.vector.vec3,
            heading: ?f32,
        ) *Self {
            const global_ambient: [4]f32 = .{ 0.7, 0.7, 0.7, 1.0 };
            const P = initPerspective(cfg);
            const v_matrix = math.matrix.identity();
            const cd: rhi.Buffer.buffer_data = .{ .camera = .{
                .f_mvp = P.array(),
                .v_matrix = v_matrix.array(),
                .f_camera_pos = .{ pos[0], pos[1], pos[2], 1 },
                .f_global_ambient = global_ambient,
                .f_shadow_view_m = math.matrix.identity().array(),
            } };
            var camera_buffer = rhi.Buffer.init(cd, "camera");
            errdefer camera_buffer.deinit();
            return initInternal(allocator, cfg, scene, integrator, pos, heading, camera_buffer, false);
        }

        pub fn initWithBuffer(
            allocator: std.mem.Allocator,
            cfg: *const config,
            scene: T,
            integrator: IntegratorT,
            pos: math.vector.vec3,
            heading: ?f32,
            camera_buffer: rhi.Buffer,
        ) *Self {
            return initInternal(allocator, cfg, scene, integrator, pos, heading, camera_buffer, false);
        }

        fn initInternal(
            allocator: std.mem.Allocator,
            cfg: *const config,
            scene: T,
            integrator: IntegratorT,
            pos: math.vector.vec3,
            heading: ?f32,
            camera_buffer: rhi.Buffer,
            owns_buffer: bool,
        ) *Self {
            const cam = allocator.create(Self) catch @panic("OOM");
            errdefer allocator.free(cam);

            const P = initPerspective(cfg);

            var camera_heading: math.rotation.Quat = .{ 1, 0, 0, 0 };
            if (heading) |h| {
                const a: math.rotation.AxisAngle = .{
                    .angle = h,
                    .axis = world_up,
                };
                var q = math.rotation.axisAngleToQuat(a);
                q = math.vector.normalize(q);
                q = math.rotation.multiplyQuaternions(camera_heading, q);
                camera_heading = math.vector.normalize(q);
            }

            const global_ambient: [4]f32 = .{ 0.7, 0.7, 0.7, 1.0 };

            const v_matrix = math.matrix.identity();
            const mvp = math.matrix.identity();

            cam.* = .{
                .allocator = allocator,
                .camera_pos = pos,
                .cfg = cfg,
                .camera_matrix = math.matrix.identity(),
                .persp_m = P,
                .view_m = v_matrix,
                .mvp = mvp,
                .movement = undefined,
                .scene = scene,
                .integrator = integrator,
                .camera_orientation = camera_heading,
                .camera_orientation_heading = camera_heading,
                .perspective_plane_distance_g = initG(cfg),
                .aspect_ratio_s = initS(cfg),
                .camera_buffer = camera_buffer,
                .global_ambient = global_ambient,
                .owns_buffer = owns_buffer,
            };
            cam.movement = physics.movement.init(cam.camera_pos, 0, .none);
            cam.updateCameraMatrix();
            cam.updateMVP();
            return cam;
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            if (self.owns_buffer) self.camera_buffer.deinit();
            self.camera_buffer = undefined;
            allocator.destroy(self);
        }

        pub fn update(self: *Self, dt: f64) void {
            self.integrate(dt);
            self.handleInput(dt);
            if (!self.updated) {
                self.updateMVP();
                self.updated = true;
            }
        }

        pub fn setViewActivation(self: *Self, enabled: bool) void {
            if (self.emit_matrix == enabled) return;
            self.emit_matrix = enabled;
            if (enabled) self.updateMVP();
        }

        pub fn setInputActivation(self: *Self, active: bool) void {
            self.input_inactive = !active;
        }

        fn integrate(self: *Self, t: f64) void {
            self.movement.step = self.integrator.timestep(self.movement.step, t);
            switch (self.movement.movement_direction) {
                .forward => self.moveCameraForward(),
                .backward => self.moveCameraBackward(),
                .left => self.moveCameraLeft(),
                .right => self.moveCameraRight(),
                .up => self.moveCameraUp(),
                .down => self.moveCameraDown(),
                else => {},
            }
        }

        fn handleInput(self: *Self, t: f64) void {
            if (self.input_inactive) return;
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
                    c.GLFW_KEY_TAB => {
                        if (input.key_action) |action| {
                            if (action == c.GLFW_RELEASE) self.fly_mode = !self.fly_mode;
                        }
                    },
                    else => {},
                }
            }
            const go_fast = ui.input.keyPressed(c.GLFW_KEY_LEFT_SHIFT);
            if (ui.input.keyPressed(c.GLFW_KEY_W)) self.accelerate(t, go_fast, .forward);
            if (ui.input.keyPressed(c.GLFW_KEY_S)) self.accelerate(t, go_fast, .backward);
            if (ui.input.keyPressed(c.GLFW_KEY_A)) if (self.fly_mode) self.turnRight() else self.accelerate(t, go_fast, .left);
            if (ui.input.keyPressed(c.GLFW_KEY_D)) if (self.fly_mode) self.turnLeft() else self.accelerate(t, go_fast, .right);
            if (ui.input.keyPressed(c.GLFW_KEY_SPACE)) self.accelerate(t, go_fast, .up);
            if (ui.input.keyPressed(c.GLFW_KEY_LEFT_CONTROL)) self.accelerate(t, go_fast, .down);
            if (ui.input.keyPressed(c.GLFW_KEY_J)) if (self.fly_mode) self.rollLeft();
            if (ui.input.keyPressed(c.GLFW_KEY_SEMICOLON)) if (self.fly_mode) self.rollRight();
            if (ui.input.keyPressed(c.GLFW_KEY_L)) if (self.fly_mode) self.pitchUp();
            if (ui.input.keyPressed(c.GLFW_KEY_K)) if (self.fly_mode) self.pitchDown();
            if (new_cursor_coords) |cc| self.handleCursor(cc);
        }

        fn handleCursor(self: *Self, new_cursor_coords: math.vector.vec3) void {
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
                        cursor_horizontal_sensitivity,
                    );
                }
                {
                    self.camera_orientation = updateOrientation(
                        self.camera_orientation,
                        world_right,
                        self.cursor_pos[0],
                        new_cursor_coords[0],
                        cursor_vertical_sensitivity,
                    );
                }
            } else {
                {
                    self.camera_orientation_heading = updateOrientation(
                        self.camera_orientation_heading,
                        world_up,
                        new_cursor_coords[2],
                        self.cursor_pos[2],
                        cursor_horizontal_sensitivity,
                    );
                }
                {
                    self.camera_orientation_pitch = updateOrientation(
                        self.camera_orientation_pitch,
                        world_right,
                        self.cursor_pos[0],
                        new_cursor_coords[0],
                        cursor_vertical_sensitivity,
                    );
                }
                self.camera_orientation = math.rotation.multiplyQuaternions(
                    self.camera_orientation_heading,
                    self.camera_orientation_pitch,
                );
            }
            self.cursor_pos = new_cursor_coords;
            self.updateCameraMatrix();
            self.updateMVP();
        }

        fn pitchUp(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_right,
                0,
                0.01,
                pitch_sensitivity,
            );
        }

        fn pitchDown(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_right,
                0.01,
                0,
                pitch_sensitivity,
            );
        }

        fn turnRight(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_up,
                0,
                0.01,
                turn_sensitivity,
            );
        }

        fn turnLeft(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_up,
                0.01,
                0,
                turn_sensitivity,
            );
        }

        fn rollRight(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_forward,
                0,
                0.01,
                roll_sensitivity,
            );
        }

        fn rollLeft(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_forward,
                0.01,
                0,
                roll_sensitivity,
            );
        }

        fn updateOrientation(
            orientation: math.rotation.Quat,
            axis: math.vector.vec3,
            a_pos: f32,
            b_pos: f32,
            sensitivity: f32,
        ) math.rotation.Quat {
            const change = (a_pos - b_pos) * sensitivity;
            const a: math.rotation.AxisAngle = .{
                .angle = change,
                .axis = axis,
            };
            var q = math.rotation.axisAngleToQuat(a);
            q = math.vector.normalize(q);
            q = math.rotation.multiplyQuaternions(orientation, q);
            return math.vector.normalize(q);
        }

        fn toggleCursor(self: *Self) void {
            if (self.cursor_mode) {
                self.cursor_mode = false;
                ui.showCursor();
                return;
            }
            self.cursor_mode = true;
            ui.hideCursor();
            return;
        }

        fn moveCameraUp(self: *Self) void {
            const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
            const velocity = math.vector.mul(self.movement.step.state.position, orientation_vector);
            self.camera_pos = math.vector.add(self.movement.start, velocity);
            self.movement.start = self.camera_pos;
            self.updateCameraComplex();
        }

        fn moveCameraDown(self: *Self) void {
            const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
            const velocity = math.vector.negate(math.vector.mul(self.movement.step.state.position, orientation_vector));
            self.camera_pos = math.vector.add(self.movement.start, velocity);
            self.movement.start = self.camera_pos;
            self.updateCameraComplex();
        }

        fn accelerate(self: *Self, t: f64, go_fast: bool, direction: physics.movement.direction) void {
            self.movement = physics.movement.init(self.camera_pos, t, direction);
            self.movement.step.state.position = if (go_fast) 0.5 else 0.05;
        }

        fn moveCameraForward(self: *Self) void {
            const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
            const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
            const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
            const velocity = math.vector.mul(self.movement.step.state.position, left_vector);
            self.camera_pos = math.vector.add(self.movement.start, velocity);
            self.movement.start = self.camera_pos;
            self.updateCameraComplex();
        }

        fn moveCameraBackward(self: *Self) void {
            const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
            const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
            const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
            const velocity = math.vector.negate(math.vector.mul(self.movement.step.state.position, left_vector));
            self.camera_pos = math.vector.add(self.movement.start, velocity);
            self.movement.start = self.camera_pos;
            self.updateCameraComplex();
        }

        fn moveCameraRight(self: *Self) void {
            const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
            const velocity = math.vector.mul(self.movement.step.state.position, direction_vector);
            self.camera_pos = math.vector.add(self.movement.start, velocity);
            self.movement.start = self.camera_pos;
            self.updateCameraComplex();
        }

        fn moveCameraLeft(self: *Self) void {
            const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
            const velocity = math.vector.negate(math.vector.mul(self.movement.step.state.position, direction_vector));
            self.camera_pos = math.vector.add(self.movement.start, velocity);
            self.movement.start = self.camera_pos;
            self.updateCameraComplex();
        }

        fn updateCameraComplex(self: *Self) void {
            self.updateCameraMatrix();
            self.updateMVP();
        }

        pub fn updateCameraMatrix(self: *Self) void {
            var m = math.matrix.identity();
            m = math.matrix.transformMatrix(m, math.matrix.translate(
                self.camera_pos[0],
                self.camera_pos[1],
                self.camera_pos[2],
            ));
            m = math.matrix.transformMatrix(m, math.matrix.normalizedQuaternionToMatrix(self.camera_orientation));
            self.camera_matrix = m;
        }

        pub fn updateGlobalAmbient(self: *Self, color: math.vector.vec4) void {
            self.global_ambient = color;
            self.updateMVP();
        }

        pub fn updateMVP(self: *Self) void {
            self.view_m = math.matrix.cameraInverse(self.camera_matrix);
            self.mvp = math.matrix.transformMatrix(self.persp_m, self.view_m);
            if (!self.emit_matrix) {
                return;
            }
            self.camera_buffer.update(.{ .camera = .{
                .f_mvp = self.mvp.array(),
                .v_matrix = self.view_m.array(),
                .f_camera_pos = .{
                    self.camera_pos[0],
                    self.camera_pos[1],
                    self.camera_pos[2],
                    1,
                },
                .f_global_ambient = self.global_ambient,
                .f_shadow_view_m = self.f_shadow_view_m.array(),
            } });
            self.scene.updateCamera();
        }
    };
}

const std = @import("std");
const c = @import("../c.zig").c;
const ui = @import("../ui/ui.zig");
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
const config = @import("../config/config.zig");
const physics = @import("physics.zig");
