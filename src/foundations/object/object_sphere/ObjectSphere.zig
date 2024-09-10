mesh: rhi.mesh,
vertex_data_size: usize,
instance_data_stride: usize,

const Sphere = @This();
const angle_delta: f32 = std.math.pi * 0.02;
const x_angle_delta = angle_delta / 2.0;
const x_grid_rows: f32 = std.math.pi * 2.0 - angle_delta * 1.5;
const grid_dimension: usize = @intFromFloat((2.0 * std.math.pi) / angle_delta);
const quad_dimensions = grid_dimension - 1;
const num_quads = quad_dimensions * quad_dimensions;
const num_triangles = quad_dimensions;
const num_triangles_in_end = quad_dimensions * 2;
const num_quads_in_grid = ((x_grid_rows - x_angle_delta * 2) / x_angle_delta) * grid_dimension;
const num_vertices: usize = (num_triangles_in_end * 2 + 1) + (3 * grid_dimension) * (3 * grid_dimension) + (num_triangles_in_end * 2 + 1);
const num_indices: usize = (grid_dimension * 3) + 6 * num_quads_in_grid + (grid_dimension * 3);
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
        .vertex_data_size = vao_buf.vertex_data_size,
        .instance_data_stride = vao_buf.instance_data_stride,
    };
}

pub fn updateInstanceAt(self: Sphere, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

fn data() struct { attribute_data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var attribute_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;
    const y_angle_delta = angle_delta;
    var x_axis_angle: f32 = x_angle_delta;
    var y_axis_angle: f32 = y_angle_delta;

    var positions: [num_vertices]math.vector.vec3 = undefined;
    const r: f32 = 1.0;

    const start: math.vector.vec3 = .{ 1, 0, 0 };
    const end: math.vector.vec3 = .{ -1, 0, 0 };
    positions[0] = start;
    positions[1] = end;
    var pi: usize = 2;
    while (y_axis_angle <= std.math.pi * 2 + y_angle_delta) : (y_axis_angle += y_angle_delta) {
        positions[pi] = .{
            r * @cos(x_axis_angle),
            r * @sin(x_axis_angle) * @sin(y_axis_angle),
            r * @sin(x_axis_angle) * @cos(y_axis_angle),
        };
        pi += 1;
    }
    y_axis_angle += y_angle_delta;
    x_axis_angle += x_angle_delta;

    var ii: usize = 0;
    var i: u32 = 0;
    var pii: u32 = 1;
    while (i < num_triangles) : (i += 1) {
        indices[ii] = 0;
        indices[ii + 1] = pii + 2;
        indices[ii + 2] = pii + 1;
        ii += 3;
        pii += 1;
    }
    indices[ii] = 0;
    indices[ii + 1] = pii + 2;
    indices[ii + 2] = 1;
    ii += 3;
    pii += 2;

    var iii: usize = 2;
    while (x_axis_angle < x_grid_rows) : (x_axis_angle += x_angle_delta) {
        const start_iii = iii;
        y_axis_angle = y_angle_delta;
        for (0..grid_dimension) |ri| {
            positions[pi] = .{
                r * @cos(x_axis_angle),
                r * @sin(x_axis_angle) * @sin(y_axis_angle),
                r * @sin(x_axis_angle) * @cos(y_axis_angle),
            };
            pi += 1;
            y_axis_angle += y_angle_delta;
            positions[pi] = .{
                r * @cos(x_axis_angle),
                r * @sin(x_axis_angle) * @sin(y_axis_angle),
                r * @sin(x_axis_angle) * @cos(y_axis_angle),
            };
            pi += 1;
            {
                var tr = iii + 1;
                if (ri == grid_dimension - 1) {
                    tr = start_iii;
                }
                const br = iii + grid_dimension + 1;
                const tl = iii;
                const bl = iii + grid_dimension;

                // Triangle 1
                indices[ii] = @intCast(tl);
                indices[ii + 1] = @intCast(br);
                indices[ii + 2] = @intCast(bl);

                // Triangle 2
                indices[ii + 3] = @intCast(tl);
                indices[ii + 4] = @intCast(tr);
                indices[ii + 5] = @intCast(br);

                ii += 6;
                iii += 1;
            }
            y_axis_angle += y_angle_delta;
            pii += 2;
        }
    }

    y_axis_angle = y_angle_delta;
    x_axis_angle = std.math.pi + x_angle_delta;
    while (y_axis_angle <= std.math.pi * 2 + y_angle_delta) : (y_axis_angle += y_angle_delta) {
        positions[pi] = .{
            r * @cos(x_axis_angle),
            r * @sin(x_axis_angle) * @sin(y_axis_angle),
            r * @sin(x_axis_angle) * @cos(y_axis_angle),
        };
        pi += 1;
    }

    i = 0;
    const closer = pii;
    while (i < num_triangles) : (i += 1) {
        indices[ii + 2] = 1;
        indices[ii + 1] = pii + 1;
        indices[ii] = pii + 0;
        ii += 3;
        pii += 1;
    }
    indices[ii + 2] = 1;
    indices[ii + 1] = closer;
    indices[ii] = pii;
    var adi: usize = 0;

    while (adi < pi) : (adi += 1) {
        attribute_data[adi].position = positions[adi];
        attribute_data[adi].normals = math.vector.normalize(positions[adi]);
    }

    return .{ .attribute_data = attribute_data, .indices = indices };
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
