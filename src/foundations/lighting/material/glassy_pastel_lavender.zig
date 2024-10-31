pub const GlassyPastelLavender: Material = .{
    .ambient = .{ 0.04, 0.02, 0.05, 0.1 },
    .diffuse = .{ 0.85, 0.75, 0.95, 0.2 }, // Soft lavender
    .specular = .{ 0.95, 0.95, 0.95, 1.0 },
    .shininess = 92.0,
};

const Material = @import("../Material.zig");
