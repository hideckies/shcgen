const std = @import("std");
const common = @import("../common/lib.zig");

const testing = std.testing;

pub const allowed_encoders = [_][]const u8{
    // "alpha",
    "xor",
};

pub fn printListEncoders() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try common.stdout.print("\nEncoders\n========\n\n{!s}\n\n", .{std.mem.join(
        allocator,
        "\n",
        &allowed_encoders,
    )});
}

pub fn validEncoder(encoder: []const u8) bool {
    for (allowed_encoders) |elem| {
        if (std.mem.eql(u8, elem, encoder)) {
            return true;
        }
    }
    return false;
}

test "test validEncoder" {
    try testing.expectEqual(validEncoder("alpha"));
}
