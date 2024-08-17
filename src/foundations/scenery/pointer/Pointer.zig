allocator: std.mem.Allocator,
cone: object.object = undefined,
cylinder: object.object = undefined,

const Pointer = @This();
pub const mvp_uniform_name: []const u8 = "f_mvp";

const pointer_vertex_shader: []const u8 = @embedFile("pointer_vertex.glsl");
const pointer_frag_shader: []const u8 = @embedFile("pointer_frag.glsl");

pub fn init(allocator: std.mem.Allocator) *Pointer {
    const pointer = allocator.create(Pointer) catch @panic("OOM");
    errdefer allocator.destroy(pointer);

    pointer.* = .{
        .allocator = allocator,
    };
    pointer.renderCylinder();
    pointer.renderCone();
    return pointer;
}

pub fn deinit(self: *Pointer) void {
    self.deletePointer();
    self.allocator.destroy(self);
}

pub fn draw(self: *Pointer, _: f64) void {
    const objects: [2]object.object = .{ self.cylinder, self.cone };
    rhi.drawObjects(objects[0..]);
}

pub fn deletePointer(self: *Pointer) void {
    var objects: [2]object.object = .{ self.cylinder, self.cone };
    rhi.deleteObjects(objects[0..]);
    self.cylinder = undefined;
}

pub fn programs(self: *Pointer) [2]u32 {
    return .{ self.cylinder.cylinder.mesh.program, self.cone.cone.mesh.program };
}

pub fn renderCylinder(self: *Pointer) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, pointer_vertex_shader, pointer_frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(0, 0.3, 0));
    m = math.matrix.transformMatrix(m, math.matrix.scale(4, 1, 1));

    const i_data: rhi.instanceData = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 0.15, 0.15, 0.25, 1 },
    };
    i_datas[0] = i_data;
    const cylinder: object.object = .{
        .cylinder = object.Cylinder.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.cylinder = cylinder;
}

pub fn renderCone(self: *Pointer) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, pointer_vertex_shader, pointer_frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(3.85, 0, 0));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(0.5));

    const i_data: rhi.instanceData = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 0.15, 0.15, 0.25, 1 },
    };
    i_datas[0] = i_data;
    const cone: object.object = .{
        .cone = object.Cone.init(
            prog,
            i_datas[0..],
        ),
    };
    self.cone = cone;
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const object = @import("../../object/object.zig");
