const std = @import("std");
const assembly = @import("../assembly/lib.zig");
const common = @import("../common/lib.zig");
const core = @import("../core/lib.zig");
const options = @import("../options/lib.zig");

// Reference:
// https://www.ired.team/offensive-security/code-injection-process-injection/writing-custom-shellcode-encoders-and-decoders
fn encodeXor(
    allocator: std.mem.Allocator,
    shellcode: []u8,
    asm_src_path: []const u8,
    asm_dest_path: []const u8,
) ![]u8 {
    var arr_xored = std.ArrayList(u8).init(allocator);
    defer arr_xored.deinit();

    // TODO: Randomiza this value.
    const key = 0x33;
    const key_str = try std.fmt.allocPrint(allocator, "0x{x}", .{key});

    for (shellcode) |c| {
        // XOR
        try arr_xored.append(c ^ key);
    }

    const encoded_shellcode = arr_xored.items;
    const shellcode_size = encoded_shellcode.len;
    const shellcode_size_str = try std.fmt.allocPrint(allocator, "0x{x}", .{shellcode_size});

    // Create encoded shellcode string
    var arr_encoded_shellcode_str = std.ArrayList([]u8).init(allocator);
    for (encoded_shellcode) |c| {
        try arr_encoded_shellcode_str.append(try std.fmt.allocPrint(allocator, "0x{x}", .{c}));
    }
    const encoded_shellcode_str = try std.mem.join(allocator, ",", arr_encoded_shellcode_str.items);

    // Decoder assembly
    const asm_code =
        \\_start:
        \\  jmp short shellcode
        \\
        \\decoder:
        \\  pop rax                     ; Store encodedShellcode address in rax
        \\
        \\setup:
        \\  xor rcx, rcx                ; Reset rcx to 0. It's used as a loop counter.
        \\  mov rdx, {SHELLCODE_SIZE}   ; mov rdx, 0x12   ; shellcode size
        \\
        \\decoderStub:
        \\  cmp rcx, rdx                ; Check if we've iterated all the encoded bytes.
        \\  je encodedShellcode         ; Jump to encodedShellcode, actually now contains the decoded shellcode.
        \\
        \\  ; Decode encoded shellcode
        \\  xor byte [rax], {XOR_KEY}
        \\
        \\  ; Incrementing for loop
        \\  inc rax                     ; Point rax to the nexe encoded shellcode byte.
        \\  inc rcx                     ; Increment a loop counter.
        \\  jmp short decoderStub       ; Repeat decoding process.
        \\
        \\shellcode:
        \\  call decoder                ; Jump to decoder label. This pushes the address of encodedShellcode to the stack.
        \\  encodedShellcode: db {ENCODED_SHELLCODE}    ; e.g. 0x2a,0x39,0x2c,...
    ;

    // Replace {SHELLCODE_SIZE}
    var asm_code_size = std.mem.replacementSize(u8, asm_code, "{SHELLCODE_SIZE}", shellcode_size_str);
    const asm_code_new_2 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code, "{SHELLCODE_SIZE}", shellcode_size_str, asm_code_new_2);
    // Replace {XOR_KEY}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_2, "{XOR_KEY}", key_str);
    const asm_code_new_1 = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_2, "{XOR_KEY}", key_str, asm_code_new_1);
    // Replace {ENCODED_SHELLCODE}
    asm_code_size = std.mem.replacementSize(u8, asm_code_new_1, "{ENCODED_SHELLCODE}", encoded_shellcode_str);
    const asm_code_new = try allocator.alloc(u8, asm_code_size);
    _ = std.mem.replace(u8, asm_code_new_1, "{ENCODED_SHELLCODE}", encoded_shellcode_str, asm_code_new);

    // Compile
    try assembly.utils.compileWithNasm(
        allocator,
        "win64",
        asm_src_path,
        asm_dest_path,
        asm_code_new,
    );

    // Extract shellcode
    const shellcode_new = core.generate.extractShellcode(allocator, asm_dest_path);

    return shellcode_new;
}

pub fn encode(
    allocator: std.mem.Allocator,
    shellcode: []u8,
    opts: options.Options,
) ![]u8 {
    const asm_src_path = "/tmp/shcgen_tmp.asm";
    const asm_dest_path = "/tmp/shcgen_tmp.o";

    var shellcode_enc: ?[]u8 = null;

    if (std.mem.eql(u8, opts.encoder.?, "xor")) {
        shellcode_enc = try encodeXor(
            allocator,
            shellcode,
            asm_src_path,
            asm_dest_path,
        );
    } else {
        try common.stdout.print("[x] Invalid encoder: {s}\n", .{opts.encoder.?});
        shellcode_enc = shellcode;
    }

    // Delete nasm src/dest file
    try std.fs.cwd().deleteFile(asm_src_path);
    try std.fs.cwd().deleteFile(asm_dest_path);

    return shellcode_enc.?;
}