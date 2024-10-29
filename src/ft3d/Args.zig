parsed: struct {
    texture_type: ?[]const u8 = null,
    output_path: ?[]const u8 = null,
    file_name: ?[]const u8 = null,
    arg_ctx: arg_context = .none,
} = .{},
texture_type: texture_type_opt = undefined,
output_path: []const u8 = undefined,
file_name: []const u8 = undefined,
process_args: std.process.ArgIterator = undefined,

const Args = @This();

const ValidationErrorTypeInvalid: []const u8 = "invalid --type texture type name";
const ValidationErrorOutputInvalid: []const u8 = "invalid --output path";
const ValidationErrorNameInvalid: []const u8 = "invalid out file --name";

pub const ArgsError = error{
    ValidationErrorTypeInvalid,
    ValidationErrorOutputInvalid,
    ValidationErrorNameInvalid,
};

const arg_context = enum {
    none,
    texture_type,
    output_path,
    file_name,
};

pub const texture_type_opt = enum {
    striped,
    marble,
    wood,
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
    self.texture_type = blk: {
        const tts: []const u8 = self.parsed.texture_type orelse return ArgsError.ValidationErrorTypeInvalid;
        if (std.mem.eql(u8, "marble", tts)) {
            break :blk .marble;
        } else if (std.mem.eql(u8, "wood", tts)) {
            break :blk .wood;
        } else if (std.mem.eql(u8, "striped", tts)) {
            break :blk .striped;
        }
        return ArgsError.ValidationErrorTypeInvalid;
    };
    self.output_path = self.parsed.output_path orelse return ArgsError.ValidationErrorOutputInvalid;
    self.file_name = self.parsed.file_name orelse return ArgsError.ValidationErrorTypeInvalid;
}

pub fn debug(self: *Args) void {
    std.debug.print("args: \n", .{});
    std.debug.print("\t--type {any}\n", .{self.texture_type});
    std.debug.print("\t--output {s}\n", .{self.output_path});
    std.debug.print("\t--name: {s}\n", .{self.file_name});
}

fn handle_arg(self: *Args, pa: [:0]const u8) void {
    switch (self.parsed.arg_ctx) {
        .none => {
            if (std.mem.eql(u8, "--type", pa)) {
                self.parsed.arg_ctx = .texture_type;
            } else if (std.mem.eql(u8, "--output", pa)) {
                self.parsed.arg_ctx = .output_path;
            } else if (std.mem.eql(u8, "--name", pa)) {
                self.parsed.arg_ctx = .file_name;
            }
        },
        .texture_type => {
            self.parsed.texture_type = pa;
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
