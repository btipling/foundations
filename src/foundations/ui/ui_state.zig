pub const scene_type = enum(usize) {
    point_rotating,
    triangle,
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
    cylinder_animated,
    cone_animated,
    frustum_planes,
    // CGPOC
    point,
    triangle_animated,
    four_plane_red_cube,
};

pub const scenes = union(scene_type) {
    point_rotating: *point_rotating,
    triangle: *triangle,
    cubes_animated: *CubeAnimated,
    math_vector_arithmetic: *math_vector_arithmetic,
    linear_colorspace: *linear_colorspace,
    circle: *circle,
    sphere: *Sphere,
    line: *line,
    unit_circle: *UnitCircle,
    barycentric_coordinates: *BarycentricCoordinates,
    line_distance: *LineDistance,
    look_at: *LookAt,
    plane_distance: *PlaneDistance,
    cylinder_animated: *CylinderAnimated,
    cone_animated: *ConeAnimated,
    frustum_planes: *FrustumPlanes,
    // CGPOC
    point: *cgpoc.point,
    triangle_animated: *cgpoc.triangle_animated,
    four_plane_red_cube: *cgpoc.chapter4.PlainRedCube,
};

pub const scene_nav_type = enum {
    shape,
    math,
    color,
    cgpoc,
};

pub const scene_nav_info = struct {
    nav_type: scene_nav_type,
    name: []const u8,
};

const point_rotating = @import("../scenes/point_rotating/point_rotating.zig");
const triangle = @import("../scenes/triangle/triangle.zig");
const math_vector_arithmetic = @import("../scenes/math_vector_arithmetic/math_vector_arithmetic.zig");
const linear_colorspace = @import("../scenes/linear_colorspace/linear_colorspace.zig");
const CubeAnimated = @import("../scenes/cubes_animated/CubeAnimated.zig");
const circle = @import("../scenes/circle/circle.zig");
const Sphere = @import("../scenes/sphere/Sphere.zig");
const line = @import("../scenes/line/line.zig");
const UnitCircle = @import("../scenes/unit_circle/UnitCircle.zig");
const BarycentricCoordinates = @import("../scenes/barycentric_coordinates/BarycentricCoordinates.zig");
const LineDistance = @import("../scenes/line_distance/LineDistance.zig");
const LookAt = @import("../scenes/look_at/LookAt.zig");
const PlaneDistance = @import("../scenes/plane_distance/PlaneDistance.zig");
const CylinderAnimated = @import("../scenes/cylinder_animated/CylinderAnimated.zig");
const ConeAnimated = @import("../scenes/cone_animated/ConeAnimated.zig");
const FrustumPlanes = @import("../scenes/frustum_planes/FrustumPlanes.zig");
// CGPOC
const cgpoc = @import("../scenes/cgpoc/cgpoc.zig");
