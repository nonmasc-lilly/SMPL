struc Stat {
    .st_dev         dq ?
    .st_ino         dq ?
    .st_nlink       dq ?
    .st_mode        dd ?
    .st_uid         dd ?
    .st_gid         dd ?
    dd ?
    .st_rdev        dq ?
    .st_size        dq ?
    .st_blksize     dq ?
    .st_blocks      dq ?
    .st_atime       dq ?
    .st_atime_nsec  dq ?
    .st_mtime       dq ?
    .st_mtime_nsec  dq ?
    .st_ctime       dq ?
    .st_ctime_nsec  dq ?
    dq 3 dup ?
}
virtual at 0
STAT Stat
sizeof.Stat = $
end virtual

macro Darr_type name, vname {
    struc name \{
        .memory   dq ?
        .capacity dd ?
        .length   dd ?
    \}
    virtual at 0
    vname name
    sizeof.#name = $
    end virtual
}
Darr_type Darr, DARR ; The generic Darr type, all other Darr types are compatible with Darr

Darr_type ProgramMemory, PROGRAM_MEMORY
Darr_type Arena, ARENA
Darr_type ProgramMacroList, PROGRAM_MACRO_LIST

struc CompiledProgram {
    .program_memory     ProgramMemory
    .arena              Arena
    .macros             ProgramMacroList
}
virtual at 0
    COMPILED_PROGRAM CompiledProgram
    sizeof.CompiledProgram = $
end virtual

struc ProgramMacro {
    ; allocated in its parents arena
    .name           dq ?
    .name.length    dd ?
    dd ?
    .program        CompiledProgram
}
virtual at 0
    PROGRAM_MACRO ProgramMacro
    sizeof.ProgramMacro = $
end virtual

