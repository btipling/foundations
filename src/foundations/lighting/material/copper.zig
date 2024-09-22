pub const Copper: Material = .{
    .ambient = .{ 0.19125, 0.0735, 0.0225, 1.0 },
    .diffuse = .{ 0.7038, 0.27048, 0.0828, 1.0 },
    .specular = .{ 0.256777, 0.137622, 0.086014, 1.0 },
    .shininess = 12.8,
};

const Material = @import("../Material.zig");
