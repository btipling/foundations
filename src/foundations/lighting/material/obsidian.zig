pub const Obsidian: Material = .{
    .ambient = .{ 0.05375, 0.05, 0.06625, 0.82 },
    .diffuse = .{ 0.18275, 0.17, 0.22525, 0.82 },
    .specular = .{ 0.332741, 0.328634, 0.346435, 0.82 },
    .shininess = 38.4,
};

const Material = @import("../Material.zig");
