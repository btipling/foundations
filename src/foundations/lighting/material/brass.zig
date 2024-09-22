pub const Brass: Material = .{
    .ambient = .{ 0.329412, 0.223529, 0.027451, 1.0 },
    .diffuse = .{ 0.780392, 0.568627, 0.113725, 1.0 },
    .specular = .{ 0.992157, 0.941176, 0.807843, 1.0 },
    .shininess = 27.8974,
};

const Material = @import("../Material.zig");
