pub fn draw() void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    if (c.igBeginMainMenuBar()) {
        if (c.igBeginMenu("Shapes", true)) {
            if (c.igMenuItem_Bool("Point", null, false, true)) {
                ui.state().demo_current = .point;
            }
            if (c.igMenuItem_Bool("Rotating Point", null, false, true)) {
                ui.state().demo_current = .point_rotating;
            }
            if (c.igMenuItem_Bool("Triangle", null, false, true)) {
                ui.state().demo_current = .triangle;
            }
            if (c.igMenuItem_Bool("Animated Triangle", null, false, true)) {
                ui.state().demo_current = .triangle_animated;
            }
            if (c.igMenuItem_Bool("Animated Cubes", null, false, true)) {
                ui.state().demo_current = .cubes_animated;
            }
            if (c.igMenuItem_Bool("Circle", null, false, true)) {
                ui.state().demo_current = .circle;
            }
            c.igEndMenu();
        }
        if (c.igBeginMenu("Math", true)) {
            if (c.igMenuItem_Bool("Vector Arithmetic", null, false, true)) {
                ui.state().demo_current = .math_vector_arithmetic;
            }
            c.igEndMenu();
        }
        if (c.igBeginMenu("Color", true)) {
            if (c.igMenuItem_Bool("Linear colorspace", null, false, true)) {
                ui.state().demo_current = .linear_colorspace;
            }
            c.igEndMenu();
        }

        c.igEndMainMenuBar();
    }
}

const std = @import("std");
const c = @import("../c.zig").c;
const ui = @import("ui.zig");
