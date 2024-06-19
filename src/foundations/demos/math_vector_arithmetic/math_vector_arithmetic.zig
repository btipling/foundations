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

fn addVector(self: *MathVectorArithmetic) void {
    const vec: math.vector.vec3 = self.ui_state.vectors[self.num_vectors];
    var positions: [3][3]f32 = undefined;
    var colors: [3][4]f32 = undefined;
    var pi: usize = 0;
    const vec2DPC = math.rotation.cartesian2DToPolarCoordinates(vec);
    // polar coordinate 0° starts at x positive axis -> (i.e (1, 0) in unit circle), and moves positive in ° in the CCW direction
    // The triangle used here is by default pointing up, the actual starting polar coordinate position for rotation is 90°
    // in order to get the rotation for the given direction from vec we must account for triangle's +90° from vec's rotation by subtracting 90°
    // i.e. say new vec is pointing up and has a magnitude of 1, polar coordinates would say 90° CCW rotation would be needed to
    // go from (1, 0) to (0, 1) but the triangle is already pointing up so 90°-90° = no rotation needed, however if new vec is pointing along the
    // x axis (1, 0) this math would say to rotate by (0° - 90° = -90°), which is correct, to turn the upwards pointing trianglen CW to the x pos direction
    const rotation = vec2DPC[1] - math.rotation.degreesToRadians(90.0);
    while (pi < 3) : (pi += 1) {
        const pv: math.vector.vec3 = object.triangle.default_positions[pi];
        const current_angle = math.rotation.cartesian2DToPolarCoordinates(pv);
        const new_angle = current_angle[1] + rotation;
        const pm = math.vector.magnitude(pv);
        const p_r = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec3, .{
            1,
            new_angle,
        });
        const nv = math.vector.mul(pm, p_r);
        const v = math.vector.add(nv, vec);
        positions[pi] = v;
        colors[pi][0] = 0.75 + 0.25 * (rotation / (std.math.pi * 2));
        colors[pi][1] = 0.75 + 0.25 * v[0];
        colors[pi][2] = 0.75 + 0.25 * v[1];
        colors[pi][3] = 1.0;
    }

    self.vectors[self.num_vectors] = .{
        .triangle = object.triangle.init(
            vertex_shader,
            frag_shader,
            positions,
            colors,
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
