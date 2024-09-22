pub const Ruby: Material = .{
    .ambient = .{ 0.1745, 0.01175, 0.01175, 0.55 },
    .diffuse = .{ 0.61424, 0.04136, 0.04136, 0.55 },
    .specular = .{ 0.727811, 0.626959, 0.626959, 0.55 },
    .shininess = 76.8,
};

const Material = @import("../Material.zig");
