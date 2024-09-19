pub const Gold: Material = .{
    .ambient = .{ 0.2473, 0.1995, 0.0745, 1.0 },
    .diffuse = .{ 0.7516, 0.6065, 0.2265, 1.0 },
    .specular = .{ 0.6283, 0.5558, 0.3661, 1.0 },
    .shininess = 51.200,
};

const Material = @import("../Material.zig");
