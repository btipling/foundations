demo_current: demo_type = .line,

pub const demo_type = enum(usize) {
    point,
    point_rotating,
    triangle,
    triangle_animated,
    cubes_animated,
    math_vector_arithmetic,
    linear_colorspace,
    circle,
    sphere,
    line,
};

pub const demos = union(demo_type) {
    point: *point,
    point_rotating: *point_rotating,
    triangle: *triangle,
    triangle_animated: *triangle_animated,
    cubes_animated: *cubes_animated,
    math_vector_arithmetic: *math_vector_arithmetic,
    linear_colorspace: *linear_colorspace,
    circle: *circle,
    sphere: *sphere,
    line: *line,
};

const point = @import("../demos/point/point.zig");
const point_rotating = @import("../demos/point_rotating/point_rotating.zig");
const triangle = @import("../demos/triangle/triangle.zig");
const triangle_animated = @import("../demos/triangle_animated/triangle_animated.zig");
const math_vector_arithmetic = @import("../demos/math_vector_arithmetic/math_vector_arithmetic.zig");
const linear_colorspace = @import("../demos/linear_colorspace/linear_colorspace.zig");
const cubes_animated = @import("../demos/cubes_animated/cubes_animated.zig");
const circle = @import("../demos/circle/circle.zig");
const sphere = @import("../demos/sphere/sphere.zig");
const line = @import("../demos/line/line.zig");
