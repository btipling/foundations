const app_name: []const u8 = "foundations_game_engine";
pub const max_file_size: usize = 4096 << 12;

pub const LoaderError = error{
    FileNotFound,
};

pub fn Loader(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        cache: std.StringArrayHashMapUnmanaged(*T) = .empty,
        absolute_root_path: []u8,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, asset_path: []const u8) *Self {
            const app_data_dir_path = std.fs.getAppDataDir(allocator, app_name) catch @panic("no app data dir");
            defer allocator.free(app_data_dir_path);

            const absolute_path = std.mem.concat(
                allocator,
                u8,
                &[_][]const u8{
                    app_data_dir_path,
                    "/",
                    asset_path,
                },
            ) catch @panic("OOM");
            errdefer allocator.free(absolute_path);

            std.fs.makeDirAbsolute(absolute_path) catch {}; // Try to create and fail silently.
            // Make sure it can be accessed.
            var asset_dir = std.fs.openDirAbsolute(absolute_path, .{}) catch @panic("failed to open asset dir");
            defer asset_dir.close();
            std.debug.print("accessed {s}\n", .{absolute_path});

            const loader = allocator.create(Self) catch @panic("OOM");
            errdefer allocator.destroy(loader);
            loader.* = .{
                .allocator = allocator,
                .absolute_root_path = absolute_path,
            };
            return loader;
        }

        pub fn deinit(self: *Self) void {
            for (self.cache.values()) |v| {
                v.deinit(self.allocator);
            }
            self.allocator.free(self.absolute_root_path);
            self.absolute_root_path = undefined;
            self.cache.deinit(self.allocator);
            self.cache = undefined;
            self.allocator.destroy(self);
        }

        pub fn loadAsset(self: *Self, file_name: []const u8) LoaderError!*T {
            if (self.cache.contains(file_name)) {
                return self.cache.get(file_name).?;
            }
            const data = try self.read(file_name);
            errdefer self.allocator.free(data);

            var t: *T = self.allocator.create(T) catch @panic("OOM");
            errdefer self.allocator.destroy(t);

            t.init(self.allocator, data, file_name);
            errdefer t.deinit();

            self.cache.put(self.allocator, file_name, t) catch @panic("OOM");
            return t;
        }

        fn read(self: *Self, file_name: []const u8) ![]u8 {
            std.debug.print("loading asset: {s} in {s}\n", .{ file_name, self.absolute_root_path });
            var app_data_dir = std.fs.openDirAbsolute(self.absolute_root_path, .{}) catch @panic("failed to open app dir");
            defer app_data_dir.close();
            var fd = app_data_dir.openFile(file_name, .{}) catch |err| {
                if (err == std.fs.File.OpenError.FileNotFound) {
                    return LoaderError.FileNotFound;
                }
                @panic("Failed opening asset");
            };
            defer fd.close();
            return fd.readToEndAlloc(self.allocator, max_file_size) catch @panic("asset too big");
        }
    };
}

const std = @import("std");
