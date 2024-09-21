pub fn theme(scale: f32) void {
    var style = c.igGetStyle().*;

    // Increase border thickness
    style.FrameBorderSize = 1.25 * scale;
    style.WindowBorderSize = 1.25 * scale;
    style.PopupBorderSize = 1.25 * scale;
    style.TabBorderSize = 1.25 * scale;

    // Adjust rounding (optional, depends on your preference)
    style.FrameRounding = 2.0 * scale;
    style.WindowRounding = 2.0 * scale;
    style.ScrollbarRounding = 2.0 * scale;
    style.GrabRounding = 2.0 * scale;
    style.TabRounding = 2.0 * scale;

    // Increase left padding
    style.WindowPadding = c.ImVec2{ .x = 20 * scale, .y = 6 * scale };
    style.FramePadding = c.ImVec2{ .x = 10 * scale, .y = 4 * scale };

    // Enhance shadow and borders for depth
    style.Colors[c.ImGuiCol_BorderShadow] = c.ImVec4_ImVec4_Float(0.00, 0.00, 0.00, 0.60).*;
    style.Colors[c.ImGuiCol_Border] = c.ImVec4_ImVec4_Float(0.40, 0.40, 0.40, 1.00).*;

    // Adjust background colors for better contrast
    style.Colors[c.ImGuiCol_WindowBg] = c.ImVec4_ImVec4_Float(0.15, 0.15, 0.15, 1.00).*;
    style.Colors[c.ImGuiCol_PopupBg] = c.ImVec4_ImVec4_Float(0.13, 0.13, 0.13, 1.00).*;
    style.Colors[c.ImGuiCol_FrameBg] = c.ImVec4_ImVec4_Float(0.20, 0.20, 0.20, 1.00).*;
    style.Colors[c.ImGuiCol_FrameBgHovered] = c.ImVec4_ImVec4_Float(0.28, 0.28, 0.28, 1.00).*;
    style.Colors[c.ImGuiCol_FrameBgActive] = c.ImVec4_ImVec4_Float(0.35, 0.35, 0.35, 1.00).*;

    // Enhance button colors
    style.Colors[c.ImGuiCol_Button] = c.ImVec4_ImVec4_Float(0.25, 0.25, 0.25, 1.00).*;
    style.Colors[c.ImGuiCol_ButtonHovered] = c.ImVec4_ImVec4_Float(0.33, 0.33, 0.33, 1.00).*;
    style.Colors[c.ImGuiCol_ButtonActive] = c.ImVec4_ImVec4_Float(0.40, 0.40, 0.40, 1.00).*;

    // Adjust header colors
    style.Colors[c.ImGuiCol_Header] = c.ImVec4_ImVec4_Float(0.22, 0.22, 0.22, 1.00).*;
    style.Colors[c.ImGuiCol_HeaderHovered] = c.ImVec4_ImVec4_Float(0.30, 0.30, 0.30, 1.00).*;
    style.Colors[c.ImGuiCol_HeaderActive] = c.ImVec4_ImVec4_Float(0.37, 0.37, 0.37, 1.00).*;

    // Enhance slider and scrollbar for better visibility
    style.Colors[c.ImGuiCol_SliderGrab] = c.ImVec4_ImVec4_Float(0.45, 0.45, 0.45, 1.00).*;
    style.Colors[c.ImGuiCol_SliderGrabActive] = c.ImVec4_ImVec4_Float(0.55, 0.55, 0.55, 1.00).*;
    style.Colors[c.ImGuiCol_ScrollbarGrab] = c.ImVec4_ImVec4_Float(0.40, 0.40, 0.40, 1.00).*;
    style.Colors[c.ImGuiCol_ScrollbarGrabHovered] = c.ImVec4_ImVec4_Float(0.50, 0.50, 0.50, 1.00).*;
    style.Colors[c.ImGuiCol_ScrollbarGrabActive] = c.ImVec4_ImVec4_Float(0.60, 0.60, 0.60, 1.00).*;

    // Ensure text is clearly visible
    style.Colors[c.ImGuiCol_Text] = c.ImVec4_ImVec4_Float(0.90, 0.90, 0.90, 1.00).*;
    style.Colors[c.ImGuiCol_TextDisabled] = c.ImVec4_ImVec4_Float(0.60, 0.60, 0.60, 1.00).*;

    // Adjust spacing for better separation of elements
    style.ItemSpacing = c.ImVec2{ .x = 8 * scale, .y = 4 * scale };
    style.ItemInnerSpacing = c.ImVec2{ .x = 4 * scale, .y = 4 * scale };
    style.TouchExtraPadding = c.ImVec2{ .x = 2 * scale, .y = 2 * scale };

    // Adjust sizes
    style.ScrollbarSize = 14 * scale;
    style.GrabMinSize = 10 * scale;

    c.igGetStyle().* = style;
}

const c = @import("../c.zig").c;
