ui_state: vma_ui,
vectors: [100]object.object = undefined,
num_vectors: usize = 0,

const MathVectorArithmetic = @This();

pub fn init(allocator: std.mem.Allocator) *MathVectorArithmetic {
    const p = allocator.create(MathVectorArithmetic) catch @panic("OOM");
    p.* = .{
        .ui_state = .{},
    };
    return p;
}

pub fn deinit(self: *MathVectorArithmetic, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *MathVectorArithmetic, _: f64) void {
    if (self.num_vectors != self.ui_state.num_vectors) {
        if (self.ui_state.num_vectors == 0) {
            self.clearVectors();
        } else {
            self.addVector();
        }
    }
    self.ui_state.draw();
}

fn addVector(self: *MathVectorArithmetic) void {
    std.debug.print("added a vector yo\n", .{});
    self.num_vectors += 1;
}

fn clearVectors(self: *MathVectorArithmetic) void {
    std.debug.print("clear vectors\n", .{});
    self.num_vectors = 0;
}

const std = @import("std");
const vma_ui = @import("math_vector_arithmetic_ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
