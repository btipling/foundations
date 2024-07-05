mesh: rhi.mesh,

const Triangle = @This();
const num_vertices: usize = 4;
const num_indices: usize = 6;

pub fn init(
    program: u32,
    color: [4]f32,
) Triangle {
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
    const origin: [3]f32 = .{ 0, 0, 0 };
    p[0] = origin;
    indices[0] = 0;
    var i: usize = 1;
    var last_index: u32 = 0;
    var indices_index: usize = 1;
    const angle: f32 = std.math.pi / 10.0;
    std.debug.print("starting angle: {d}\n", .{angle});
    var current_vector: [3]f32 = .{ 0, 0, 1 }; // start at z positive, move counter clockwise around the y axis
    while (i < num_vertices) : (i += 1) {
        if (i > 2) {
            // Complete triangle every with previous index and origin
            indices[indices_index] = 0;
            indices_index += 1;
            indices[indices_index] = last_index;
            indices_index += 1;
        }
        p[i] = current_vector;
        last_index += 1;
        indices[indices_index] = last_index;
        indices_index += 1;
        const r = math.rotation.cartesian2DToPolarCoordinates(@as(math.vector.vec2, .{ current_vector[2], current_vector[1] }));
        const new_coordinates: [2]f32 = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{
            r[0],
            angle * @as(f32, @floatFromInt(i)),
        });
        current_vector[2] = new_coordinates[0];
        current_vector[0] = new_coordinates[1];
    }
    for (indices, 0..) |v, ii| {
        std.debug.print("{d}: {d}\n", .{ ii, v });
    }
    for (p, 0..) |v, ii| {
        std.debug.print("{d}: {any}\n", .{ ii, v });
    }
    return .{ .positions = p, .indices = indices };
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
