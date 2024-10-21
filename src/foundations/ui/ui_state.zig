pub const scene_type = enum(usize) {
    // shapes
    point_rotating,
    triangle,
    cubes_animated,
    circle,
    sphere,
    cylinder_animated,
    cone_animated,
    pyramid,
    torus,
    // math
    math_vector_arithmetic,
    line,
    unit_circle,
    barycentric_coordinates,
    line_distance,
    look_at,
    plane_distance,
    frustum_planes,
    // color
    linear_colorspace,
    polygon_offset,
    // CGPOC
    point,
    triangle_animated,
    four_plane_red_cube,
    four_varying_color_cube,
    four_cube_and_pyramid,
    four_simple_solar_system,
    five_textured_pyramid,
    six_textured_torus,
    six_shuttle,
    seven_lighting,
    seven_dolphin,
    eight_shadows,
    ten_surface_detail,
    twelve_basic_tessellator,
    twelve_terrain_tessellator,
    twelve_lod_tessellator,
};

pub const scenes = union(scene_type) {
    // shapes
    point_rotating: *scenes_list.shapes.Point,
    triangle: *scenes_list.shapes.Triangle,
    cubes_animated: *scenes_list.shapes.Cube,
    circle: *scenes_list.shapes.Circle,
    sphere: *scenes_list.shapes.Sphere,
    cylinder_animated: *scenes_list.shapes.Cylinder,
    cone_animated: *scenes_list.shapes.Cone,
    pyramid: *scenes_list.shapes.Pyramid,
    torus: *scenes_list.shapes.Torus,
    // math
    math_vector_arithmetic: *scenes_list.math.MathVectorArithmetic,
    line: *scenes_list.math.Line,
    unit_circle: *scenes_list.math.UnitCircle,
    barycentric_coordinates: *scenes_list.math.BarycentricCoordinates,
    line_distance: *scenes_list.math.LineDistance,
    look_at: *scenes_list.math.LookAt,
    plane_distance: *scenes_list.math.PlaneDistance,
    frustum_planes: *scenes_list.math.FrustumPlanes,
    // color
    linear_colorspace: *scenes_list.graphics.LinearColorspace,
    polygon_offset: *scenes_list.graphics.PolygonOffset,
    // CGPOC
    point: *scenes_list.cgpoc.point,
    triangle_animated: *scenes_list.cgpoc.triangle_animated,
    four_plane_red_cube: *scenes_list.cgpoc.chapter4.PlainRedCube,
    four_varying_color_cube: *scenes_list.cgpoc.chapter4.VaryingColorCube,
    four_cube_and_pyramid: *scenes_list.cgpoc.chapter4.CubeAndPyramid,
    four_simple_solar_system: *scenes_list.cgpoc.chapter4.SimpleSolarSystem,
    five_textured_pyramid: *scenes_list.cgpoc.chapter5.TexturedPyramid,
    six_textured_torus: *scenes_list.cgpoc.chapter6.TexturedTorus,
    six_shuttle: *scenes_list.cgpoc.chapter6.Shuttle,
    seven_lighting: *scenes_list.cgpoc.chapter7.Lighting,
    seven_dolphin: *scenes_list.cgpoc.chapter7.Dolphin,
    eight_shadows: *scenes_list.cgpoc.chapter8.Shadows,
    ten_surface_detail: *scenes_list.cgpoc.chapter10.SurfaceDetail,
    twelve_basic_tessellator: *scenes_list.cgpoc.chapter12.BasicTessellator,
    twelve_terrain_tessellator: *scenes_list.cgpoc.chapter12.TerrainTessellator,
    twelve_lod_tessellator: *scenes_list.cgpoc.chapter12.LodTessellator,
};

pub const scene_nav_type = enum {
    shape,
    math,
    graphics,
    cgpoc,
};

pub const scene_nav_info = struct {
    nav_type: scene_nav_type,
    name: []const u8,
};

const scenes_list = @import("../scenes/scenes.zig");
