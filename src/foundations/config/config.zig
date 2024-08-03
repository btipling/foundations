fullscreen: bool = false,
maximized: bool = false,
decorated: bool = true,
width: u32 = 0,
height: u32 = 0,
near: f32 = 0.1,
far: f32 = 500,
fovy: f32 = 45,
allocator: std.mem.Allocator,

const Config = @This();

pub fn init(allocator: std.mem.Allocator) *Config {
    const c = allocator.create(Config) catch @panic("OOM");
    c.* = .{
        .allocator = allocator,
    };
    return c;
}

pub fn deinit(self: *Config) void {
    self.allocator.destroy(self);
}

pub fn open(self: *Config) void {
    const config_bytes = config_file.read(self.allocator);
    const b = config_bytes orelse {
        std.log.info("No config found", .{});
        return;
    };
    defer self.allocator.free(b);
    std.log.info("config found", .{});

    var p = parser.init(self.allocator, b);
    p.parse();
    defer p.deinit();
    if (p.map.get("fullscreen")) |v| {
        self.fullscreen = std.mem.eql(u8, v, "true");
    }
    if (p.map.get("maximized")) |v| {
        self.fullscreen = std.mem.eql(u8, v, "true");
    }
    if (p.map.get("decorated")) |v| {
        self.fullscreen = std.mem.eql(u8, v, "true");
    }
    if (p.map.get("width")) |v| {
        self.width = std.fmt.parseInt(u32, v, 10) catch 0;
    }
    if (p.map.get("height")) |v| {
        self.height = std.fmt.parseInt(u32, v, 10) catch 0;
    }
}

pub fn print(self: *Config) void {
    std.log.info("Config:", .{});
    std.log.info("fullscreen: {any}", .{self.fullscreen});
    std.log.info("maximized: {any}", .{self.maximized});
    std.log.info("decorated: {any}", .{self.decorated});
    std.log.info("width: {d}", .{self.width});
    std.log.info("height: {d}\n", .{self.height});
}

pub fn save(self: Config) void {
    var buf: [config_file.max_file_size]u8 = undefined;
    const b = std.fmt.bufPrint(
        &buf,
        "fullscreen={s};\nmaxmized={s};\ndecorated={s};\nwidth={d};\nheight={d};\n",
        .{
            if (self.fullscreen) "true" else "false",
            if (self.maximized) "true" else "false",
            if (self.decorated) "true" else "false",
            self.width,
            self.height,
        },
    ) catch @panic("failed to writ config");
    config_file.write(self.allocator, b);
    std.log.info("saved config", .{});
}

const std = @import("std");
const config_file = @import("config_file.zig");
pub const parser = @import("config_parser.zig");
