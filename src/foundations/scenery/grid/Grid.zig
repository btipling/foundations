allocator: std.mem.Allocator,
grid: object.object = undefined,
grid_y_scale: math.vector.vec3 = .{ 5000, 1, 1 },
grid_y_translate: math.vector.vec3 = .{ -67, -2500, -5000 },
grid_z_scale: math.vector.vec3 = .{ 5000, 1, 1 },
grid_z_translate: math.vector.vec3 = .{ -68.5, -1071, -2578 },
grid_z_rot: math.vector.vec3 = .{ std.math.pi / 2.0, 0, std.math.pi / 2.0 },

const Grid = @This();
pub const mvp_uniform_name: []const u8 = "f_mvp";

const num_grid_lines: usize = 500;
const grid_len: usize = 2;
const grid_increments: usize = 25;

const grid_vertex_shader: []const u8 = @embedFile("grid_vertex.glsl");
const grid_frag_shader: []const u8 = @embedFile("grid_frag.glsl");

pub fn init(allocator: std.mem.Allocator) *Grid {
    const grid = allocator.create(Grid) catch @panic("OOM");
    errdefer allocator.destroy(grid);

    grid.* = .{
        .allocator = allocator,
    };
    grid.renderGrid();
    return grid;
}

pub fn deinit(self: *Grid) void {
    self.deleteGrid();
    self.allocator.destroy(self);
}

pub fn draw(self: *Grid, _: f64) void {
    const objects: [1]object.object = .{self.grid};
    rhi.drawObjects(objects[0..]);
}

pub fn deleteGrid(self: *Grid) void {
    var objects: [1]object.object = .{self.grid};
    rhi.deleteObjects(objects[0..]);
    self.grid = undefined;
}

pub fn program(self: *Grid) u32 {
    return self.grid.parallelepiped.mesh.program;
}

fn renderGrid(self: *Grid) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, grid_vertex_shader, grid_frag_shader);
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
                        self.grid_y_translate[0],
                        self.grid_y_translate[1],
                        self.grid_y_translate[2] + grid_pos * grid_increments,
                    ),
                );
                m = math.matrix.transformMatrix(m, math.matrix.rotationZ(std.math.pi / 2.0));
                m = math.matrix.transformMatrix(m, math.matrix.scale(
                    self.grid_y_scale[0],
                    self.grid_y_scale[1],
                    self.grid_y_scale[2],
                ));
            } else {
                m = math.matrix.transformMatrix(
                    m,
                    math.matrix.translate(
                        self.grid_z_translate[0],
                        self.grid_z_translate[1] + grid_pos * grid_increments,
                        self.grid_z_translate[2],
                    ),
                );
                m = math.matrix.transformMatrix(m, math.matrix.rotationX(self.grid_z_rot[0]));
                m = math.matrix.transformMatrix(m, math.matrix.rotationY(self.grid_z_rot[1]));
                m = math.matrix.transformMatrix(m, math.matrix.rotationZ(self.grid_z_rot[2]));
                m = math.matrix.transformMatrix(m, math.matrix.scale(
                    self.grid_z_scale[0],
                    self.grid_z_scale[1],
                    self.grid_z_scale[2],
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
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.grid = grid;
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const object = @import("../../object/object.zig");
