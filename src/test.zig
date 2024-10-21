pub fn main() !void {
    _ = math.vector;
    _ = math.rotation;
    _ = math.float;
    _ = math.matrix;
    _ = math.geometry;
    _ = math.geometry.Plane;
    _ = math.interpolation;
    _ = config.parser;
    _ = CompilerParser;
    _ = CompilerIncluder;
}

test {
    std.testing.refAllDeclsRecursive(@This());
}

const std = @import("std");
const math = @import("foundations/math/math.zig");
const config = @import("foundations/config/config.zig");
const CompilerParser = @import("compiler/Parser.zig");
const CompilerIncluder = @import("compiler/Includer.zig");
