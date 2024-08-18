mesh: rhi.mesh,

const Sphere = @This();
const angle_delta: f32 = std.math.pi * 0.2;
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
    std.debug.print("angle_delta: ({d}) grid_dim: ({d}) num_quads: ({d}) num_vertices: ({d}, num_indices: ({d}))\n", .{
        angle_delta,
        grid_dimension,
        num_quads,
        num_vertices,
        num_indices,
    });

    var positions: [num_vertices]math.vector.vec3 = undefined;
    {
        var pi: usize = 0;
        while (x_axis_angle < 2 * std.math.pi) : (x_axis_angle += x_angle_delta) {
            var y_axis_angle: f32 = 0;
            const y_angle_delta: f32 = x_angle_delta;
            while (y_axis_angle < 2 * std.math.pi) : (y_axis_angle += y_angle_delta) {
                positions[pi] = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                    1.0,
                    y_axis_angle,
                    x_axis_angle,
                });
                std.debug.print("pi ({d}) y_angle: ({d}) x_angle: ({d})\n", .{
                    pi,
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
        for (0..quad_dimensions) |qi| {
            for (0..quad_dimensions) |_| {
                const i = fl + sl;
                const tr = i + 1;
                const br = i + grid_dimension + 1;
                const tl = i;
                var bl = i + grid_dimension;
                bl += 0;
                _ = qi;
                // if (qi == 0) bl += grid_dimension;
                // std.debug.print("qi: ({d}), qj: ({d}) i: ({d}) quad_dimensions: ({d})\n", .{
                //     qi,
                //     qj,
                //     i,
                //     quad_dimensions,
                // });
                // std.debug.print("tr: ({d}) br: ({d}) tl: ({d}) bl: ({d})\n", .{
                //     tr,
                //     br,
                //     tl,
                //     bl,
                // });

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
                ii += 6;
                last = br;
                fl += 1;
            }
            sl += 1;
        }
        // // Stich up the grid end to end
        // for (0..quad_dimensions) |qdi| {
        //     const qi = (qdi * grid_dimension) + quad_dimensions;
        //     const tr = qi - quad_dimensions;
        //     const br = qi + 1;
        //     const tl = qi;
        //     const bl = qi + grid_dimension;

        //     const tr_coordinates = positions[tr];
        //     const br_coordinates = positions[br];
        //     const tl_coordinates = positions[tl];
        //     const bl_coordinates = positions[bl];
        //     attribute_data[tr] = .{ .position = tr_coordinates, .normals = math.vector.normalize(tr_coordinates) };
        //     attribute_data[br] = .{ .position = br_coordinates, .normals = math.vector.normalize(br_coordinates) };
        //     attribute_data[tl] = .{ .position = tl_coordinates, .normals = math.vector.normalize(tl_coordinates) };
        //     attribute_data[bl] = .{ .position = bl_coordinates, .normals = math.vector.normalize(bl_coordinates) };
        //     // Triangle 1
        //     indices[ii] = @intCast(tl);
        //     indices[ii + 1] = @intCast(bl);
        //     indices[ii + 2] = @intCast(br);
        //     // Triangle 2
        //     indices[ii + 3] = @intCast(tr);
        //     indices[ii + 4] = @intCast(tl);
        //     indices[ii + 5] = @intCast(br);
        //     ii += 6;
        //     last = br;
        // }
        std.debug.print("last vertex: ({d}) last index: ({d})\n", .{ last, ii });
    }
    // std.debug.print("\nfirst three indexes: ({d}, {d}, {d})\n", .{
    //     indices[0],
    //     indices[1],
    //     indices[2],
    // });
    // std.debug.print("\tp0: ({d}, {d}, {d})\n", .{
    //     attribute_data[@intCast(indices[0])].position[0],
    //     attribute_data[@intCast(indices[0])].position[1],
    //     attribute_data[@intCast(indices[0])].position[2],
    // });
    // std.debug.print("\tp1: ({d}, {d}, {d})\n", .{
    //     attribute_data[@intCast(indices[1])].position[0],
    //     attribute_data[@intCast(indices[1])].position[1],
    //     attribute_data[@intCast(indices[1])].position[2],
    // });
    // std.debug.print("\tp2: ({d}, {d}, {d})\n", .{
    //     attribute_data[@intCast(indices[2])].position[0],
    //     attribute_data[@intCast(indices[2])].position[1],
    //     attribute_data[@intCast(indices[2])].position[2],
    // });
    // std.debug.print("next three indexes: ({d}, {d}, {d})\n", .{
    //     indices[3],
    //     indices[4],
    //     indices[5],
    // });
    // std.debug.print("\tp0: ({d}, {d}, {d})\n", .{
    //     attribute_data[@intCast(indices[3])].position[0],
    //     attribute_data[@intCast(indices[3])].position[1],
    //     attribute_data[@intCast(indices[3])].position[2],
    // });
    // std.debug.print("\tp1: ({d}, {d}, {d})\n", .{
    //     attribute_data[@intCast(indices[4])].position[0],
    //     attribute_data[@intCast(indices[4])].position[1],
    //     attribute_data[@intCast(indices[4])].position[2],
    // });
    // std.debug.print("\tp2: ({d}, {d}, {d})\n", .{
    //     attribute_data[@intCast(indices[5])].position[0],
    //     attribute_data[@intCast(indices[5])].position[1],
    //     attribute_data[@intCast(indices[5])].position[2],
    // });
    return .{ .attribute_data = attribute_data, .indices = indices };
}

fn addVertexData(attribute_data: *[num_vertices]rhi.attributeData, new_coordinates: [3]f32, i: usize) void {
    {
        const p = math.vector.mul(
            sphere_scale,
            @as(math.vector.vec3, .{
                new_coordinates[2],
                new_coordinates[1],
                new_coordinates[0],
            }),
        );
        attribute_data[i] = .{
            .position = p,
            .normals = math.vector.normalize(p),
        };
    }
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
