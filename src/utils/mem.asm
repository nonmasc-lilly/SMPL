; Making some generic Darr code [look at Darr_types in headers/structs.inc]

Darr.create: ; (Darr<T> *ret)
    push rdi
    syscall SYS_MMAP, ~, 0x200, (PROT_READ or PROT_WRITE), (MAP_PRIVATE or MAP_ANONYMOUS), -1, ~
    pop rdi
    mov qword [rdi + DARR.memory], rax
    mov dword [rdi + DARR.capacity], 0x200
    xor eax, eax
    mov dword [rdi + DARR.length], eax
    ret

Darr.destroy: ; (Darr<T> *ret)
    mov esi, [rdi + DARR.length]
    mov rdi, [rdi + DARR.memory]
    syscall SYS_MUNMAP
    ret

Darr.alloc: ; *(Darr<T> *ret, uint length)
    mov eax, [rdi + DARR.length]
    push rax                        ; push old_length
    add [rdi + DARR.length], esi

    xor ecx, ecx
    mov eax, [rdi + DARR.capacity]
    cmp eax, [rdi + DARR.length]
    cmovb ecx, eax  ; ecx = old_capacity
    .length_calc_loop:
        jae .length_calc_loop.break
        shl eax, 1
        cmp eax, [rdi + DARR.length]
        jmp .length_calc_loop
    .length_calc_loop.break:

    or ecx, ecx
    jz .no_realloc
        push rdi
        mov [rdi + DARR.capacity], eax
        syscall SYS_MREMAP, qword [rdi + DARR.memory], ecx, eax, MREMAP_MAYMOVE, qword rdi 
        pop rdi
        mov [rdi + DARR.memory], rax
    .no_realloc:
    pop rax
    mov rdi, [rdi + DARR.memory]
    add rax, rdi
    ret

Darr.append: ; (Darr<T> *ret, byte *data, uint length)
    mov eax, [rdi + DARR.length]
    push rax                        ; push old_length
    add [rdi + DARR.length], edx    ; add to length

    xor ecx, ecx
    mov eax, [rdi + DARR.capacity]
    cmp eax, [rdi + DARR.length]
    cmovb ecx, eax  ; ecx = old_capacity
    .length_calc_loop:
        jae .length_calc_loop.break
        shl eax, 1
        cmp eax, [rdi + DARR.length]
        jmp .length_calc_loop
    .length_calc_loop.break:

    or ecx, ecx
    jz .no_realloc
        push rdi
        push rsi
        push rdx
        mov [rdi + DARR.capacity], eax
        syscall SYS_MREMAP, qword [rdi + DARR.memory], ecx, eax, MREMAP_MAYMOVE, qword rdi 
        pop rdx ; rdx = length
        pop rsi
        pop rdi
        mov [rdi + DARR.memory], rax
    .no_realloc:
    ; rsi = data, rdi = ret->memory + old_length, ecx = length
    pop rax
    mov rdi, [rdi + DARR.memory]
    add rdi, rax
    mov rax, rdi
    mov ecx, edx
    rep movsb
    ret
