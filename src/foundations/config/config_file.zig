const app_name: []const u8 = "foundations_game_engine";
const config_file_name: []const u8 = "config.txt";
const max_file_size: usize = 4096 << 8;

pub fn read(allocator: std.mem.Allocator) ?[]u8 {
    const app_data_dir_path = std.fs.getAppDataDir(allocator, app_name) catch @panic("no app data dir");
    defer allocator.free(app_data_dir_path);
    std.debug.print("app_data_dir_path: {s}\n", .{app_data_dir_path});
    std.fs.makeDirAbsolute(app_data_dir_path) catch {}; // Try to create and fail silently.
    var app_data_dir = std.fs.openDirAbsolute(app_data_dir_path, .{}) catch @panic("failed to open app dir");
    defer app_data_dir.close();
    var fd = app_data_dir.openFile(config_file_name, .{}) catch return null;
    defer fd.close();
    return fd.readToEndAlloc(allocator, max_file_size) catch return null;
}

pub fn write(allocator: std.mem.Allocator, config: []const u8) void {
    const app_data_dir_path = std.fs.getAppDataDir(allocator, app_name) catch @panic("no app data dir");
    defer allocator.free(app_data_dir_path);
    std.fs.makeDirAbsolute(app_data_dir_path) catch {}; // Try to create and fail silently.
    var app_data_dir = std.fs.openDirAbsolute(app_data_dir_path, .{}) catch @panic("failed to open app dir");
    defer app_data_dir.close();
    var fd = app_data_dir.createFile(config_file_name, .{}) catch @panic("failed to open app config for saving");
    defer fd.close();
    fd.writeAll(config) catch @panic("failed to write config");
}

const std = @import("std");
