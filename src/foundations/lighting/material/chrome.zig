pub const Chrome: Material = .{
    .ambient = .{ 0.25, 0.25, 0.25, 1.0 },
    .diffuse = .{ 0.4, 0.4, 0.4, 1.0 },
    .specular = .{ 0.774597, 0.774597, 0.774597, 1.0 },
    .shininess = 76.8,
};

const Material = @import("../Material.zig");
