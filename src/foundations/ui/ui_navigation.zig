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
            if (c.igMenuItem_Bool("Point", null, false, true)) {
                self.app_scenes.setScene(.point);
            }
            if (c.igMenuItem_Bool("Rotating Point", null, false, true)) {
                self.app_scenes.setScene(.point_rotating);
            }
            if (c.igMenuItem_Bool("Triangle", null, false, true)) {
                self.app_scenes.setScene(.triangle);
            }
            if (c.igMenuItem_Bool("Animated Triangle", null, false, true)) {
                self.app_scenes.setScene(.triangle_animated);
            }
            if (c.igMenuItem_Bool("Animated Cubes", null, false, true)) {
                self.app_scenes.setScene(.cubes_animated);
            }
            if (c.igMenuItem_Bool("Circle", null, false, true)) {
                self.app_scenes.setScene(.circle);
            }
            if (c.igMenuItem_Bool("Shere", null, false, true)) {
                self.app_scenes.setScene(.sphere);
            }
            c.igEndMenu();
        }
        if (c.igBeginMenu("Math", true)) {
            if (c.igMenuItem_Bool("Vector Arithmetic", null, false, true)) {
                self.app_scenes.setScene(.math_vector_arithmetic);
            }
            if (c.igMenuItem_Bool("Lines", null, false, true)) {
                self.app_scenes.setScene(.line);
            }
            c.igEndMenu();
        }
        if (c.igBeginMenu("Color", true)) {
            if (c.igMenuItem_Bool("Linear colorspace", null, false, true)) {
                self.app_scenes.setScene(.linear_colorspace);
            }
            c.igEndMenu();
        }

        c.igEndMainMenuBar();
    }
}

const std = @import("std");
const c = @import("../c.zig").c;
const scenes = @import("../scenes/scenes.zig");
const ui = @import("ui.zig");
