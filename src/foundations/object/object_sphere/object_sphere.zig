mesh: rhi.mesh,

const Sphere = @This();
const num_vertices: usize = 6560;
const num_indices: usize = 19433;
const sphere_scale: f32 = 0.75;
const angle_div: f32 = 80.0;

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
            .wire_mesh = false,
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

    // The width of the triangle base around the axis.
    const angle_delta: f32 = 2 * std.math.pi / angle_div;
    var y_axis_angle: f32 = angle_delta;
    _ = &y_axis_angle;

    var current_p_index: usize = 0;
    var current_i_index: usize = 0;
    var current_level: f32 = 1.0;

    {
        const start: [3]f32 = .{ sphere_scale, 0, 0 };
        p[0] = start;
        indices[0] = 0;
        current_p_index += 1;
        current_i_index += 1;

        var prev_bot_vertex_index: u32 = 0;
        var i: usize = 0;
        var x_angle: f32 = 0;
        while (x_angle < 2 * std.math.pi) : (x_angle += angle_delta) {
            const new_coordinates: [3]f32 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                1.0,
                y_axis_angle,
                x_angle,
            });
            p[current_p_index] = math.vector.mul(
                sphere_scale,
                @as(math.vector.vec3, .{
                    new_coordinates[2],
                    new_coordinates[1],
                    new_coordinates[0],
                }),
            );
            if (i >= 2) {
                indices[current_i_index] = 0;
                current_i_index += 1;
                indices[current_i_index] = prev_bot_vertex_index;
                current_i_index += 1;
            }
            const bot_index: u32 = @intCast(current_p_index);
            indices[current_i_index] = bot_index;
            prev_bot_vertex_index = bot_index;
            current_p_index += 1;
            current_i_index += 1;
            i += 1;
        }
    }

    // Generate the bands around the rest of the bottom half of the sphere. It's different. It doesn't use a shared point at the
    // top of every triangle.
    // y_axis_angle += angle_delta;
    const first_ya = y_axis_angle;
    while (y_axis_angle < 2 * std.math.pi) : (y_axis_angle += angle_delta) {
        current_level += 1;
        var current_top_vertex_index: u32 = 0;
        var current_bot_vertex_index: u32 = 0;
        var x_angle: f32 = 0;
        {
            // Get the first top coordinate
            const new_coordinates: [3]f32 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                1.0,
                y_axis_angle,
                x_angle,
            });
            p[current_p_index] = math.vector.mul(
                sphere_scale,
                @as(math.vector.vec3, .{
                    new_coordinates[2],
                    new_coordinates[1],
                    new_coordinates[0],
                }),
            );
            const top_index: u32 = @intCast(current_p_index);
            indices[current_i_index] = top_index;
            current_top_vertex_index = top_index;
            current_p_index += 1;
            current_i_index += 1;
            if (y_axis_angle != first_ya) {
                indices[current_i_index] = top_index;
                current_i_index += 1;
            }
        }

        {
            // Get the first bottom coordinate
            const new_coordinates: [3]f32 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                1.0,
                y_axis_angle + angle_delta,
                x_angle,
            });
            p[current_p_index] = math.vector.mul(
                sphere_scale,
                @as(math.vector.vec3, .{
                    new_coordinates[2],
                    new_coordinates[1],
                    new_coordinates[0],
                }),
            );
            const bot_index: u32 = @intCast(current_p_index);
            indices[current_i_index] = bot_index;
            current_p_index += 1;
            current_i_index += 1;
        }

        var i: usize = 0;
        x_angle += angle_delta;
        const stop_at = (2 * std.math.pi) + angle_delta;
        while (x_angle <= stop_at) : (x_angle += angle_delta) {
            if (@mod(i, 2) == 0) {
                // Get the second bottom coordinate to form the first triangle
                const new_coordinates: [3]f32 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                    1.0,
                    y_axis_angle + angle_delta,
                    x_angle,
                });
                p[current_p_index] = math.vector.mul(
                    sphere_scale,
                    @as(math.vector.vec3, .{
                        new_coordinates[2],
                        new_coordinates[1],
                        new_coordinates[0],
                    }),
                );
                const bot_index: u32 = @intCast(current_p_index);
                indices[current_i_index] = bot_index;
                current_bot_vertex_index = bot_index;
                current_p_index += 1;
                current_i_index += 1;
            } else {
                const new_coordinates: [3]f32 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                    1.0,
                    y_axis_angle,
                    x_angle,
                });
                p[current_p_index] = math.vector.mul(
                    sphere_scale,
                    @as(math.vector.vec3, .{
                        new_coordinates[2],
                        new_coordinates[1],
                        new_coordinates[0],
                    }),
                );
                const top_index: u32 = @intCast(current_p_index);
                indices[current_i_index] = top_index;
                current_top_vertex_index = top_index;
                current_p_index += 1;
                current_i_index += 1;
            }

            {
                // add top index again
                indices[current_i_index] = current_top_vertex_index;
                current_i_index += 1;
                // Add bot index again
                indices[current_i_index] = current_bot_vertex_index;
                current_i_index += 1;
            }
            i += 1;
        }
    }
    std.debug.print("vertices: {d} indices: {d}\n", .{ current_p_index, current_i_index });
    return .{ .positions = p, .indices = indices };
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
