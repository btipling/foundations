pub const PoolWater: Material = .{
    // Darker blue base color for underwater feel
    .ambient = .{ 0.05, 0.15, 0.25, 0.7 },
    // Lighter blue-green for main water color with transparency
    .diffuse = .{ 0.1, 0.3, 0.4, 0.8 },
    // Close to sky color for reflections (194/255, 216/255, 241/255)
    .specular = .{ 0.76, 0.847, 0.945, 0.9 },
    // High shininess for water's reflective surface
    .shininess = 96.0,
};

const Material = @import("../Material.zig");
