mesh: rhi.mesh,

const Sphere = @This();
const num_quads = 10000;
const num_vertices: usize = num_quads * 4;
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

    var pi: usize = 0;
    var ii: usize = 0;

    const x_angle_delta: f32 = std.math.pi * 0.02;

    while (x_axis_angle < 2 * std.math.pi) : (x_axis_angle += x_angle_delta) {
        var y_axis_angle: f32 = 0;
        const y_angle_delta: f32 = x_angle_delta;
        while (y_axis_angle <= 2 * std.math.pi) : (y_axis_angle += y_angle_delta) {
            const tr_coordinates: math.vector.vec3 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                1.0,
                y_axis_angle,
                x_axis_angle,
            });
            const br_coordinates: math.vector.vec3 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                1.0,
                y_axis_angle,
                x_axis_angle + x_angle_delta,
            });
            const tl_coordinates: math.vector.vec3 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                1.0,
                y_axis_angle + y_angle_delta,
                x_axis_angle,
            });
            const bl_coordinates: math.vector.vec3 = math.rotation.sphericalCoordinatesToCartesian3D(math.vector.vec3, .{
                1.0,
                y_axis_angle + y_angle_delta,
                x_axis_angle + x_angle_delta,
            });
            const tr = pi;
            const br = pi + 1;
            const tl = pi + 2;
            const bl = pi + 3;
            attribute_data[tr] = .{ .position = tr_coordinates, .normals = math.vector.normalize(tr_coordinates) };
            attribute_data[br] = .{ .position = br_coordinates, .normals = math.vector.normalize(br_coordinates) };
            attribute_data[tl] = .{ .position = tl_coordinates, .normals = math.vector.normalize(tl_coordinates) };
            attribute_data[bl] = .{ .position = bl_coordinates, .normals = math.vector.normalize(bl_coordinates) };
            // Triangle 1
            indices[ii] = @intCast(tl);
            indices[ii + 1] = @intCast(bl);
            indices[ii + 2] = @intCast(br);
            // Triangle 2
            indices[ii + 3] = @intCast(tr);
            indices[ii + 4] = @intCast(tl);
            indices[ii + 5] = @intCast(br);
            pi += 4;
            ii += 6;
        }
    }
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
