app_scenes: *scenes,

const Nav = @This();

pub fn init(app_scenes: *scenes) Nav {
    return .{ .app_scenes = app_scenes };
}

pub fn draw(self: *Nav) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    if (c.igBeginMainMenuBar()) {
        if (c.igBeginMenu("Shapes", true)) {
            self.navMenuItems(.shape);
            c.igEndMenu();
        }
        if (c.igBeginMenu("Math", true)) {
            self.navMenuItems(.math);
            c.igEndMenu();
        }
        if (c.igBeginMenu("Graphics", true)) {
            self.navMenuItems(.graphics);
            c.igEndMenu();
        }
        if (c.igBeginMenu("CGPOC", true)) {
            self.navMenuItems(.cgpoc);
            c.igEndMenu();
        }
        c.igEndMainMenuBar();
    }
}

inline fn navMenuItems(self: *Nav, nav_type: ui.ui_state.scene_nav_type) void {
    inline for (std.meta.fields(ui.ui_state.scene_type)) |field| {
        const dt = @field(ui.ui_state.scene_type, field.name);
        @setEvalBranchQuota(10_000);
        switch (dt) {
            inline else => |dtag| {
                const ntfn: *const fn () ui.ui_state.scene_nav_info = @field(std.meta.Child(std.meta.TagPayload(
                    ui.ui_state.scenes,
                    dtag,
                )), "navType");
                const nav_info: ui.ui_state.scene_nav_info = @call(.auto, ntfn, .{});
                if (nav_info.nav_type == nav_type) {
                    if (c.igMenuItem_Bool(@ptrCast(nav_info.name), null, false, true)) {
                        self.app_scenes.setScene(dt);
                    }
                }
            },
        }
    }
}

const std = @import("std");
const c = @import("../c.zig").c;
const scenes = @import("../scenes/scenes.zig");
const ui = @import("ui.zig");
