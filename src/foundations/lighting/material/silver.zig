pub const Silver: Material = .{
    .ambient = .{ 0.1923, 0.1923, 0.1923, 1.0 },
    .diffuse = .{ 0.5075, 0.5075, 0.5075, 1.0 },
    .specular = .{ 0.5083, 0.5083, 0.5083, 1.0 },
    .shininess = 51.200,
};

const Material = @import("../Material.zig");
