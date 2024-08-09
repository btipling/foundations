pub const c = @cImport({
    @cInclude("glad/gl.h");
    @cInclude("GLFW/glfw3.h");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cDefine("CIMGUI_USE_GLFW", {});
    @cDefine("CIMGUI_USE_OPENGL3", {});
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
    @cInclude("flecs.h");
});
