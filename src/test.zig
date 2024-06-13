pub fn main() !void {
    _ = math.vector;
    _ = math.cast;
    _ = math.float;
}

test {
    std.testing.refAllDeclsRecursive(@This());
}

const std = @import("std");
const math = @import("foundations/math/math.zig");
