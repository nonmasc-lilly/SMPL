format elf64 executable
entry _start

include "headers/macros.inc"
include "headers/constants.inc"
include "headers/structs.inc"

segment readable executable
strdef UNIMPLEMENTED.string, 33o, "[1;31mError:", 33o, "[m unimplemented!", 0x0A
include "utils/io.asm"
include "utils/mem.asm"
include "compile.asm"

_start:
    ; read argv: [<input> <output>]
    mov rbp, rsp
    cmp byte [rbp], 0x03
    jne .error

    ; read file
    syscall SYS_OPEN, qword [rbp + 0x10], O_RDONLY, 777o
    push rax
    syscall SYS_FSTAT, eax, stat
    syscall SYS_MMAP, ~, [stat.st_size], PROT_READ, MAP_PRIVATE, [rsp], ~
    mov qword [src], rax
    pop rax
    syscall SYS_CLOSE, eax


    ; compile now
    call CompiledProgram.create, qword compiled
    call compile, qword compiled, qword [src], [stat.st_size]

    syscall SYS_OPEN, qword [rbp + 0x18], (O_WRONLY or O_CREAT or O_TRUNC), 777o
    push rax
    syscall SYS_WRITE, eax, qword [compiled + COMPILED_PROGRAM.program_memory.memory], [compiled + COMPILED_PROGRAM.program_memory.length]
    pop rax
    syscall SYS_CLOSE, eax

    call CompiledProgram.destroy, qword compiled

    syscall SYS_MUNMAP, qword [src], dword [stat.st_size]
    syscall SYS_EXIT, ~
.error:
    mov rsi, usage.0
    syscall SYS_WRITE, ~STDOUT, lea qword [usage.0 + 4], dword [usage.0]
    call strlen, qword [rbp + 0x08]
    syscall SYS_WRITE, ~STDOUT, qword [rbp + 0x08], eax
    syscall SYS_WRITE, ~STDOUT, lea qword [usage.1 + 4], dword [usage.1]
    syscall SYS_EXIT, ~

strlen: ; (string)
    xor eax, eax
    xor ecx, ecx
    dec ecx
    repnz scasb
    mov eax, ecx
    neg eax
    dec eax
    ret

;
;   .ronly
;
usage:
    strdef usage.0, 33o, "[1;33mUsage:", 33o, "[m "
    strdef usage.1, " <input file> <output file>", 0x0A

segment readable writeable

include "headers/data.inc"
