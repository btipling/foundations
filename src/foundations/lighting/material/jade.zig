pub const Jade: Material = .{
    .ambient = .{ 0.1350, 0.2225, 0.1575, 1.0 },
    .diffuse = .{ 0.5400, 0.8900, 0.6300, 1.0 },
    .specular = .{ 0.3162, 0.3162, 0.3162, 1.0 },
    .shininess = 12.800,
};

const Material = @import("../Material.zig");
