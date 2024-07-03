const std = @import("std");
const common = @import("../common/lib.zig");
const options = @import("../options/lib.zig");

// Display shellcode in specified format.
fn display_shellcode(
    allocator: std.mem.Allocator,
    shellcode: []const u8,
    opts: options.Options,
) !void {
    for (shellcode) |c| {
        if (std.mem.eql(u8, opts.format.?, "hex")) {
            const item_hex_str = try std.fmt.allocPrint(allocator, "\\x{x:0>2}", .{c});
            try common.stdout.print("{s}", .{item_hex_str});
        } else if (std.mem.eql(u8, opts.format.?, "raw")) {
            try common.stdout.print("{d}", .{c});
        }
    }
    try common.stdout.print("\n", .{});
}

// Save shellcode to a specified output file path.
fn save_shellcode(
    allocator: std.mem.Allocator,
    shellcode: []const u8,
    opts: options.Options,
) !void {
    const file = try std.fs.cwd().createFile(
        opts.output.?,
        .{ .read = true },
    );
    defer file.close();

    if (std.mem.eql(u8, opts.format.?, "hex")) {
        var bytes = std.ArrayList([]u8).init(allocator);
        defer bytes.deinit();

        for (shellcode) |c| {
            const item_hex_str = try std.fmt.allocPrint(allocator, "\\x{x:0>2}", .{c});
            try bytes.append(item_hex_str);
        }

        const bytes_join = try std.mem.join(allocator, "", bytes.items);

        try file.writeAll(bytes_join);
    } else if (std.mem.eql(u8, opts.format.?, "raw")) {
        try file.writeAll(shellcode);
    }
}

// Output a generated shellcode.
pub fn output(
    allocator: std.mem.Allocator,
    shellcode: []const u8,
    opts: options.Options,
) !void {
    if (opts.output == null) {
        try display_shellcode(
            allocator,
            shellcode,
            opts,
        );
    } else {
        try save_shellcode(
            allocator,
            shellcode,
            opts,
        );
    }
}
