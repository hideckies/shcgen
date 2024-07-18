const clap = @import("clap");
const std = @import("std");
const common = @import("common/lib.zig");
const options = @import("options/lib.zig");
const core = @import("core/lib.zig");

const testing = std.testing;

pub fn main() !void {
    // Parse arguments
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-b, --badchars    <STR>   Bad characters to allow the shellcode works without problems.
        \\--cmd             <STR>   Command to be executed. It's required for 'exec' payload.
        \\-e, --encoder     <STR>   Encoder. Use '--list encoders' to display available encoders.
        \\-f, --format      <STR>   Output format. Use '--list formats' to display available options.
        \\-h, --help                Display the usage.
        \\-i, --iterations  <INT>   The number of times to encode the shellcode.
        \\-l, --list        <STR>   Display list of encoders, formats or payloads.
        \\--lhost           <STR>   Local host (default: 127.0.0.1) to be used for 'shell_reverse_tcp' payload.
        \\--lport           <INT>   Local port (default: 4444) to be used for 'shell_reverse_tcp' payload.
        \\-o, --output      <FILE>  Output file path.
        \\-p, --payload     <STR>   Payload to use. Use '--list payloads' to display available payloads.
        \\-v, --version             Display the version of Shcgen.
    );

    const parsers = comptime .{
        .STR = clap.parsers.string,
        .FILE = clap.parsers.string,
        .INT = clap.parsers.int(usize, 10),
    };

    // Parse command-line
    var res = clap.parse(clap.Help, &params, parsers, .{
        .allocator = gpa.allocator(),
    }) catch |err| {
        try common.stdout.print("Invalid Command: {}\nUse '-h/--help' to see the usage.\n", .{err});
        return;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return common.stdout.printUsage(&params);
    if (res.args.list) |l| {
        if (std.mem.eql(u8, l, "encoders")) {
            return options.encoder.printListEncoders();
        } else if (std.mem.eql(u8, l, "formats")) {
            return options.format.printListFormats();
        } else if (std.mem.eql(u8, l, "payloads")) {
            return options.payload.printListPayloads();
        } else {
            return common.stdout.print("Invalid option for '--list'.\n", .{});
        }
    }
    if (res.args.version != 0)
        return common.stdout.printVersion();

    // Allocate memory
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Set options from command line arguments.
    const opts = try options.setOptions(allocator, res.args);
    if (opts == null) {
        return;
    }

    // Generate shellcode
    var shellcode = try core.generate.generate(allocator, opts.?);
    if (shellcode == null) {
        try common.stdout.print("[x] Shellcode generatoin failed.\n", .{});
        return;
    }

    // Encode shellcode
    if (opts.?.encoder != null) {
        shellcode = try core.encoder.encode(allocator, shellcode.?, opts.?);
    }

    // Output
    try core.output.output(
        allocator,
        shellcode.?,
        opts.?,
    );

    return;
}

test "test main" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try testing.expectEqual(@as(i32, 42), list.pop());
}
