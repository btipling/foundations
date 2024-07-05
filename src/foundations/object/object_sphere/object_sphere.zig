mesh: rhi.mesh,

const Sphere = @This();
const num_vertices: usize = 3;
const num_indices: usize = (num_vertices - 2) * 3;

pub fn init(
    program: u32,
    color: [4]f32,
) Sphere {
    const d = data();

    var rhi_data: [num_vertices]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < num_vertices) : (i += 1) {
        rhi_data[i] = .{
            .position = d.positions[i],
            .color = color,
        };
    }
    const vao_buf = rhi.attachBuffer(rhi_data[0..]);
    const ebo = rhi.initEBO(@ptrCast(d.indices[0..]), vao_buf.vao);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .instance_type = .{
                .element = .{
                    .count = num_indices,
                    .ebo = ebo,
                    .primitive = c.GL_TRIANGLES,
                    .format = c.GL_UNSIGNED_INT,
                },
            },
        },
    };
}

fn data() struct { positions: [num_vertices][3]f32, indices: [num_indices]u32 } {
    var p: [num_vertices][3]f32 = undefined;
    var indices: [num_indices]u32 = undefined;
    // origin:
    const start: [3]f32 = .{ 1.0, 0, 0 };
    p[0] = start;
    indices[0] = 0;
    var current_p_index = 1;
    var current_i_index = 1;
    var x_to_o: f32 = 0.9;
    const x_decrements: f32 = 0.1;
    const x_axis_angle: f32 = std.math.pi / 100.0;
    while (x_to_o > 0.0) : (x_to_o -= x_decrements) {
        const current_slice_radius = 2 * std.math.pi * (1.0 - x_to_o);
        const num_points = @floor(current_slice_radius / x_axis_angle);
        var i: usize = 0;
        while (i < num_points) : (i += 1) {
            // This is generating points of the outer edge of a circle that spans a line drawn around the surface of a sphere
            // on the (x)yz plane. This code makes successive iterations of such circles in segments descending down x.
            // The slices of cicles increase in diamater until it reaches the center of the sphere and is done
            // The points will acculate as vertices. Indices will be generated to specify the primitives to draw
            // triangles that will form a visual representation of the surface of the sphere.
            //
            // The distance between the points is uniform and is based on a fraction of the total sphere's circumference at its widest point
            // along the yz plane where x = 0.
            // As we're working with a unit sphere the radius of each circle is equal to 1 - (distance to current x)
            // Each circle will generate 2pi*radius/angle points.
            //
            // the angle across the x axis is the x_axis_angle
            // each point is derived by calculating a 2D polar coordinate from the center origin of the yz plane circle
            // and then translating it to the current x with just vector addition (x, 0, 0) + (0, y, z) = new position
            current_p_index += 1;
            current_i_index += 1;
            if (current_p_index > num_vertices) break;
            if (current_i_index > num_indices) break;
        }
    }
    return .{ .positions = p, .indices = indices };
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
