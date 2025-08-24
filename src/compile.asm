strdef PUNCTUATORS, 0x20, 0x0A, 0x0D, 0x09, '\', '$', '@', '[', ']'
WSP_DWORD: dd 0x200A0D09 ; the whitespace characters in a string like "\t\r\n "

SUBRT compile ; length (CompiledProgram *ret, string *src, length)
    var vr12, qword r12
    var vr13, qword r13
    var vr14, qword r14
    var vret, qword rdi
BEGIN
    mov r12, rdx
    mov r13, rsi

    or r12, r12
    jz .done
    
    ; main loop
    xor r14d, r14d ; counter
    .main_loop:
        xor ecx, ecx
        mov cl, 0x04
        movzx eax, byte [r13 + r14]
        mov rdi, WSP_DWORD
        repne scasb
        je .main_loop.continue

        cmp al, '\'
        jne .not_comment
            inc r14d
            lea rdi, [r13 + r14]
            mov ecx, r12d
            sub ecx, r14d
            dec ecx
            repne scasb
            jne .err_open_comment
            mov r14d, r12d
            sub r14d, ecx
            jmp .main_loop.continue
        .not_comment:
        cmp al, '$'
        jne .not_number
            ; while next() is not a punctuator we just shift the digit into al, if an invalid digit is found then we halt
            xor r11d, r11d
            xor r8d, r8d
            .hex_loop:
                inc r14d
                movzx eax, byte [r13 + r14]
                mov ecx, [PUNCTUATORS]
                lea rdi, [PUNCTUATORS + 4]
                repne scasb
                je .ehex_loop

                shl r11, 4
                sub al, 0x30
                jb .err_not_digit
                cmp al, 0x0A
                jb .not_hexdig
                    sub al, 0x07
                .not_hexdig:
                cmp al, 0x10
                jb .not_lowercase
                    sub al, 0x20
                    jb .err_not_digit
                    cmp al, 0x0F
                    ja .err_not_digit
                .not_lowercase:
                or r11b, al
                inc r8d
                jmp .hex_loop
            .ehex_loop:
            shr r8d, 1
            push r11
            mov rsi, rsp
            mov rdi, vret
            call Darr.append, lea qword [rdi + COMPILED_PROGRAM.program_memory], , r8d
            pop r11
            dec r14d ; because we end on the seperator and .continue increments r14d
            jmp .main_loop.continue
        .not_number:
        cmp al, '@'
        jne .not_definition
            ; First find the bounds on the identifier following [if the first character is a punctuator then halt]
            push r14 ; for later use
            .def.iden_length:
                inc r14d
                movzx eax, byte [r13 + r14]
                mov ecx, [PUNCTUATORS]
                lea rdi, [PUNCTUATORS + 4]
                repne scasb
                je .def.iden_length.break
                jmp .def.iden_length
            .def.iden_length.break:
            ; r14 = end of identifier
            ; [rsp] = old_length
            ; if (r14 - [rsp] <= 1) err
            dec r14 ; transforms is to : (r14 - 1 - [rsp] <= 0) :: (r14 - 1 <= [rsp])
            mov rdx, r14
            sub rdx, [rsp] ; rsi := r14 - 1 - [rsp] ::: flags still set; sets rdx to length
            jle .err_def_no_identifier
            mov [tmp_macro.name.length], edx
            ; now we need to append the string to the arena
            mov rsi, [rsp]
            mov rdi, vret
            call Darr.append, lea qword [rdi + COMPILED_PROGRAM.arena], lea qword [rsi + r13 + 1] ; rsi is already set
            mov [tmp_macro.name], rax ; move the string into the macro
            ; now we need to find some way to get our memory in ;-;
            inc r14 ; undo the dec from before
            cmp byte [r13 + r14], '['
            jne .err_def_expected_scope
            call CompiledProgram.create, lea qword [tmp_macro + PROGRAM_MACRO.program]
            inc r14
            mov rdx, r12
            sub rdx, r14
            inc dword [recursion]
            call compile, lea qword [tmp_macro + PROGRAM_MACRO.program], lea qword [r13 + r14] ; rdx preset
            add r14d, eax
            inc r14d
            dec dword [recursion]
            ; Now we should add tmp_macro to ret->macros
            mov rdi, vret
            ;int3
            call Darr.append, lea qword [rdi + COMPILED_PROGRAM.macros], tmp_macro, 0x40
            add rsp, 0x08
            jmp .main_loop.continue
        .not_definition:
        ; TODO: OPEN SCOPE
        .not_open_scope:
        cmp al, ']'
        jne .not_close_scope
            cmp dword [recursion], 0x00
            je .err_unmatched_endscope
            jmp .done
        .not_close_scope:

        ; So, we have to actually... use the macro ;-;
        ; I guess we just ascertain the length of the identifier
        ; and then search the array for the identifier found :L
        push r14 ; for later use
        .iden_length:
            movzx eax, byte [r13 + r14]
            mov ecx, [PUNCTUATORS]
            lea rdi, [PUNCTUATORS + 4]
            repne scasb
            je .iden_length.break
            inc r14d
            jmp .iden_length
        .iden_length.break:
        ; r14 = end of identifier
        ; [rsp] = old_length
        ; if (r14 - [rsp] <= 1) err
        dec r14 ; transforms is to : (r14 - 1 - [rsp] <= 0) :: (r14 - 1 <= [rsp])
        mov rsi, r14
        sub rsi, [rsp] ; rsi := r14 - 1 - [rsp] ::: flags still set; sets rsi to length
        jle .err_unclassifiable_token
        inc r14d
        ; r13 + [rsp] ::: the address of the first character?
        ; rsi + 1     ::: length of the identifier
        ; we need to iterate over every macro
        push r13
        add r13, [rsp+0x08]
        lea r11d, [rsi + 1]
        mov rdi, vret
        call get_macro, lea qword [rdi + COMPILED_PROGRAM.macros], qword r13, r11d
        or rax, rax
        jz .err_undefined_macro
        pop r13
        ; rax is the ProgramMacro to append
        mov rdi, vret
        call Darr.append, lea qword [rdi + COMPILED_PROGRAM.program_memory], qword [rax + PROGRAM_MACRO.program.program_memory.memory], dword [rax + PROGRAM_MACRO.program.program_memory.length]
    .main_loop.continue:
        inc r14d
        cmp r14d, r12d
        jb .main_loop
        
.done:
    mov eax, r14d
    mov r12, vr12
    mov r13, vr13
    mov r14, vr14
    leave
    ret
ERROR unclassifiable_token, 33o, "[1;31mError:", 33o, "[m Unclassifiable token!", 0x0A
ERROR open_comment, 33o, "[1;31mError:", 33o, "[m Expected close comment!", 0x0A
ERROR not_digit, 33o, "[1;31mError:", 33o, "[m Expected hexadecimal digit!", 0x0A
ERROR def_no_identifier, 33o, "[1;31mError:", 33o, "[m Expected identifier after '@' for definition!", 0x0A
ERROR def_expected_scope, 33o, "[1;31mError:", 33o, "[m Expected scope after identifier for definition!", 0x0A
ERROR unmatched_endscope, 33o, "[1;31mError:", 33o, "[m Unexplained ']'!", 0x0A
ERROR undefined_macro, 33o, "[1;31mError:", 33o, "[m Undefined macro!", 0x0A
END_SUBRT

SUBRT get_macro
    var macros, qword rdi
    var name, qword rsi
    var name_length, qword rdx
    var vr12, qword r12
    var vr13, qword r13
BEGIN
    ; returns a pointer to a ProgramMacro with the name specified
    mov r11, [rdi + PROGRAM_MACRO_LIST.memory]
    mov r12d, [rdi + PROGRAM_MACRO_LIST.length]
    xor r13d, r13d
    ; for each iteration r11 = r11 + sizeof.ProgramMacro
    .loop:
        ; Check if names are equal
        mov rsi, [r11 + r13 + PROGRAM_MACRO.name]
        mov rdi, name
        mov ecx, [r11 + r13 + PROGRAM_MACRO.name.length]
        cmp ecx, name_length
        jne .continue
        repe cmpsb
        je .end_loop

    .continue:
        add r13d, sizeof.ProgramMacro
        cmp r13d, r12d
        jae .not_found
        jmp .loop
    .end_loop:

    lea rax, [r11 + r13]
.done:
    mov r12, vr12
    mov r13, vr13
    leave
    ret
.not_found:
    xor eax, eax
    jmp .done
END_SUBRT

SUBRT CompiledProgram.create ; (CompiledProgram *ret)
    var vret, qword rdi
BEGIN
    mov rdi, vret
    call Darr.create, lea qword [rdi + COMPILED_PROGRAM.program_memory]
    mov rdi, vret
    call Darr.create, lea qword [rdi + COMPILED_PROGRAM.arena]
    mov rdi, vret
    call Darr.create, lea qword [rdi + COMPILED_PROGRAM.macros]
    leave
    ret
END_SUBRT

SUBRT CompiledProgram.destroy ; (CompiledProgram *ret)
    var vret, qword rdi
BEGIN
    mov rdi, vret
    call Darr.destroy, lea qword [rdi + COMPILED_PROGRAM.program_memory]
    mov rdi, vret
    call Darr.destroy, lea qword [rdi + COMPILED_PROGRAM.arena]
    mov rdi, vret
    call Darr.destroy, lea qword [rdi + COMPILED_PROGRAM.macros]
    leave
    ret
END_SUBRT
