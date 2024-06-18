ui_state: vma_ui,
vectors: [100]object.object = undefined,
num_vectors: usize = 0,

const MathVectorArithmetic = @This();

const vertex_shader: []const u8 = @embedFile("mva_vertex.glsl");
const frag_shader: []const u8 = @embedFile("mva_frag.glsl");

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
    rhi.drawObjects(self.vectors[0..self.num_vectors]);
    self.ui_state.draw();
}

const xy_pos: math.vector.vec3 = .{ 1.0, 1.0, 0.0 };

fn addVector(self: *MathVectorArithmetic) void {
    const vec: math.vector.vec3 = self.ui_state.vectors[self.num_vectors];
    var positions: [3][3]f32 = undefined;
    var pi: usize = 0;
    const rotation = math.vector.angleBetweenVectors(xy_pos, vec);
    while (pi < 3) : (pi += 1) {
        const pv: math.vector.vec3 = object.triangle.default_positions[pi];
        // const nv = math.vector.add(pv, vec);
        const current_angle = math.vector.angleBetweenVectors(xy_pos, pv);
        const new_angle = current_angle + rotation;
        // const pm = math.vector.magnitude(pv);
        const p_r = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
            1,
            math.rotation.degreesToRadians(90.0),
            new_angle,
        });
        const v = p_r; // math.vector.add(pv, p_r);
        positions[pi] = v;
    }

    self.vectors[self.num_vectors] = .{
        .triangle = object.triangle.init(
            vertex_shader,
            frag_shader,
            positions,
            object.triangle.default_colors,
        ),
    };
    self.num_vectors += 1;
}

fn clearVectors(self: *MathVectorArithmetic) void {
    rhi.deleteObjects(self.vectors[0..self.num_vectors]);
    self.num_vectors = 0;
}

const std = @import("std");
const vma_ui = @import("math_vector_arithmetic_ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
