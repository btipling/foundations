pub fn Camera(comptime T: type, comptime IntegratorT: type) type {
    return struct {
        allocator: std.mem.Allocator,
        cfg: *config,
        camera_matrix: math.matrix = undefined,
        camera_pos: math.vector.vec3 = .{ 1, 3.5, 1 },
        camera_orientation_pitch: math.rotation.Quat = .{ 1, 0, 0, 0 },
        camera_orientation_heading: math.rotation.Quat = .{ 1, 0, 0, 0 },
        camera_orientation: math.rotation.Quat = .{ 1, 0, 0, 0 },
        cursor_pos: math.vector.vec3 = .{ 0, 0, 0 },
        cursor_mode: bool = false,
        use_camera: bool = false,
        fly_mode: bool = false,
        persp_m: math.matrix,
        mvp: math.matrix,
        forward: physics.movement,
        programs: std.ArrayListUnmanaged(program) = .{},
        scene: T,
        integrator: IntegratorT,

        const Self = @This();

        pub const program = struct {
            program: u32,
            uniform: []const u8,
        };

        const world_up: math.vector.vec3 = .{ 1, 0, 0 };
        const world_right: math.vector.vec3 = .{ 0, 0, 1 };
        const world_forward: math.vector.vec3 = .{ 0, 1, 0 };
        const speed: f32 = 0.05;

        pub fn init(allocator: std.mem.Allocator, cfg: *config, scene: T, integrator: IntegratorT) *Self {
            const cam = allocator.create(Self) catch @panic("OOM");
            const s = @as(f32, @floatFromInt(cfg.width)) / @as(f32, @floatFromInt(cfg.height));
            const mvp = math.matrix.transformMatrix(
                math.matrix.perspectiveProjection(cfg.fovy, s, 0.01, 750),
                math.matrix.leftHandedXUpToNDC(),
            );

            cam.* = .{
                .allocator = allocator,
                .cfg = cfg,
                .persp_m = mvp,
                .mvp = mvp,
                .forward = undefined,
                .scene = scene,
                .integrator = integrator,
            };
            cam.forward = physics.movement.init(cam.camera_pos, 0);
            cam.updateCameraMatrix();
            return cam;
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.programs.deinit(self.allocator);
            allocator.destroy(self);
        }

        pub fn update(self: *Self, dt: f64) void {
            self.integrate(dt);
            self.handleInput(dt);
        }

        fn integrate(self: *Self, t: f64) void {
            self.forward.step = self.integrator.timestep(self.forward.step, t);
            self.moveCameraForward();
        }

        fn handleInput(self: *Self, t: f64) void {
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
            if (ui.input.keyPressed(c.GLFW_KEY_W)) self.accelerateForward(t, ui.input.keyPressed(c.GLFW_KEY_LEFT_SHIFT));
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
            self.updateMVP();
        }

        fn turnUp(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_right,
                0,
                0.01,
            );
        }

        fn turnDown(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_right,
                0.01,
                0,
            );
        }

        fn turnRight(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_up,
                0,
                0.01,
            );
        }

        fn turnLeft(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_up,
                0.01,
                0,
            );
        }

        fn rollRight(self: *Self) void {
            self.camera_orientation = updateOrientation(
                self.camera_orientation,
                world_forward,
                0,
                0.01,
            );
        }

        fn rollLeft(self: *Self) void {
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

        fn toggleView(self: *Self) void {
            if (self.use_camera) {
                self.use_camera = false;
                return;
            }
            self.use_camera = true;
            return;
        }

        fn moveCameraUp(self: *Self) void {
            const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
            const velocity = math.vector.mul(speed, orientation_vector);
            self.camera_pos = math.vector.add(self.camera_pos, velocity);
            self.updateCameraComplex();
        }

        fn moveCameraDown(self: *Self) void {
            const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
            const velocity = math.vector.negate(math.vector.mul(speed, orientation_vector));
            self.camera_pos = math.vector.add(self.camera_pos, velocity);
            self.updateCameraComplex();
        }

        fn accelerateForward(self: *Self, t: f64, go_fast: bool) void {
            self.forward = physics.movement.init(self.camera_pos, t);
            self.forward.step.state.position = if (go_fast) 0.5 else 0.05;
        }

        fn moveCameraForward(self: *Self) void {
            const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
            const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
            const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
            const velocity = math.vector.mul(self.forward.step.state.position, left_vector);
            self.camera_pos = math.vector.add(self.forward.start, velocity);
            self.forward.start = self.camera_pos;
            self.updateCameraComplex();
        }

        fn moveCameraBackward(self: *Self) void {
            const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
            const orientation_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_up, self.camera_orientation));
            const left_vector = math.vector.crossProduct(direction_vector, orientation_vector);
            const velocity = math.vector.negate(math.vector.mul(speed, left_vector));
            self.camera_pos = math.vector.add(self.camera_pos, velocity);
            self.updateCameraComplex();
        }

        fn moveCameraRight(self: *Self) void {
            const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
            const velocity = math.vector.mul(speed, direction_vector);
            self.camera_pos = math.vector.add(self.camera_pos, velocity);
            self.updateCameraComplex();
        }

        fn moveCameraLeft(self: *Self) void {
            const direction_vector = math.vector.normalize(math.rotation.rotateVectorWithNormalizedQuat(world_right, self.camera_orientation));
            const velocity = math.vector.negate(math.vector.mul(speed, direction_vector));
            self.camera_pos = math.vector.add(self.camera_pos, velocity);
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
            m = math.matrix.transformMatrix(m, math.matrix.uniformScale(0.1));
            self.camera_matrix = m;
        }

        pub fn updateMVP(self: *Self) void {
            if (self.use_camera) {
                var m = math.matrix.translate(self.camera_pos[0], self.camera_pos[1], self.camera_pos[2]);
                m = math.matrix.transformMatrix(m, math.matrix.normalizedQuaternionToMatrix(self.camera_orientation));
                m = math.matrix.inverse(m);
                self.mvp = math.matrix.transformMatrix(self.persp_m, m);
            } else self.mvp = self.persp_m;
            self.updatePrograms();
        }

        pub fn updatePrograms(self: *Self) void {
            for (self.programs.items) |prog| {
                rhi.setUniformMatrix(prog.program, prog.uniform, self.mvp);
            }
            self.scene.updateCamera();
        }

        pub fn addProgram(self: *Self, p: u32, uniform: []const u8) void {
            self.programs.append(
                self.allocator,
                .{ .program = p, .uniform = uniform },
            ) catch @panic("OOM");
            rhi.setUniformMatrix(p, uniform, self.mvp);
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
