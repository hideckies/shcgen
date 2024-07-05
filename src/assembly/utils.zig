const std = @import("std");
const common = @import("../common/lib.zig");

pub fn compileWithNasm(
    allocator: std.mem.Allocator,
    format: []const u8,
    asm_src_path: []const u8,
    asm_dest_path: []const u8,
    asm_code: []const u8,
) !void {
    // Write assembly code to a temp file.
    const file = try std.fs.cwd().createFile(
        asm_src_path,
        .{ .read = true },
    );
    defer file.close();
    try file.writeAll(asm_code);

    // Compile
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "nasm",
            "-f",
            format,
            "-o",
            asm_dest_path,
            asm_src_path,
        },
        .max_output_bytes = 1024,
    }) catch |err| {
        try common.stdout.print("nasm Error: {s}\n", .{@errorName(err)});
        return err;
    };
    if (result.stderr.len > 0) {
        try common.stdout.print("objdump stderr: {s}\n", .{result.stderr});
        return;
    }
}
