const std = @import("std");
const common = @import("../common/lib.zig");

const testing = std.testing;

pub const allowed_formats = [_][]const u8{
    "hex",
    "raw",
};

pub fn printListFormats() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try common.stdout.print("\nFormats\n=======\n\n{!s}\n\n", .{std.mem.join(
        allocator,
        "\n",
        &allowed_formats,
    )});
}

pub fn validFormat(format: []const u8) bool {
    for (allowed_formats) |elem|
        if (std.mem.eql(u8, elem, format))
            return true;
    return false;
}

test "test validFormats" {
    try testing.expectEqual(validFormat("raw"));
}
