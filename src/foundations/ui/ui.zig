io: *c.ImGuiIO,
ctx: *c.ImGuiContext,
win: *glfw.window,
allocator: std.mem.Allocator,
width: u32,
height: u32,
helpers: ui_helpers,
state: *ui_state,

const UI = @This();

var ui: *UI = undefined;

pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, glsl_version: []const u8) void {
    // Initialize windowing
    glfw.init() catch @panic("no glfw");
    const win = glfw.createWindow(@intCast(width), @intCast(height)) catch @panic("no window");

    // Initialize cimgui
    const ctx = c.igCreateContext(null) orelse @panic("no imgui");
    const io: *c.ImGuiIO = c.igGetIO();
    const v = c.igGetVersion();

    std.debug.print("dear imgui version: {s}\n", .{v});
    _ = c.ImGui_ImplGlfw_InitForOpenGL(@ptrCast(win), true);
    _ = c.ImGui_ImplOpenGL3_Init(@ptrCast(glsl_version));

    const scale = glfw.contentScale(win);
    io.FontGlobalScale = scale;

    const s = allocator.create(ui_state) catch @panic("OOM");
    s.* = .{};
    ui = allocator.create(UI) catch @panic("OOM");
    ui.* = .{
        .width = width,
        .height = height,
        .io = io,
        .ctx = ctx,
        .win = win,
        .helpers = .{ .scale = scale },
        .state = s,
        .allocator = allocator,
    };
}

pub fn deinit() void {
    c.ImGui_ImplOpenGL3_Shutdown();
    c.ImGui_ImplGlfw_Shutdown();
    c.igDestroyContext(ui.ctx);
    glfw.destroyWindow(ui.win);
    glfw.deinit();
    ui.allocator.destroy(ui.state);
    ui.allocator.destroy(ui);
}

pub fn endFrame() void {
    c.igRender();
    c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
    glfw.swapBuffers(ui.win);
}

pub fn shouldClose() bool {
    glfw.pollEvents();
    return glfw.shouldClose(ui.win);
}

pub fn windowDimensions() [2]u32 {
    return [2]u32{ ui.width, ui.height };
}

pub fn hellWorld() void {
    var show = true;
    c.igShowDemoWindow(@ptrCast(&show));
}

pub fn beginFrame() void {
    c.ImGui_ImplOpenGL3_NewFrame();
    c.ImGui_ImplGlfw_NewFrame();
    c.igNewFrame();
}

pub fn helpers() ui_helpers {
    return ui.helpers;
}

pub fn state() *ui_state {
    return ui.state;
}

const std = @import("std");
const c = @import("../c.zig").c;
const ui_helpers = @import("ui_helpers.zig");
pub const nav = @import("ui_navigation.zig").draw;

pub const glfw = @import("ui_glfw.zig");
pub const ui_state = @import("ui_state.zig");
