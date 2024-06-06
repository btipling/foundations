var io: *c.ImGuiIO = undefined;

pub fn createContext(win: ?*glfw.window) void {
    _ = c.igCreateContext(null);
    io = c.igGetIO();
    const v = c.igGetVersion();
    std.debug.print("dear imgui version: {s}\n", .{v});
    _ = c.ImGui_ImplGlfw_InitForOpenGL(@ptrCast(win), true);
    const glsl_version: [*c]const u8 = "#version 460";
    _ = c.ImGui_ImplOpenGL3_Init(glsl_version);
}

pub fn frame() void {
    c.ImGui_ImplOpenGL3_NewFrame();
    c.ImGui_ImplGlfw_NewFrame();
    c.igNewFrame();
    var show = true;
    c.igShowDemoWindow(@ptrCast(&show));
    _ = c.igBegin("Hello, world!", null, 0);
    c.igText("This is some useful text");
    c.igEnd();
    c.igRender();
    c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
}

const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cDefine("CIMGUI_USE_GLFW", {});
    @cDefine("CIMGUI_USE_OPENGL3", {});
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
});
const std = @import("std");
const glfw = @import("glfw.zig");
