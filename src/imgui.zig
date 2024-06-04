const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "1");
    @cInclude("cimgui.h");
});

var io: *c.ImGuiIO = undefined;

pub fn createContext() void {
    _ = c.igCreateContext(null);
    io = c.igGetIO();
    const v = c.igGetVersion();
    std.debug.print("dear imgui version: {s}\n", .{v});
}

const std = @import("std");
