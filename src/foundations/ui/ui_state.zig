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
    four_varying_color_cube,
    four_cube_and_pyramid,
};

pub const scenes = union(scene_type) {
    point_rotating: *scenes_list.shapes.Point,
    triangle: *scenes_list.shapes.Triangle,
    cubes_animated: *scenes_list.shapes.Cube,
    math_vector_arithmetic: *scenes_list.math.MathVectorArithmetic,
    linear_colorspace: *scenes_list.color.LinearColorspace,
    circle: *scenes_list.shapes.Circle,
    sphere: *scenes_list.shapes.Sphere,
    line: *scenes_list.math.Line,
    unit_circle: *scenes_list.math.UnitCircle,
    barycentric_coordinates: *scenes_list.math.BarycentricCoordinates,
    line_distance: *scenes_list.math.LineDistance,
    look_at: *scenes_list.math.LookAt,
    plane_distance: *scenes_list.math.PlaneDistance,
    cylinder_animated: *scenes_list.shapes.Cylinder,
    cone_animated: *scenes_list.shapes.Cone,
    frustum_planes: *scenes_list.math.FrustumPlanes,
    // CGPOC
    point: *scenes_list.cgpoc.point,
    triangle_animated: *scenes_list.cgpoc.triangle_animated,
    four_plane_red_cube: *scenes_list.cgpoc.chapter4.PlainRedCube,
    four_varying_color_cube: *scenes_list.cgpoc.chapter4.VaryingColorCube,
    four_cube_and_pyramid: *scenes_list.cgpoc.chapter4.CubeAndPyramid,
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

const scenes_list = @import("../scenes/scenes.zig");
