app_demos: *demos,

const Nav = @This();

pub fn init(app_demos: *demos) Nav {
    return .{ .app_demos = app_demos };
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
                self.app_demos.setDemo(.point);
            }
            if (c.igMenuItem_Bool("Rotating Point", null, false, true)) {
                self.app_demos.setDemo(.point_rotating);
            }
            if (c.igMenuItem_Bool("Triangle", null, false, true)) {
                self.app_demos.setDemo(.triangle);
            }
            if (c.igMenuItem_Bool("Animated Triangle", null, false, true)) {
                self.app_demos.setDemo(.triangle_animated);
            }
            if (c.igMenuItem_Bool("Animated Cubes", null, false, true)) {
                self.app_demos.setDemo(.cubes_animated);
            }
            if (c.igMenuItem_Bool("Circle", null, false, true)) {
                self.app_demos.setDemo(.circle);
            }
            if (c.igMenuItem_Bool("Shere", null, false, true)) {
                self.app_demos.setDemo(.sphere);
            }
            c.igEndMenu();
        }
        if (c.igBeginMenu("Math", true)) {
            if (c.igMenuItem_Bool("Vector Arithmetic", null, false, true)) {
                self.app_demos.setDemo(.math_vector_arithmetic);
            }
            if (c.igMenuItem_Bool("Lines", null, false, true)) {
                self.app_demos.setDemo(.line);
            }
            c.igEndMenu();
        }
        if (c.igBeginMenu("Color", true)) {
            if (c.igMenuItem_Bool("Linear colorspace", null, false, true)) {
                self.app_demos.setDemo(.linear_colorspace);
            }
            c.igEndMenu();
        }

        c.igEndMainMenuBar();
    }
}

const std = @import("std");
const c = @import("../c.zig").c;
const demos = @import("../demos/demos.zig");
const ui = @import("ui.zig");
