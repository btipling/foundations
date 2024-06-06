io: *c.ImGuiIO,
ctx: *c.ImGuiContext,
win: *glfw.window,
allocator: std.mem.Allocator,
width: u32,
height: u32,

const UI = @This();

var ui: *UI = undefined;

pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, glsl_version: []const u8) void {
    glfw.init() catch @panic("no glfw");
    const win = glfw.createWindow(@intCast(width), @intCast(height)) catch @panic("no window");
    const ctx = c.igCreateContext(null) orelse @panic("no imgui");
    const io: *c.ImGuiIO = c.igGetIO();
    const v = c.igGetVersion();
    std.debug.print("dear imgui version: {s}\n", .{v});
    _ = c.ImGui_ImplGlfw_InitForOpenGL(@ptrCast(win), true);
    _ = c.ImGui_ImplOpenGL3_Init(@ptrCast(glsl_version));
    io.FontGlobalScale = glfw.contentScale(win);
    ui = allocator.create(UI) catch @panic("OOM");
    ui.* = .{
        .width = width,
        .height = height,
        .io = io,
        .ctx = ctx,
        .win = win,
        .allocator = allocator,
    };
}

pub fn deinit() void {
    c.ImGui_ImplOpenGL3_Shutdown();
    c.ImGui_ImplGlfw_Shutdown();
    c.igDestroyContext(ui.ctx);
    glfw.destroyWindow(ui.win);
    glfw.deinit();
    ui.allocator.destroy(ui);
}

pub fn endFrame() void {
    c.igEnd();
    c.igRender();
    c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
    glfw.swapBuffers(ui.win);
}

pub fn shouldClose() bool {
    glfw.pollEvents();
    return glfw.shouldClose(ui.win);
}

pub fn hellWorld() void {
    var show = true;
    c.igShowDemoWindow(@ptrCast(&show));
    _ = c.igBegin("Hello, world!", null, 0);
    c.igText("This is some useful text");
}

pub fn beginFrame() void {
    c.ImGui_ImplOpenGL3_NewFrame();
    c.ImGui_ImplGlfw_NewFrame();
    c.igNewFrame();
}

const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cDefine("CIMGUI_USE_GLFW", {});
    @cDefine("CIMGUI_USE_OPENGL3", {});
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
});
const std = @import("std");
pub const glfw = @import("glfw.zig");
