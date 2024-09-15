ui_state: vma_ui,
objects: [200]object.object = undefined,
num_objects: usize = 0,
num_vectors: usize = 0,
ctx: scenes.SceneContext,
ortho_persp: math.matrix,

const MathVectorArithmetic = @This();

const vertex_shader: []const u8 = @embedFile("mva_vertex.glsl");
const frag_shader: []const u8 = @embedFile("mva_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Vector Math",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *MathVectorArithmetic {
    const p = allocator.create(MathVectorArithmetic) catch @panic("OOM");
    const ortho_persp = math.matrix.orthographicProjection(
        0,
        9,
        0,
        6,
        ctx.cfg.near,
        ctx.cfg.far,
    );
    p.* = .{
        .ui_state = vma_ui.init(),
        .ctx = ctx,
        .ortho_persp = ortho_persp,
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
    rhi.drawObjects(self.objects[0..self.num_objects]);
    self.ui_state.draw();
}

fn addVector(self: *MathVectorArithmetic) void {
    const vec: math.vector.vec3 = self.ui_state.vectors[self.num_vectors].vector;
    const origin: math.vector.vec3 = self.ui_state.vectors[self.num_vectors].origin;
    var triangle_positions: [3][3]f32 = undefined;
    var triangle_colors: [3][4]f32 = undefined;
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
        const pv: math.vector.vec3 = object.Triangle.default_positions[pi];
        const current_angle = math.rotation.cartesian2DToPolarCoordinates(pv);
        const new_angle = current_angle[1] + rotation;
        const pm = math.vector.magnitude(pv);
        const p_r = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec3, .{
            1,
            new_angle,
        });
        var nv = math.vector.mul(pm, p_r);
        nv = math.vector.add(nv, origin);
        const v = math.vector.add(nv, vec);
        triangle_positions[pi] = math.vector.vec4ToVec3(math.matrix.transformVector(self.ortho_persp, math.vector.vec3ToVec4Point(v)));
        triangle_colors[pi][0] = 0.75 + 0.25 * (rotation / (std.math.pi * 2));
        triangle_colors[pi][1] = 0.75 + 0.25 * v[0];
        triangle_colors[pi][2] = 0.75 + 0.25 * v[1];
        triangle_colors[pi][3] = 1.0;
    }

    self.objects[self.num_objects] = .{
        .triangle = object.Triangle.init(
            vertex_shader,
            frag_shader,
            triangle_positions,
            triangle_colors,
            object.Triangle.default_normals,
        ),
    };
    self.num_objects += 1;

    var quad_positions: [6][3]f32 = undefined;
    var quad_colors: [6][4]f32 = undefined;

    pi = 0;
    while (pi < 6) : (pi += 1) {
        var pv: math.vector.vec3 = object.Quad.default_deprecated_positions[pi];
        pv = math.vector.mul(0.01, pv);
        const do_sum = math.float.equal(pv[1], 0.01, 0.001);
        const current_angle = math.rotation.cartesian2DToPolarCoordinates(pv);
        const new_angle = current_angle[1] + rotation;
        const pm = math.vector.magnitude(pv);
        const p_r = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec3, .{
            1,
            new_angle,
        });
        var nv = math.vector.mul(pm, p_r);
        nv = math.vector.add(nv, origin);
        if (do_sum) nv = math.vector.add(nv, vec);
        const v = nv;
        quad_positions[pi] = math.vector.vec4ToVec3(math.matrix.transformVector(self.ortho_persp, math.vector.vec3ToVec4Point(v)));
        quad_colors[pi][0] = 0.75 + 0.25 * (rotation / (std.math.pi * 2));
        quad_colors[pi][1] = 0.75 + 0.25 * v[0];
        quad_colors[pi][2] = 0.75 + 0.25 * v[1];
        quad_colors[pi][3] = 1.0;
    }

    self.objects[self.num_objects] = .{
        .quad = object.Quad.init(
            vertex_shader,
            frag_shader,
            quad_positions,
            quad_colors,
        ),
    };
    self.num_objects += 1;
    self.num_vectors += 1;
}

fn clearVectors(self: *MathVectorArithmetic) void {
    rhi.deleteObjects(self.objects[0..self.num_objects]);
    self.num_vectors = 0;
    self.num_objects = 0;
}

const std = @import("std");
const vma_ui = @import("MathVectorArithmeticUI.zig");
const rhi = @import("../../../rhi/rhi.zig");
const object = @import("../../../object/object.zig");
const math = @import("../../../math/math.zig");
const ui = @import("../../../ui/ui.zig");
const scenes = @import("../../scenes.zig");
