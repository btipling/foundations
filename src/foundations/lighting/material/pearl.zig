pub const Pearl: Material = .{
    .ambient = .{ 0.2500, 0.2073, 0.2073, 1.0 },
    .diffuse = .{ 1.0000, 0.8290, 0.8290, 1.0 },
    .specular = .{ 0.2966, 0.2966, 0.2966, 1.0 },
    .shininess = 11.264,
};

const Material = @import("../Material.zig");
