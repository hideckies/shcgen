const std = @import("std");
const assembly = @import("../assembly/lib.zig");
const common = @import("../common/lib.zig");
const options = @import("../options/lib.zig");

/// Extract shellcode.
// usefule command:
//   for i in $(objdump -D /tmp/tmp.o | grep "^ " | cut -f2); do echo -n "\x$i" ; done
pub fn extractShellcode(
    allocator: std.mem.Allocator,
    nasm_output_temp: []const u8,
) ![]u8 {
    var shellcode = std.ArrayList(u8).init(allocator);
    defer shellcode.deinit();

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "objdump",
            "-D",
            nasm_output_temp,
        },
    }) catch |err| {
        try common.stdout.print("objdump Error: {s}\n", .{@errorName(err)});
        return err;
    };
    if (result.stderr.len > 0) {
        try common.stdout.print("objdump stderr: {s}\n", .{result.stderr});
        return result.stderr;
    }

    const output_str = try std.fmt.allocPrint(allocator, "{s}", .{result.stdout});
    var output_it = std.mem.splitSequence(u8, output_str, "\n");
    while (output_it.next()) |line| {
        if (line.len == 0 or line[0] != ' ') continue;

        // Cut off multiple spaces
        const spl_size = std.mem.replacementSize(u8, line, " ", "");
        const line_spl = try allocator.alloc(u8, spl_size);
        _ = std.mem.replace(u8, line, " ", "", line_spl);

        // Extract hex value (2nd position in the line) and store them.
        var line_it = std.mem.splitSequence(u8, line_spl, "\t");
        var idx: u32 = 0;
        while (line_it.next()) |l| {
            if (idx == 1) {
                var hex_val = std.mem.window(u8, l, 2, 2);
                while (hex_val.next()) |h| {
                    const h_int = try std.fmt.parseInt(u8, h, 16);
                    try shellcode.append(h_int);
                }
                break;
            }
            idx += 1;
        }
    }

    const items = shellcode.items;
    return try allocator.dupe(u8, items);
}

// const GenerateError = error{
//     NasmError,
//     ObjdumpError,
// };

/// Generate shellcode
pub fn generate(
    allocator: std.mem.Allocator,
    opts: options.Options,
) !?[]u8 {
    const asm_src_path = "/tmp/shcgen_tmp.asm";
    const asm_dest_path = "/tmp/shcgen_tmp.o";

    // Compile assembly
    if (std.mem.eql(u8, opts.payload.?, "linux/x64/exec")) {
        try assembly.linux_x64_exec.compile(
            allocator,
            asm_src_path,
            asm_dest_path,
            opts.payload_exec_cmd.?,
        );
    } else if (std.mem.eql(u8, opts.payload.?, "windows/x64/exec")) {
        try assembly.windows_x64_exec.compile(
            allocator,
            asm_src_path,
            asm_dest_path,
            opts.payload_exec_cmd.?,
        );
    } else if (std.mem.eql(u8, opts.payload.?, "windows/x64/shell_bind_tcp")) {
        try assembly.windows_x64_shell_bind_tcp.compile(
            allocator,
            asm_src_path,
            asm_dest_path,
            opts,
        );
    } else if (std.mem.eql(u8, opts.payload.?, "windows/x64/shell_reverse_tcp")) {
        try assembly.windows_x64_shell_reverse_tcp.compile(
            allocator,
            asm_src_path,
            asm_dest_path,
            opts,
        );
    } else {
        try common.stdout.print("[x] Invalid payload: {s}\n", .{opts.payload.?});
        return null;
    }

    const shellcode = try extractShellcode(
        allocator,
        asm_dest_path,
    );

    // Delete nasm src/dest file
    try std.fs.cwd().deleteFile(asm_src_path);
    try std.fs.cwd().deleteFile(asm_dest_path);

    return shellcode;
}
