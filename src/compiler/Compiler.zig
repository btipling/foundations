allocator: std.mem.Allocator,
ctx: Ctx,

const Compiler = @This();

const CompilerError = error{
    NoOutputError,
};

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

// Caller owns returned bytes.
pub fn runWithBytes(allocator: std.mem.Allocator, ctx: Ctx, in: []const u8) ![]const u8 {
    const source_file: *File = try File.initWithEmbed(allocator, in);
    defer source_file.deinit(allocator);

    var parser: *Parser = try Parser.init(allocator, source_file);
    defer parser.deinit(allocator);

    try parser.parse(allocator);

    var inc = try Includer.init(allocator, source_file, ctx, parser);
    defer inc.deinit(allocator);

    try inc.fetch(allocator, ctx);
    try inc.include(allocator);
    const bytes = inc.output_file.bytes orelse return CompilerError.NoOutputError;
    return try allocator.dupe(u8, bytes);
}

pub fn deinit(self: *Compiler) void {
    self.ctx.args.deinit(self.allocator);
    self.allocator.destroy(self);
}

const std = @import("std");
pub const Args = @import("Args.zig");
const File = @import("File.zig");
const Parser = @import("Parser.zig");
const Includer = @import("Includer.zig");
