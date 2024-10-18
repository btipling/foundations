allocator: std.mem.Allocator,
ctx: Ctx,

const Compiler = @This();

var cwd_buf: [1000]u8 = undefined;

pub const Ctx = struct {
    cwd: []const u8,
    args: *Args,
};

pub fn init(allocator: std.mem.Allocator) !*Compiler {
    const c: *Compiler = try allocator.create(Compiler);
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

pub fn run(self: *Compiler) !void {
    self.ctx.args.parse(self.allocator) catch |err| std.debug.panic("{any}\n", .{err});
    self.ctx.args.validate() catch |err| std.debug.panic("{any}\n", .{err});
    self.ctx.args.debug();

    const source_file: *File = try File.init(self.allocator, self.ctx, self.ctx.args.source_file);
    defer source_file.deinit(self.allocator);
    try source_file.read(self.allocator);
    if (source_file.bytes) |bytes| std.debug.print("numbytes: {d}\n", .{bytes.len});

    var parser: *Parser = try Parser.init(self.allocator, source_file);
    defer parser.deinit(self.allocator);

    try parser.parse(self.allocator);

    parser.debug();

    var inc = try Includer.init(self.allocator, source_file, self.ctx, parser);
    defer inc.deinit(self.allocator);

    try inc.fetch(self.allocator, self.ctx);
    try inc.include(self.allocator);
    try inc.output_file.write(self.allocator);
}

pub fn deinit(self: *Compiler) void {
    self.ctx.args.deinit(self.allocator);
    self.allocator.destroy(self);
}

const std = @import("std");
const Args = @import("Args.zig");
const File = @import("File.zig");
const Parser = @import("Parser.zig");
const Includer = @import("Includer.zig");
