parsed: struct {
    source_file: ?[]const u8 = null,
    output_path: ?[]const u8 = null,
    file_name: ?[]const u8 = null,
    arg_ctx: arg_context = .none,
} = .{},
source_file: []const u8 = undefined,
output_path: []const u8 = undefined,
file_name: []const u8 = undefined,
process_args: std.process.ArgIterator = undefined,

const Args = @This();

const ValidationErrorSourceInvalid: []const u8 = "invalid --source file path";
const ValidationErrorOutputInvalid: []const u8 = "invalid --output path";
const ValidationErrorNameInvalid: []const u8 = "invalid out file --name";

pub const ArgsError = error{
    ValidationErrorSourceInvalid,
    ValidationErrorOutputInvalid,
    ValidationErrorNameInvalid,
};

const arg_context = enum {
    none,
    source_file,
    output_path,
    file_name,
};

pub fn init(allocator: std.mem.Allocator) !*Args {
    var process_args: std.process.ArgIterator = try std.process.argsWithAllocator(allocator);
    errdefer process_args.deinit();
    const args: *Args = try allocator.create(Args);
    args.* = .{
        .process_args = process_args,
    };
    return args;
}

pub fn deinit(self: *Args, allocator: std.mem.Allocator) void {
    self.process_args.deinit();
    allocator.destroy(self);
}

pub fn parse(self: *Args, _: std.mem.Allocator) !void {
    while (self.process_args.next()) |pa| self.handle_arg(pa);
}

pub fn validate(self: *Args) ArgsError!void {
    self.source_file = self.parsed.source_file orelse return ArgsError.ValidationErrorSourceInvalid;
    self.output_path = self.parsed.output_path orelse return ArgsError.ValidationErrorOutputInvalid;
    self.file_name = self.parsed.file_name orelse return ArgsError.ValidationErrorSourceInvalid;
}

pub fn debug(self: *Args) void {
    std.debug.print("args: \n", .{});
    std.debug.print("\t--source {s}\n", .{self.source_file});
    std.debug.print("\t--output {s}\n", .{self.output_path});
    std.debug.print("\t--name: {s}\n", .{self.file_name});
}

fn handle_arg(self: *Args, pa: [:0]const u8) void {
    switch (self.parsed.arg_ctx) {
        .none => {
            if (std.mem.eql(u8, "--source", pa)) {
                self.parsed.arg_ctx = .source_file;
            } else if (std.mem.eql(u8, "--output", pa)) {
                self.parsed.arg_ctx = .output_path;
            } else if (std.mem.eql(u8, "--name", pa)) {
                self.parsed.arg_ctx = .file_name;
            }
        },
        .source_file => {
            self.parsed.source_file = pa;
            self.parsed.arg_ctx = .none;
        },
        .output_path => {
            self.parsed.output_path = pa;
            self.parsed.arg_ctx = .none;
        },
        .file_name => {
            self.parsed.file_name = pa;
            self.parsed.arg_ctx = .none;
        },
    }
}

const std = @import("std");
