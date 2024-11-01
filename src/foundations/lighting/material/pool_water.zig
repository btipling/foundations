pub const PoolWater: Material = .{
    .ambient = .{ 0.017843, 0.125490, 0.160784, 0.7 },
    .diffuse = .{ 0.058824, 0.458824, 0.486275, 0.8 },
    .specular = .{ 0.870588, 0.921569, 0.937255, 0.9 },
    .shininess = 89.6,
};

const Material = @import("../Material.zig");
