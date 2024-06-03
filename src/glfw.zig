const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const GLFWError = error{
    Fatal,
};

// void error_callback(int error, const char* description)
// {
//     fputs(description, stderr);
// }

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("GLFW Error: {d} {s}\n", .{ err, description });
}

pub fn init() !void {
    if (c.glfwInit() == 0) {
        std.debug.print("could not init glfw", .{});
        return GLFWError.Fatal;
    }
    _ = c.glfwSetErrorCallback(errorCallback);
    std.debug.print("successfully inited glfw", .{});
}

pub fn deinit() void {
    c.glfwTerminate();
}

const std = @import("std");
