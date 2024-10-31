pub const GlassyPastelBlue: Material = .{
    .ambient = .{ 0.02, 0.02, 0.05, 0.1 },
    .diffuse = .{ 0.75, 0.85, 0.95, 0.2 }, // Soft blue
    .specular = .{ 0.95, 0.95, 0.95, 1.0 },
    .shininess = 92.0,
};

const Material = @import("../Material.zig");
