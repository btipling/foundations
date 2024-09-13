pub fn theme() void {
    var style = c.igGetStyle().*;
    style.WindowPadding = c.ImVec2_ImVec2_Float(20, 6).*;
    style.WindowTitleAlign = c.ImVec2_ImVec2_Float(0.30, 0.50).*;
    style.ScrollbarSize = 17;
    style.FramePadding = c.ImVec2_ImVec2_Float(5, 6).*;

    style.FrameRounding = 0;
    style.WindowRounding = 0;
    style.ScrollbarRounding = 0;
    style.ChildRounding = 0;
    style.PopupRounding = 0;
    style.GrabRounding = 0;
    style.TabRounding = 0;

    style.WindowBorderSize = 1;
    style.FrameBorderSize = 1;
    style.ChildBorderSize = 1;
    style.PopupBorderSize = 1;
    style.TabBorderSize = 1;

    style.Colors[c.ImGuiCol_Text] = c.ImVec4_ImVec4_Float(0.85, 0.87, 0.83, 1.00).*;
    style.Colors[c.ImGuiCol_TextDisabled] = c.ImVec4_ImVec4_Float(0.63, 0.67, 0.58, 1.00).*;
    style.Colors[c.ImGuiCol_WindowBg] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_ChildBg] = c.ImVec4_ImVec4_Float(0.00, 0.00, 0.00, 0.00).*;
    style.Colors[c.ImGuiCol_PopupBg] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_Border] = c.ImVec4_ImVec4_Float(0.53, 0.57, 0.50, 1.00).*;
    style.Colors[c.ImGuiCol_BorderShadow] = c.ImVec4_ImVec4_Float(0.16, 0.18, 0.13, 1.00).*;
    style.Colors[c.ImGuiCol_FrameBg] = c.ImVec4_ImVec4_Float(0.24, 0.27, 0.22, 1.00).*;
    style.Colors[c.ImGuiCol_FrameBgHovered] = c.ImVec4_ImVec4_Float(0.24, 0.27, 0.22, 1.00).*;
    style.Colors[c.ImGuiCol_FrameBgActive] = c.ImVec4_ImVec4_Float(0.24, 0.27, 0.22, 1.00).*;
    style.Colors[c.ImGuiCol_TitleBg] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_TitleBgActive] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_TitleBgCollapsed] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_MenuBarBg] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_ScrollbarBg] = c.ImVec4_ImVec4_Float(0.35, 0.42, 0.31, 0.52).*;
    style.Colors[c.ImGuiCol_ScrollbarGrab] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_ScrollbarGrabHovered] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_ScrollbarGrabActive] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_CheckMark] = c.ImVec4_ImVec4_Float(1.00, 1.00, 1.00, 1.00).*;
    style.Colors[c.ImGuiCol_SliderGrab] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_SliderGrabActive] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_Button] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_ButtonHovered] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_ButtonActive] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_Header] = c.ImVec4_ImVec4_Float(0.25, 0.25, 0.25, 1.00).*;
    style.Colors[c.ImGuiCol_HeaderHovered] = c.ImVec4_ImVec4_Float(0.25, 0.25, 0.25, 1.00).*;
    style.Colors[c.ImGuiCol_HeaderActive] = c.ImVec4_ImVec4_Float(1.00, 0.49, 0.11, 1.00).*;
    style.Colors[c.ImGuiCol_Separator] = c.ImVec4_ImVec4_Float(0.16, 0.18, 0.13, 1.00).*;
    style.Colors[c.ImGuiCol_SeparatorHovered] = c.ImVec4_ImVec4_Float(0.16, 0.18, 0.13, 1.00).*;
    style.Colors[c.ImGuiCol_SeparatorActive] = c.ImVec4_ImVec4_Float(0.16, 0.18, 0.13, 1.00).*;
    style.Colors[c.ImGuiCol_ResizeGrip] = c.ImVec4_ImVec4_Float(1.00, 1.00, 1.00, 1.00).*;
    style.Colors[c.ImGuiCol_ResizeGripHovered] = c.ImVec4_ImVec4_Float(1.00, 1.00, 1.00, 1.00).*;
    style.Colors[c.ImGuiCol_ResizeGripActive] = c.ImVec4_ImVec4_Float(1.00, 1.00, 1.00, 1.00).*;
    style.Colors[c.ImGuiCol_Tab] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_TabHovered] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_TabActive] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_TabUnfocused] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_TabUnfocusedActive] = c.ImVec4_ImVec4_Float(0.30, 0.35, 0.27, 1.00).*;
    style.Colors[c.ImGuiCol_DockingPreview] = c.ImVec4_ImVec4_Float(0.61, 0.61, 0.61, 1.00).*;
    style.Colors[c.ImGuiCol_DockingEmptyBg] = c.ImVec4_ImVec4_Float(1.00, 0.43, 0.35, 1.00).*;
    style.Colors[c.ImGuiCol_PlotLines] = c.ImVec4_ImVec4_Float(0.90, 0.70, 0.00, 1.00).*;
    style.Colors[c.ImGuiCol_PlotLinesHovered] = c.ImVec4_ImVec4_Float(1.00, 0.60, 0.00, 1.00).*;
    style.Colors[c.ImGuiCol_PlotHistogram] = c.ImVec4_ImVec4_Float(0.26, 0.59, 0.98, 0.34).*;
    style.Colors[c.ImGuiCol_PlotHistogramHovered] = c.ImVec4_ImVec4_Float(1.00, 1.00, 0.00, 0.78).*;
    style.Colors[c.ImGuiCol_TableHeaderBg] = c.ImVec4_ImVec4_Float(0.26, 0.59, 0.98, 1.00).*;
    style.Colors[c.ImGuiCol_TableBorderStrong] = c.ImVec4_ImVec4_Float(1.00, 1.00, 1.00, 0.67).*;
    style.Colors[c.ImGuiCol_TableBorderLight] = c.ImVec4_ImVec4_Float(0.80, 0.80, 0.80, 0.31).*;
    style.Colors[c.ImGuiCol_TableRowBg] = c.ImVec4_ImVec4_Float(0.80, 0.80, 0.80, 0.38).*;
    style.Colors[c.ImGuiCol_TableRowBgAlt] = c.ImVec4_ImVec4_Float(0.80, 0.80, 0.80, 1.00).*;
    style.Colors[c.ImGuiCol_TextSelectedBg] = c.ImVec4_ImVec4_Float(0.58, 0.53, 0.19, 1.00).*;
    style.Colors[c.ImGuiCol_DragDropTarget] = c.ImVec4_ImVec4_Float(0.58, 0.53, 0.19, 1.00).*;
    style.Colors[c.ImGuiCol_NavHighlight] = c.ImVec4_ImVec4_Float(1.00, 0.00, 0.94, 1.00).*;
    style.Colors[c.ImGuiCol_NavWindowingHighlight] = c.ImVec4_ImVec4_Float(1.00, 0.00, 0.69, 1.00).*;
    style.Colors[c.ImGuiCol_NavWindowingDimBg] = c.ImVec4_ImVec4_Float(0.12, 0.00, 1.00, 1.00).*;
    style.Colors[c.ImGuiCol_ModalWindowDimBg] = c.ImVec4_ImVec4_Float(0.00, 0.00, 1.00, 1.00).*;

    c.igGetStyle().* = style;
}

const c = @import("../c.zig").c;
