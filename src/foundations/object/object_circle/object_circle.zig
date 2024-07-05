mesh: rhi.mesh,

const Triangle = @This();
const num_vertices: usize = 3;

pub fn init(
    program: u32,
    color: [4]f32,
) Triangle {
    const p = positions();

    var data: [num_vertices]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < num_vertices) : (i += 1) {
        data[i] = .{
            .position = p[i],
            .color = color,
        };
    }
    const vao_buf = rhi.attachBuffer(data[0..]);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .instance_type = .{
                .array = .{
                    .count = p.len,
                },
            },
        },
    };
}

fn positions() [num_vertices][3]f32 {
    var p: [num_vertices][3]f32 = undefined;
    // origin:
    p[0] = .{ 0, 0, 0 };
    var i: usize = 1;
    const angle: f32 = std.math.pi / 10.0;
    var current_vector: [3]f32 = .{ 0, 0, 1 }; // start at z positive, move counter clockwise around the y axis
    while (i < num_vertices) : (i += 1) {
        p[i] = current_vector;
        const r = math.rotation.cartesian2DToPolarCoordinates(@as(math.vector.vec2, .{ current_vector[2], current_vector[1] }));
        const new_coordinates: [2]f32 = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{ r[0], r[1] + angle });
        current_vector[2] = new_coordinates[0];
        current_vector[0] = new_coordinates[1];
    }
    return p;
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
