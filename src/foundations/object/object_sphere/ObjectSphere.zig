mesh: rhi.mesh,

const Sphere = @This();
const angle_delta: f32 = std.math.pi * 0.02;
const grid_dimension: usize = @intFromFloat((2.0 * std.math.pi) / angle_delta);
const num_vertices: usize = grid_dimension * grid_dimension;
const quad_dimensions = grid_dimension - 1;
const num_quads = quad_dimensions * quad_dimensions;
const num_indices: usize = num_quads * 6;
const sphere_scale: f32 = 0.75;

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    wireframe: bool,
) Sphere {
    var d = data();

    const vao_buf = rhi.attachInstancedBuffer(d.attribute_data[0..], instance_data);
    const ebo = rhi.initEBO(@ptrCast(d.indices[0..]), vao_buf.vao);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .wire_mesh = wireframe,
            // TODO: this code has a degenerate triangle, cull face bug at when i % grid_dimension == 0
            // I have to do the math on paper to figure this out.
            .cull = false,
            .instance_type = .{
                .instanced = .{
                    .index_count = num_indices,
                    .instances_count = instance_data.len,
                    .ebo = ebo,
                    .primitive = c.GL_TRIANGLES,
                    .format = c.GL_UNSIGNED_INT,
                },
            },
        },
    };
}

fn data() struct { attribute_data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var attribute_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;
    var x_axis_angle: f32 = 0;

    const x_angle_delta: f32 = angle_delta;

    var positions: [num_vertices]math.vector.vec3 = undefined;
    {
        var pi: usize = 0;
        while (x_axis_angle < 2 * std.math.pi) : (x_axis_angle += x_angle_delta) {
            const y_angle_delta: f32 = x_angle_delta;
            var y_axis_angle: f32 = 0;
            while (y_axis_angle < 2 * std.math.pi) : (y_axis_angle += y_angle_delta) {
                positions[pi] = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                    1.0,
                    y_axis_angle,
                    x_axis_angle,
                });
                pi += 1;
            }
        }
    }

    {
        var ii: usize = 0;
        var last: usize = 0;
        var fl: usize = 0;
        var sl: usize = 0;
        for (0..quad_dimensions) |_| {
            for (0..quad_dimensions) |_| {
                const i = fl + sl;
                const tr = i + 1;
                const br = i + grid_dimension + 1;
                const tl = i;
                var bl = i + grid_dimension;
                bl += 0;

                addVertexData(positions, indices[0..], attribute_data[0..], tr, br, tl, bl, ii);

                ii += 6;
                last = br;
                fl += 1;
            }
            sl += 1;
        }
    }

    return .{ .attribute_data = attribute_data, .indices = indices };
}

fn addVertexData(
    positions: [num_vertices]math.vector.vec3,
    indices: []u32,
    attribute_data: []rhi.attributeData,
    tr: usize,
    br: usize,
    tl: usize,
    bl: usize,
    ii: usize,
) void {
    const tr_coordinates = positions[tr];
    const br_coordinates = positions[br];
    const tl_coordinates = positions[tl];
    const bl_coordinates = positions[bl];
    attribute_data[tr] = .{ .position = tr_coordinates, .normals = math.vector.normalize(tr_coordinates) };
    attribute_data[br] = .{ .position = br_coordinates, .normals = math.vector.normalize(br_coordinates) };
    attribute_data[tl] = .{ .position = tl_coordinates, .normals = math.vector.normalize(tl_coordinates) };
    attribute_data[bl] = .{ .position = bl_coordinates, .normals = math.vector.normalize(bl_coordinates) };
    // Triangle 1
    indices[ii] = @intCast(tl);
    indices[ii + 1] = @intCast(br);
    indices[ii + 2] = @intCast(tr);
    // Triangle 2
    indices[ii + 3] = @intCast(tl);
    indices[ii + 4] = @intCast(bl);
    indices[ii + 5] = @intCast(br);
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
