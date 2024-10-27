allocator: std.mem.Allocator,
ctx: Ctx,

const Generator = @This();

const GeneratorError = error{
    NoOutputError,
};

var cwd_buf: [1000]u8 = undefined;

pub const Ctx = struct {
    cwd: []const u8,
    args: *Args,
};

pub fn init(allocator: std.mem.Allocator) !*Generator {
    const c: *Generator = try allocator.create(Generator);
    errdefer allocator.destroy(c);

    const cwd = try std.fs.cwd().realpath(".", &cwd_buf);
    c.* = .{
        .allocator = allocator,
        .ctx = .{
            .cwd = cwd,
            .args = Args.init(allocator) catch |err| std.debug.panic("{any}\n", .{err}),
        },
    };
    return c;
}

pub fn run(self: *Generator) !void {
    self.ctx.args.parse(self.allocator) catch |err| std.debug.panic("{any}\n", .{err});
    self.ctx.args.validate() catch |err| std.debug.panic("{any}\n", .{err});
    self.ctx.args.debug();
}

pub fn deinit(self: *Generator) void {
    self.ctx.args.deinit(self.allocator);
    self.allocator.destroy(self);
}

const std = @import("std");
pub const Args = @import("Args.zig");
const File = @import("File.zig");

const StripedPattern = @import("StripedPattern.zig");
const Marble = @import("Marble.zig");
