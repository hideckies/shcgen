const std = @import("std");
const common = @import("../common/lib.zig");

const testing = std.testing;

pub const allowed_payloads = [_][]const u8{
    "linux/x64/exec",
    "windows/x64/exec",
    "windows/x64/shell_bind_tcp",
    "windows/x64/shell_reverse_tcp",
};

pub fn printListPayloads() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try common.stdout.print("\nPayloads\n========\n\n{!s}\n\n", .{std.mem.join(
        allocator,
        "\n",
        &allowed_payloads,
    )});
}

pub fn validPayload(payload: []const u8) bool {
    for (allowed_payloads) |elem|
        if (std.mem.eql(u8, elem, payload))
            return true;
    return false;
}

test "test validPayload" {
    try testing.expectEqual(validPayload("windows/x64/exec"));
}
