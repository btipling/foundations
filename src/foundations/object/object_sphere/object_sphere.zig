mesh: rhi.mesh,

const Sphere = @This();
const num_vertices: usize = 10;
const num_indices: usize = (num_vertices - 2) * 3;
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
    // start is the very top of the sphere from which this code begins the desend to generate the vertices around the sphere
    const start: [3]f32 = .{ sphere_scale, 0, 0 };
    // Store the initial position and index
    p[0] = start;
    indices[0] = 0;
    // Tack positions and indicies, accounting for start
    var next_vertices_index: u32 = 1;
    var current_p_index: usize = 1;
    var current_i_index: usize = 1;
    // The first circle begins at 0.1 less than unit length
    var x_to_o: f32 = 0.9;
    const x_decrements: f32 = 0.1;
    // The width of the triangle base around the axis.
    const x_axis_angle: f32 = 2 * std.math.pi / 100.0;

    //***
    // INDEX MANGEMENT
    // prev_vertex_index tracks the EBO index of the last vertex added to positions.
    var prev_vertex_index: u32 = 0;
    //***

    // Every iteration around a circle starts at z positive, and moves counter clockwise around the x axis.
    const current_vector: math.vector.vec3 = .{ x_to_o, 0, 0 };
    while (x_to_o > 0.0) : (x_to_o -= x_decrements) {
        //*********
        // BEGIN NEXT CIRCLE AROUND SPHERE
        // Begins with per circle set up.
        //*********

        //***
        // DETERMINE CIRCLE PROPERTIES
        //****
        // Get current circle's radius based on current x to origin distance
        const current_slice_radius = 2 * std.math.pi * (1.0 - x_to_o);
        // Calculate the number of points to generate for this circle.
        const num_points: usize = @intFromFloat(@floor(current_slice_radius / x_axis_angle));
        // Calculate the angle around the x axis between each point.
        const slice_angle: f32 = (2 * std.math.pi) / @as(f32, @floatFromInt(num_points));
        std.debug.print("num_points: {d}\n", .{num_points});

        // Begin iterating around circle to generate the points.
        var i: usize = 0;
        while (i < num_points) : (i += 1) {
            const current_x_axis_angle: f32 = slice_angle * @as(f32, @floatFromInt(i));
            std.debug.print("current_x_axis_angle: {d}\n", .{math.rotation.radiansToDegrees(current_x_axis_angle)});
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
            // by taking the vector at y = 0, z = 1 and the current angle(it actually works off of x instead of z - I just fix that)
            // and then translating it to the current x with just vector addition (x, 0, 0) + (0, y, z) = new position

            const new_coordinates: [2]f32 = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{
                0.5,
                current_x_axis_angle,
            });
            p[current_p_index] = math.vector.mul(sphere_scale, math.vector.add(
                current_vector,
                @as(math.vector.vec3, .{
                    0,
                    new_coordinates[1],
                    new_coordinates[0],
                }),
            ));
            current_p_index += 1;

            // Each circle adds two points before we start incrementing indices on a per new vertex basis
            if (i >= 2) {
                // Having added a previous triangle and need to create full triangles for each point add the start and previous point's index
                // Add start index to ebo to create the tip of the triangle
                if (math.float.equal(x_to_o, 0.9, 0.0001)) {
                    // Creating our first circle, so just use the first index for triangle.
                    indices[current_i_index] = 0;
                }
                current_i_index += 1;
                // Add the previously created point in the prior loop to create the right most edge of the triangle
                indices[current_i_index] = prev_vertex_index;
                current_i_index += 1;
            }
            // Store the ebo index for the point just created.
            prev_vertex_index = next_vertices_index;

            // Add an ebo index for the point just created to finish the triangle.
            indices[current_i_index] = next_vertices_index;
            next_vertices_index += 1;
            current_i_index += 1;

            if (current_p_index >= num_vertices) break;
            if (current_i_index >= num_indices) break;
        }
        if (current_p_index >= num_vertices) break;
        if (current_i_index >= num_indices) break;
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
