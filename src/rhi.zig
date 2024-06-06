const c = @cImport({
    @cInclude("glad/gl.h");
});

pub fn clear() void {
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    c.glClearColor(0.6, 0, 1, 1);
}
