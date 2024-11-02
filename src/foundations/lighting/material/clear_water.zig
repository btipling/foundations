pub const ClearWater: Material = .{
    .ambient = .{ 0.125490, 0.125490, 0.125490, 1 },
    .diffuse = .{ 0.68824, 0.68824, 0.68824, 1 },
    .specular = .{ 0.870588, 0.870588, 0.870588, 1 },
    .shininess = 10.0,
};

const Material = @import("../Material.zig");
