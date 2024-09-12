allocator: std.mem.Allocator,
pyramid: object.object = .{ .norender = .{} },
pyramid_uniform: rhi.Uniform = .empty,
parallelepiped: object.object = .{ .norender = .{} },
parallelepiped_uniform: rhi.Uniform = .empty,
cylinder: object.object = .{ .norender = .{} },
cylinder_uniform: rhi.Uniform = .empty,
view_camera: *physics.camera.Camera(*SimpleSolarSystem, physics.Integrator(physics.SmoothDeceleration)),
stack: [5]math.matrix = undefined,
current_stack_index: u8 = 0,

const SimpleSolarSystem = @This();

const num_cubes = 1;

const pyramid_vertex_shader: []const u8 = @embedFile("pyramid_vertex.glsl");
const cube_vertex_shader: []const u8 = @embedFile("cube_vertex.glsl");
const cylinder_vertex_shader: []const u8 = @embedFile("cylinder_vertex.glsl");
const frag_shader: []const u8 = @embedFile("simple_solar_system_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Cube And Pyramid",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *SimpleSolarSystem {
    const pd = allocator.create(SimpleSolarSystem) catch @panic("OOM");

    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*SimpleSolarSystem, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        cfg,
        pd,
        integrator,
        .{ 3, -8, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
    };
    pd.stack[0] = math.matrix.identity();
    pd.renderPyramid();
    pd.renderParallepiped();
    pd.renderCylinder();
    return pd;
}

pub fn deinit(self: *SimpleSolarSystem, allocator: std.mem.Allocator) void {
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *SimpleSolarSystem, dt: f64) void {
    self.stack[self.current_stack_index].debug("huh?");
    self.pyramid_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.parallelepiped_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.cylinder_uniform.setUniformMatrix(self.stack[self.current_stack_index]);
    self.view_camera.update(dt);
    {
        const objects: [3]object.object = .{
            self.pyramid,
            self.parallelepiped,
            self.cylinder,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *SimpleSolarSystem) void {}

pub fn renderPyramid(self: *SimpleSolarSystem) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, pyramid_vertex_shader, frag_shader);
    const cm = math.matrix.identity();
    const i_data: rhi.instanceData = .{
        .t_column0 = cm.columns[0],
        .t_column1 = cm.columns[1],
        .t_column2 = cm.columns[2],
        .t_column3 = cm.columns[3],
        .color = .{ 1, 0, 1, 1 },
    };
    var i_datas: [num_cubes]rhi.instanceData = undefined;
    for (0..num_cubes) |i| {
        i_datas[i] = i_data;
    }
    const pyramid: object.object = .{
        .pyramid = object.Pyramid.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.view_camera.addProgram(prog, "f_mvp");
    self.pyramid = pyramid;
    self.pyramid_uniform = rhi.Uniform.init(prog, "f_pyramid_transform");
}

pub fn renderParallepiped(self: *SimpleSolarSystem) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, cube_vertex_shader, frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    {
        const cm = math.matrix.identity();
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.view_camera.addProgram(prog, "f_mvp");
    self.parallelepiped = parallelepiped;
    self.parallelepiped_uniform = rhi.Uniform.init(prog, "f_cube_transform");
}

pub fn renderCylinder(self: *SimpleSolarSystem) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, cylinder_vertex_shader, frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    {
        const cm = math.matrix.identity();
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const cylinder: object.object = .{
        .cylinder = object.Cylinder.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.view_camera.addProgram(prog, "f_mvp");
    self.cylinder = cylinder;
    self.cylinder_uniform = rhi.Uniform.init(prog, "f_cylinder_transform");
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const config = @import("../../../../config/config.zig");
const physics = @import("../../../../physics/physics.zig");
