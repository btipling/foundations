pub const scene_type = enum(usize) {
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
    unit_circle,
    barycentric_coordinates,
    line_distance,
    look_at,
    plane_distance,
};

pub const scenes = union(scene_type) {
    point: *point,
    point_rotating: *point_rotating,
    triangle: *triangle,
    triangle_animated: *triangle_animated,
    cubes_animated: *CubeAnimated,
    math_vector_arithmetic: *math_vector_arithmetic,
    linear_colorspace: *linear_colorspace,
    circle: *circle,
    sphere: *sphere,
    line: *line,
    unit_circle: *UnitCircle,
    barycentric_coordinates: *BarycentricCoordinates,
    line_distance: *LineDistance,
    look_at: *look_at,
    plane_distance: *PlaneDistance,
};

pub const scene_nav_type = enum {
    shape,
    math,
    color,
};

pub const scene_nav_info = struct {
    nav_type: scene_nav_type,
    name: []const u8,
};

const point = @import("../scenes/point/point.zig");
const point_rotating = @import("../scenes/point_rotating/point_rotating.zig");
const triangle = @import("../scenes/triangle/triangle.zig");
const triangle_animated = @import("../scenes/triangle_animated/triangle_animated.zig");
const math_vector_arithmetic = @import("../scenes/math_vector_arithmetic/math_vector_arithmetic.zig");
const linear_colorspace = @import("../scenes/linear_colorspace/linear_colorspace.zig");
const CubeAnimated = @import("../scenes/cubes_animated/CubeAnimated.zig");
const circle = @import("../scenes/circle/circle.zig");
const sphere = @import("../scenes/sphere/sphere.zig");
const line = @import("../scenes/line/line.zig");
const UnitCircle = @import("../scenes/unit_circle/UnitCircle.zig");
const BarycentricCoordinates = @import("../scenes/barycentric_coordinates/BarycentricCoordinates.zig");
const LineDistance = @import("../scenes/line_distance/LineDistance.zig");
const look_at = @import("../scenes/look_at/look_at.zig");
const PlaneDistance = @import("../scenes/plane_distance/PlaneDistance.zig");
