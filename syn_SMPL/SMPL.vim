

syn region SMPLscope start="START" end="END" fold transparent contains=SMPLkeyword,SMPLnumber
syn keyword SMPLtypes FUNCTION STRING INT CHAR POINTER LONG
syn keyword SMPLkeyword RETURN END START CALL FIND ASM
syn match SMPLnumber "\d\+"
syn match SMPLnumber "0x[0-9a-fA-F]\+\>"
syn region SMPLstring start='"' end='"'

let b:current_syntax = "SMPL"
hi def link SMPLkeyword Statement
hi def link SMPLnumber Constant
hi def link SMPLstring Constant
hi def link SMPLtypes Type

