return equ FALSE

macro rexpr_p expr*, rb*, rw*, rd*, rq* {
    local matched
    matched equ FALSE
    match =byte v, expr \{
        mov rb, byte v
        matched equ TRUE
    \}
    match =lea =byte v, expr \{
        lea rb, byte v
        matched equ TRUE
    \}
    match =word v, expr \{
        mov rw, word v
        matched equ TRUE
    \}
    match =lea =word v, expr \{
        lea rw, word v
        matched equ TRUE
    \}
    match =dword v, expr \{
        mov rd, dword v
        matched equ TRUE
    \}
    match =lea =dword v, expr \{
        lea rd, dword v
        matched equ TRUE
    \}
    match =qword v, expr \{
        mov rq, qword v
        matched equ TRUE
    \}
    match =lea =qword v, expr \{
        lea rq, qword v
        matched equ TRUE
    \}
    match =FALSE, matched \{
        match =lea v, expr \\{
            lea rd, dword v
            matched equ TRUE
        \\}
        match =FALSE, matched \\{
            mov rd, dword expr
        \\}
    \}
}

macro rexpr expr*, rb*, rw*, rd*, rq* {
    local matched
    matched equ FALSE
    match =~, expr \{
        xor rd, rd
        matched equ TRUE
    \}
    match =~ v, expr \{
        xor rd, rd
        rexpr_p v, rb, rw, rd, rq
        matched equ TRUE
    \}
    match =FALSE, matched \{
        rexpr_p expr, rb, rw, rd, rq
    \}
}

macro sexpr expr* {
    local matched
    matched equ FALSE
    push rax
    rexpr expr, al, ax, eax, rax
    xchg rax, [rsp]
}

macro syscall num, a0, a1, a2, a3, a4, a5 {
    match any, a0 \{
        rexpr a0, dil, di, edi, rdi
    \}
    match any, a1 \{
        rexpr a1, sil, si, esi, rsi
    \}
    match any, a2 \{
        rexpr a2, dl, dx, edx, rdx
    \}
    match any, a3 \{
        rexpr a3, r10b, r10w, r10d, r10
    \}
    match any, a4 \{
        rexpr a4, r8b, r8w, r8d, r8
    \}
    match any, a5 \{
        rexpr a5, r9b, r9w, r9d, r9
    \}
    match any, num \{
        xor eax, eax
        mov al, num
    \}
    syscall
}

macro call lbl*, a0, a1, a2, a3, a4, a5, [arg] {
common
    match any, a0 \{
        rexpr a0, dil, di, edi, rdi
    \}
    match any, a1 \{
        rexpr a1, sil, si, esi, rsi
    \}
    match any, a2 \{
        rexpr a2, dl, dx, edx, rdx
    \}
    match any, a3 \{
        rexpr a3, cl, cx, ecx, rcx
    \}
    match any, a4 \{
        rexpr a4, r8b, r8w, r8d, r8
    \}
    match any, a5 \{
        rexpr a5, r9b, r9w, r9d, r9
    \}
forward
    match any, arg \{
        sexpr arg
    \}
common
    call lbl
}

macro strdef name*, [dat] {
common
    label name
    dd @f - $ - 4
forward
    db dat
common
    @@:
}

macro enter {
    push rbp
    mov rbp, rsp
}
macro leave {
    mov rsp, rbp
    pop rbp
}

macro SUBRT name*, [args] {
    define STACK_SIZE 0x00
    define VAR_LIST
    define HAS_BEGUN FALSE
    label name
    enter
    macro var name*, initial_value*, type \{
        sexpr initial_value
        local increment
        define increment 0x01
        rept 0x01 result:STACK_SIZE+increment \\{ define STACK_SIZE result \\}
        match any, VAR_LIST \\{ VAR_LIST equ VAR_LIST,name \\}
        match , VAR_LIST \\{ VAR_LIST equ name \\}
        name equ [rbp - (STACK_SIZE*0x08)]
    \}
    macro BEGIN \{
        define HAS_BEGUN TRUE
        purge var
    \}
    macro _PURGE [dat] \{
    forward
        match any, dat \\{ purge dat \\}
    \}
    macro END_SUBRT \{
        match =FALSE, HAS_BEGUN \\{
            err
        \\}
        _PURGE VAR_LIST
        purge BEGIN
        purge ERROR
    \}
}
macro ERROR err_name*, [dat] {
common
    label .err_#err_name
    syscall SYS_WRITE, ~byte STDOUT, lea qword [.err_#err_name#.string + 4], [.err_#err_name#.string]
    xor eax, eax
    inc eax
    jmp .done
    strdef .err_#err_name#.string, dat
    
}
