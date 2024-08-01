pub fn main() !void {
    _ = math.vector;
    _ = math.rotation;
    _ = math.float;
    _ = math.matrix;
    _ = math.interpolation;
    _ = config.parser;
}

test {
    std.testing.refAllDeclsRecursive(@This());
}

const std = @import("std");
const math = @import("foundations/math/math.zig");
const config = @import("foundations/config/config.zig");
