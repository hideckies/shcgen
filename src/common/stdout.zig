const clap = @import("clap");
const std = @import("std");
const config = @import("config");

const testing = std.testing;

pub fn print(comptime _format: []const u8, args: anytype) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print(_format, args);

    try bw.flush(); // don't forget to flush!
}

pub fn printBanner() !void {
    // TODO: Implement more elegant banner.
    try print("\nShcgen v{s}\n\n", .{config.version});
}

pub fn printUsage(params: *const [9]clap.Param(clap.Help)) !void {
    try printBanner();

    // USAGE
    try print("Usage:\n\n    shcgen ", .{});
    try clap.usage(std.io.getStdErr().writer(), clap.Help, params);
    try print("\n\n", .{});
    try clap.help(std.io.getStdErr().writer(), clap.Help, params, .{});

    try print("\n\n", .{});

    // EXAMPLE
    try print("Example:\n\n   {s}\n\n", .{"shcgen -p windows/x64/exec --cmd calc -f raw -o ./shellcode.bin"});
}

pub fn printVersion() !void {
    try print("Shcgen v{s}\n", .{config.version});
}

test "test print" {
    try testing.expect(print("Test for {s}.\n", .{"Shcgen"}));
}
