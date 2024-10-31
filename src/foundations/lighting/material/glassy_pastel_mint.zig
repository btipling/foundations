pub const GlassyPastelMint: Material = .{
    .ambient = .{ 0.02, 0.05, 0.03, 0.1 },
    .diffuse = .{ 0.75, 0.95, 0.85, 0.2 }, // Soft mint green
    .specular = .{ 0.95, 0.95, 0.95, 1.0 },
    .shininess = 92.0,
};

const Material = @import("../Material.zig");
