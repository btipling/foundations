pub const ClearWater: Material = .{
    .ambient = .{ 0.6, 0.6, 0.6, 1 },
    .diffuse = .{ 0.9, 0.9, 0.9, 1 },
    .specular = .{ 1, 1, 1, 1 },
    .shininess = 10.0,
};

const Material = @import("../Material.zig");
