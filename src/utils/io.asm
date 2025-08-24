putchar: ; (char c)
    dec rsp
    mov byte [rsp], dil
    syscall SYS_WRITE, ~byte STDOUT, qword rsp, ~byte 1
    inc rsp
    ret

putn: ; (byte byte)
    push rax
    push rdi
    push rsi
    push rdx
    push r8
    push r11
    xor eax, eax
    mov al, dil
    shr al, 0x04
    add al, 0x30
    cmp al, 0x3A
    jb .not_hex
        add al, 0x07
    .not_hex:
    push rdi
    push rax
    mov rsi, rsp
    syscall SYS_WRITE, ~byte STDOUT, qword rsi, ~byte 1
    pop rax
    pop rdi
    mov al, dil
    and al, 0x0F
    add al, 0x30
    cmp al, 0x3A
    jb .not_hex2
        add al, 0x07
    .not_hex2:
    push rax
    mov rsi, rsp
    syscall SYS_WRITE, ~byte STDOUT, qword rsi, ~byte 1 
    pop rax

    pop r11
    pop r8
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
