const std = @import("std");

/// Parse IP Address
pub fn parseIpAddress(ip_str: []const u8) ![4]u8 {
    var result: [4]u8 = undefined;
    var index: usize = 0;

    var parts = std.mem.splitScalar(u8, ip_str, '.');

    while (index < 4) {
        const part = parts.next();
        if (part == null) {
            break;
        }

        const num = try std.fmt.parseInt(u8, part.?, 10);
        if (num < 0 or 255 < num) {
            return error.InvalidIpAddress;
        }

        result[index] = @intCast(num);
        index += 1;
    }

    if (index != 4) {
        return error.InvalidIpAddress;
    }

    return result;
}

/// Parse Port
pub fn parsePort(port: usize) [2]u8 {
    return [2]u8{
        @as(u8, @truncate((port >> 8) & 0xFF)),
        @as(u8, @truncate(port & 0xFF)),
    };
}
