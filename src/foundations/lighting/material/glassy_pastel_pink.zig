pub const GlassyPastelPink: Material = .{
    .ambient = .{ 0.05, 0.02, 0.02, 0.1 },
    .diffuse = .{ 0.95, 0.75, 0.75, 0.2 }, // Soft pink
    .specular = .{ 0.95, 0.95, 0.95, 1.0 },
    .shininess = 92.0,
};

const Material = @import("../Material.zig");
