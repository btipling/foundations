allocator: std.mem.Allocator,

const Compiler = @This();

pub fn init(allocator: std.mem.Allocator) *Compiler {
    const c: *Compiler = allocator.create(Compiler) catch @panic("OOM");
    c.* = .{
        .allocator = allocator,
    };
    return c;
}

const arg_context = enum {
    none,
    source_file,
    output_path,
    file_name,
};

pub fn run(self: *Compiler) void {
    var args = std.process.argsWithAllocator(self.allocator) catch @panic("OOM");
    defer args.deinit();

    var source_file: ?[]const u8 = null;
    var output_path: ?[]const u8 = null;
    var file_name: ?[]const u8 = null;
    var arg_ctx: arg_context = .none;

    var args_len: usize = 0;
    while (args.next()) |arg| {
        args_len += 1;
        switch (arg_ctx) {
            .none => {
                if (std.mem.eql(u8, "--source", arg)) {
                    arg_ctx = .source_file;
                } else if (std.mem.eql(u8, "--output", arg)) {
                    arg_ctx = .output_path;
                } else if (std.mem.eql(u8, "--name", arg)) {
                    arg_ctx = .file_name;
                }
            },
            .source_file => {
                source_file = arg;
                arg_ctx = .none;
            },
            .output_path => {
                output_path = arg;
                arg_ctx = .none;
            },
            .file_name => {
                file_name = arg;
                arg_ctx = .none;
            },
        }
    }
    if (source_file == null or output_path == null or file_name == null) {
        std.log.err("Usage: $ fssc.exe --source ./path/to/shader/vert.glsl --output ./path/to/output/ --name my_cool_vert_shader", .{});
        if (source_file == null) std.log.err("missing --source\n", .{});
        if (output_path == null) std.log.err("missing --output\n", .{});
        if (file_name == null) std.log.err("missing --name\n", .{});
        std.process.exit(1);
    }
    std.log.info("Generating {s}{s}.glsl via {s}\n", .{ output_path.?, file_name.?, source_file.? });
    var buf: [1000]u8 = undefined;
    const cwd_path = std.fs.cwd().realpath(".", &buf) catch @panic("can\t read real path");
    std.debug.print("cwd_path: {s}\n", .{cwd_path});
    const full_source_path = std.mem.concat(self.allocator, u8, &[_][]const u8{ cwd_path, source_file.? }) catch @panic("OOM");
    defer self.allocator.free(full_source_path);
    std.debug.print("full_source_path: {s}\n", .{full_source_path});
    // const cwd = std.fs.openDirAbsolute(absolute_path: []const u8, flags: Dir.OpenOptions)
}

pub fn deinit(self: *Compiler) void {
    self.allocator.destroy(self);
}

const std = @import("std");
