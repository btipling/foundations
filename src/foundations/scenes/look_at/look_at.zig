ui_state: look_at_ui,
allocator: std.mem.Allocator,
cfg: *config,
quad: object.object = undefined,
cube: object.object = undefined,
mvp: math.matrix,

const LookAt = @This();

const num_grid_lines: usize = 50;
const grid_len: usize = 2;
const grid_increments: usize = 25;

const grid_vertex_shader: []const u8 = @embedFile("look_at_grid_vertex.glsl");
const grid_frag_shader: []const u8 = @embedFile("look_at_grid_frag.glsl");
const cube_vertex_shader: []const u8 = @embedFile("look_at_cube_vertex.glsl");
const cube_frag_shader: []const u8 = @embedFile("look_at_cube_frag.glsl");

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
    return lkt;
}

pub fn deinit(self: *LookAt, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *LookAt, _: f64) void {
    if (self.ui_state.grid_updated) self.updateGrid();
    self.handleInput();
    {
        const objects: [1]object.object = .{self.quad};
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{self.cube};
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

fn handleInput(self: *LookAt) void {
    const input = ui.input.getReadOnly() orelse return;
    const x = input.coord_x orelse return;
    const z = input.coord_z orelse return;
    _ = x;
    _ = z;
    _ = self;
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
    var m = math.matrix.transformMatrix(
        self.mvp,
        math.matrix.translate(0.5, 0.5, 0.5),
    );
    m = math.matrix.transformMatrix(m, math.matrix.translate(0.0, 10.5, 0.0));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(1));
    rhi.setUniformMatrix(program, "f_transform", m);
    self.cube = cube;
}

pub fn deleteGrid(self: *LookAt) void {
    var objects: [1]object.object = .{self.quad};
    rhi.deleteObjects(objects[0..]);
    self.quad = undefined;
}

pub fn updateGrid(self: *LookAt) void {
    self.ui_state.grid_updated = false;
    self.deleteGrid();
    self.renderGrid();
}

pub fn renderGrid(self: *LookAt) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, grid_vertex_shader, grid_frag_shader);
    var i_datas: [num_grid_lines]rhi.instanceData = undefined;
    for (0..num_grid_lines) |i| {
        const grid_pos: f32 = @floatFromInt(i);
        var m = math.matrix.transformMatrix(
            self.mvp,
            math.matrix.translate(
                self.ui_state.grid_translate[0],
                self.ui_state.grid_translate[1],
                self.ui_state.grid_translate[2] + grid_pos * grid_increments,
            ),
        );
        m = math.matrix.transformMatrix(m, math.matrix.scale(
            self.ui_state.grid_scale[0],
            self.ui_state.grid_scale[1],
            self.ui_state.grid_scale[2],
        ));
        m = math.matrix.transformMatrix(m, math.matrix.rotationZ(std.math.pi / 2.0));
        const i_data: rhi.instanceData = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 1, 1, 1 },
        };
        i_datas[i] = i_data;
    }
    const quad: object.object = .{
        .quad = object.quad.initInstanced(
            program,
            i_datas[0..],
        ),
    };
    self.quad = quad;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const look_at_ui = @import("look_at_ui.zig");
const object = @import("../../object/object.zig");
const config = @import("../../config/config.zig");
