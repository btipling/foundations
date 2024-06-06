pub fn beginFrame() void {
    const dims = ui.windowDimensions();
    c.glViewport(0, 0, @intCast(dims[0]), @intCast(dims[1]));
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    c.glClearColor(0.6, 0, 1, 1);
}

const c = @cImport({
    @cInclude("glad/gl.h");
});

const ui = @import("../ui/ui.zig");
