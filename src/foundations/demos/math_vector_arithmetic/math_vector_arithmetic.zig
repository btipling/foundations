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
    var pi: usize = 0;
    const rotation = math.rotation.cartesian3DToSphericalCoordinates(vec);
    std.debug.print("rotation? {d}\n", .{rotation});
    while (pi < 3) : (pi += 1) {
        const pv: math.vector.vec3 = object.triangle.default_positions[pi];
        const current_angle = math.rotation.cartesian3DToSphericalCoordinates(pv);
        const new_angle = current_angle[2] + rotation[2];
        std.debug.print("current_angle? {d} new_angle: {d}\n", .{
            std.math.radiansToDegrees(current_angle[2]),
            std.math.radiansToDegrees(new_angle),
        });
        const pm = math.vector.magnitude(pv);
        const p_r = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
            1,
            math.rotation.degreesToRadians(90.0),
            new_angle,
        });
        const nv = math.vector.mul(pm, p_r);
        const v = math.vector.add(nv, vec);
        std.debug.print("data: \n\tpv: ({d}, {d}, {d}) \n", .{
            pv[0],
            pv[1],
            pv[2],
        });
        std.debug.print("\tp_r: ({d}, {d}, {d}) \n", .{
            p_r[0],
            p_r[1],
            p_r[2],
        });
        std.debug.print("\tnv: ({d}, {d}, {d}) \n", .{
            nv[0],
            nv[1],
            nv[2],
        });
        std.debug.print("\tv: ({d}, {d}, {d})\n\n", .{
            v[0],
            v[1],
            v[2],
        });
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
