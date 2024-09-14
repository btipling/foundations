objects: [2]object.object = undefined,
ctx: scenes.SceneContext,

const LinearColorSpace = @This();

const vertex_shader: []const u8 = @embedFile("lcs_vertex.glsl");
const frag_shader: []const u8 = @embedFile("lcs_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .color,
        .name = "Linear Colorspace",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *LinearColorSpace {
    const p = allocator.create(LinearColorSpace) catch @panic("OOM");
    p.* = .{
        .ctx = ctx,
    };

    var triangle_positions: [3][3]f32 = undefined;
    const triangle_colors: [3][4]f32 = object.Triangle.default_colors;
    var rotation = math.rotation.degreesToRadians(32.0);
    var offset: math.vector.vec3 = .{ 0.3, 0.2, 0 };
    var pi: usize = 0;
    var magnitude: f32 = 12;
    while (pi < 3) : (pi += 1) {
        const pv: math.vector.vec3 = object.Triangle.default_positions[pi];
        const current_angle = math.rotation.cartesian2DToPolarCoordinates(pv);
        const new_angle = current_angle[1] + rotation;
        const pm = math.vector.magnitude(pv) * magnitude;
        const p_r = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec3, .{
            1,
            new_angle,
        });
        const nv = math.vector.mul(pm, p_r);
        const v = math.vector.add(offset, nv);
        triangle_positions[pi] = math.vector.vec4ToVec3(math.matrix.transformVector(
            math.matrix.orthographicProjection(0, 9, 0, 6, ctx.cfg.near, ctx.cfg.far),
            math.vector.vec3ToVec4Point(v),
        ));
    }
    const triangle1: object.object = .{
        .triangle = object.Triangle.init(
            vertex_shader,
            frag_shader,
            triangle_positions,
            triangle_colors,
            object.Triangle.default_normals,
        ),
    };
    p.objects[0] = triangle1;

    pi = 0;
    rotation = -45.0;
    offset = .{ -0.3, -0.2, 0 };
    magnitude = 10;
    while (pi < 3) : (pi += 1) {
        const pv: math.vector.vec3 = object.Triangle.default_positions[pi];
        const current_angle = math.rotation.cartesian2DToPolarCoordinates(pv);
        const new_angle = current_angle[1] + rotation;
        const pm = math.vector.magnitude(pv) * 10;
        const p_r = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec3, .{
            1,
            new_angle,
        });
        const nv = math.vector.mul(pm, p_r);
        const v = math.vector.add(offset, nv);
        triangle_positions[pi] = math.vector.vec4ToVec3(math.matrix.transformVector(
            math.matrix.orthographicProjection(0, 9, 0, 6, ctx.cfg.near, ctx.cfg.far),
            math.vector.vec3ToVec4Point(v),
        ));
    }
    var triangle2: object.object = .{
        .triangle = object.Triangle.init(
            vertex_shader,
            frag_shader,
            triangle_positions,
            triangle_colors,
            object.Triangle.default_normals,
        ),
    };
    triangle2.triangle.mesh.linear_colorspace = false;
    p.objects[1] = triangle2;

    return p;
}

pub fn deinit(self: *LinearColorSpace, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *LinearColorSpace, _: f64) void {
    rhi.drawObjects(self.objects[0..]);
}

const std = @import("std");
const rhi = @import("../../../rhi/rhi.zig");
const object = @import("../../../object/object.zig");
const math = @import("../../../math/math.zig");
const ui = @import("../../../ui/ui.zig");
const scenes = @import("../../scenes.zig");
