// Reference:
// ; https://github.com/rapid7/metasploit-framework/blob/master/external/source/shellcode/windows/x64/src/block/block_exitfunk.asm
pub const asm_code =
    \\exitfunk:
    \\  mov ebx, 0x0A2A1DE0     ; The EXITFUNK ( hash("kernel32.dll", "ExitThread") ) as specified by user...
    \\  mov r10d, 0x9DBD95A6    ; hash("kernel32.dll", "GetVersion")
    \\  call rbp                ; GetVersion(); (AL will = major version and AH will = minor version)
    \\  add rsp, 40             ; Cleanup the default param space on stack
    \\  cmp al, byte 6          ; If we are not running on Windows Vista, 2008 or 7
    \\  jl short goodbye        ; Then just call the exit function...
    \\  cmp bl, 0xe0            ; If we are trying a call to kernel32.dll!ExitThread on Windows Vista, 2008 or 7
    \\  jne short goodbye
    \\  mov ebx, 0x6F721347     ; Then we substitute the EXITFUNK to that of ntdll.dll!RtlExitUserThread
    \\
    \\  ; We now perform the actual call to the exit function
    \\
    \\goodbye:
    \\  push byte 0
    \\  pop rcx         ; Set the exit function parameter
    \\  mov r10d, ebx   ; Place the correct EXITFUNK into r10d
    \\  call rbp        ; Call EXITFUNK(0);
;
