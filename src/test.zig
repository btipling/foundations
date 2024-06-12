pub fn main() !void {
    _ = math.vector;
}

test {
    std.testing.refAllDeclsRecursive(@This());
}

const std = @import("std");
const math = @import("foundations/math/math.zig");
