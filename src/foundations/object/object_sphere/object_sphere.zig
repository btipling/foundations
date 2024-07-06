mesh: rhi.mesh,

const Sphere = @This();
// const num_vertices: usize = 883;
// const num_indices: usize = 1755;
const num_vertices: usize = 14;
const num_indices: usize = 30;
const sphere_scale: f32 = 1.0;

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
            .wire_mesh = true,
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
    // p is an array of vertices to use for the triangles that form the sphere
    var p: [num_vertices][3]f32 = undefined;
    // indices are the indices that are used for the EBO to generate the triangles that form the sphere
    var indices: [num_indices]u32 = undefined;

    // The first circle begins at 0.1 less than unit length
    var x_to_o_top: f32 = 1.0;
    var x_to_o_bot: f32 = 0.9;
    const x_decrements: f32 = 0.1;
    // The width of the triangle base around the axis.
    const x_axis_angle: f32 = 2 * std.math.pi / 100.0;

    var next_vertices_index: u32 = 0;
    // var prev_top_index: u32 = 0;
    var current_p_index: usize = 0;
    var current_i_index: usize = 0;
    var prev_vertex_index: u32 = 0;

    {
        // Generate the top of the circle that just has one shared point at top.
        const current_bot_vector: math.vector.vec3 = .{ x_to_o_bot, 0, 0 };

        const current_bot_slice_radius = 2 * std.math.pi * (1.0 - x_to_o_bot);
        const num_points: usize = @intFromFloat(@floor(current_bot_slice_radius / x_axis_angle));
        const slice_angle: f32 = (2 * std.math.pi) / @as(f32, @floatFromInt(num_points));
        std.debug.print("num_points: {d}\n", .{num_points});

        const start: [3]f32 = .{ sphere_scale, 0, 0 };
        p[0] = start;
        indices[0] = 0;
        next_vertices_index += 1;
        current_p_index += 1;
        current_i_index += 1;

        var i: usize = 0;
        while (i < num_points) : (i += 1) {
            const current_x_axis_angle: f32 = slice_angle * @as(f32, @floatFromInt(i));
            std.debug.print("current_bot_x_axis_angle: {d}\n", .{math.rotation.radiansToDegrees(current_x_axis_angle)});

            const new_coordinates: [2]f32 = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{
                1.0 - x_to_o_bot,
                current_x_axis_angle,
            });
            p[current_p_index] = math.vector.mul(sphere_scale, math.vector.add(
                current_bot_vector,
                @as(math.vector.vec3, .{
                    0,
                    new_coordinates[1],
                    new_coordinates[0],
                }),
            ));
            current_p_index += 1;
            if (i >= 2) {
                indices[current_i_index] = 0;
                current_i_index += 1;
                indices[current_i_index] = prev_vertex_index;
                current_i_index += 1;
            }
            prev_vertex_index = next_vertices_index;

            indices[current_i_index] = next_vertices_index;
            next_vertices_index += 1;
            current_i_index += 1;
        }
    }

    x_to_o_top -= x_decrements;
    x_to_o_bot -= x_decrements;
    std.debug.print("current_p_index: {d}\n", .{current_p_index});

    // Generate the bands around the rest of the bottom half of the sphere. It's different. It doesn't use a shared point at the
    // top of every triangle.
    {
        const current_top_vector: math.vector.vec3 = .{ x_to_o_top, 0, 0 };
        const current_bot_vector: math.vector.vec3 = .{ x_to_o_bot, 0, 0 };

        const current_bot_slice_radius = 2 * std.math.pi * (1.0 - x_to_o_bot);
        // Calculate the number of points to generate for this circle.
        const num_points: usize = @intFromFloat(@floor(current_bot_slice_radius / x_axis_angle));
        // Calculate the angle around the x axis between each point for both the bottom and top circles.
        const slice_angle: f32 = (2 * std.math.pi) / @as(f32, @floatFromInt(num_points));
        std.debug.print("num_points: {d}\n", .{num_points});

        {
            // Get the first top coordinate
            const new_coordinates: [2]f32 = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{
                1.0 - x_to_o_top,
                0,
            });
            p[current_p_index] = math.vector.mul(sphere_scale, math.vector.add(
                current_top_vector,
                @as(math.vector.vec3, .{
                    0,
                    new_coordinates[1],
                    new_coordinates[0],
                }),
            ));
            indices[current_i_index] = @intCast(current_p_index);
            current_p_index += 1;
            current_i_index += 1;
        }

        {
            // Get the first bottom coordinate
            const new_coordinates: [2]f32 = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{
                1.0 - x_to_o_bot,
                0,
            });
            p[current_p_index] = math.vector.mul(sphere_scale, math.vector.add(
                current_bot_vector,
                @as(math.vector.vec3, .{
                    0,
                    new_coordinates[1],
                    new_coordinates[0],
                }),
            ));
            indices[current_i_index] = @intCast(current_p_index);
            current_p_index += 1;
            current_i_index += 1;
        }

        {
            // Get the second bottom coordinate to form the first triangle
            const new_coordinates: [2]f32 = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{
                1.0 - x_to_o_bot,
                slice_angle,
            });
            p[current_p_index] = math.vector.mul(sphere_scale, math.vector.add(
                current_bot_vector,
                @as(math.vector.vec3, .{
                    0,
                    new_coordinates[1],
                    new_coordinates[0],
                }),
            ));
            indices[current_i_index] = @intCast(current_p_index);
            current_p_index += 1;
            current_i_index += 1;
        }
    }

    std.debug.print("points: \n", .{});
    for (p, 0..) |v, i| {
        std.debug.print("\ti:{d} ({d}, {d}, {d})\n", .{
            i,
            v[0],
            v[1],
            v[2],
        });
    }
    std.debug.print("\nindices: \n", .{});
    for (indices, 0..) |v, i| {
        std.debug.print("\ti:{d} index: {d}\n", .{ i, v });
    }
    return .{ .positions = p, .indices = indices };
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
