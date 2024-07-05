const clap = @import("clap");
const std = @import("std");
const common = @import("../common/lib.zig");

pub const encoder = @import("encoder.zig");
pub const format = @import("format.zig");
pub const payload = @import("payload.zig");

pub const Options = struct {
    encoder: ?[]const u8,
    format: ?[]const u8,
    payload: ?[]const u8,
    payload_exec_cmd: ?[]const u8,
    lhost: ?[]const u8,
    lport: ?usize,
    output: ?[]const u8,
};

pub fn set_options(args: anytype) !?Options {
    var opts = Options{
        .encoder = null,
        .format = null,
        .payload = null,
        .payload_exec_cmd = null,
        .lhost = null,
        .lport = null,
        .output = null,
    };

    // Encoder
    if (args.encoder) |e| {
        if (encoder.validEncoder(e)) {
            opts.encoder = e;
        } else {
            try common.stdout.print(
                "Invalid encoder: {s}\nUse '--list encoders' to display available encoders.\n",
                .{e},
            );
            return null;
        }
    }

    // Format
    if (args.format) |f| {
        if (format.validFormat(f)) {
            opts.format = f;
        } else {
            try common.stdout.print(
                "Invalid format: {s}\nUse '--list formats' to display available payloads.\n",
                .{f},
            );
            return null;
        }
    } else {
        try common.stdout.print("No format specified. Use '-f/--format' option.\n", .{});
        return null;
    }

    // Paylaod
    if (args.payload) |p| {
        if (payload.validPayload(p)) {
            opts.payload = p;
        } else {
            try common.stdout.print(
                "Invalid payload: {s}\nUse '--list payloads' to display available payloads.\n",
                .{p},
            );
            return null;
        }
    } else {
        try common.stdout.print("No payload specified. Use -p/--payload option.\n", .{});
        return null;
    }

    // If the payload is 'exec', we need to set the '--cmd' option.
    if (std.mem.containsAtLeast(u8, opts.payload.?, 1, "exec")) {
        if (args.cmd) |c| {
            // opt_payload_exec_cmd = c;
            opts.payload_exec_cmd = c;
        } else {
            try common.stdout.print(
                "Not enough argument: We must set '--cmd' for this payload.\n",
                .{},
            );
            return null;
        }
    }

    // If the payload is 'shell_reverse_tcp', we need to set the '--lhost' and '--lport' option.
    if (std.mem.containsAtLeast(u8, opts.payload.?, 1, "shell_reverse_tcp")) {
        if (args.lhost) |h| {
            opts.lhost = h;
        } else {
            try common.stdout.print(
                "Not enough argument: We must set '--lhost' and '--lport' for this payload.\n",
                .{},
            );
            return null;
        }
        if (args.lport) |p| {
            opts.lport = p;
        } else {
            try common.stdout.print(
                "Not enough argument: We must set '--lhost' and '--lport' for this payload.\n",
                .{},
            );
            return null;
        }
    }

    // Output
    if (args.output) |o| {
        opts.output = o;
    }

    return opts;
}
