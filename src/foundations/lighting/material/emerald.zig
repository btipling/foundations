pub const Emerald: Material = .{
    .ambient = .{ 0.0215, 0.1745, 0.0215, 0.55 },
    .diffuse = .{ 0.07568, 0.61424, 0.07568, 0.55 },
    .specular = .{ 0.633, 0.727811, 0.633, 0.55 },
    .shininess = 76.8,
};

const Material = @import("../Material.zig");
