import sys


def whitespace(c: str) -> bool:
    return c == ' ' or c == '\t' or c == '\n';

def op(s: str) -> tuple:
    if s == ';': return ("ENDL", None);

def token(s: str) -> tuple:
    if   s == "":         return None;
    elif s == "FUNCTION": return ("FUNCTION", None);
    elif s == "STRING":   return ("STRING", None);
    elif s == "INT":      return ("TINT", None);
    elif s == "LONG":     return ("TLONG", None);
    elif s == "CHAR":     return ("TCHAR", None);
    elif s == "POINTER":  return ("TPOINTER", None);
    elif s == "RETURN":   return ("RETURN", None);
    elif s == "START":    return ("START", None);
    elif s == "END":      return ("END", None);
    elif s == "CALL":     return ("CALL", None);
    elif s == "FIND":     return ("FIND", None);
    elif s == "ASM":      return ("ASM", None);
    elif s == "SYSCALL":  return ("SYSCALL", None);
    else:
        try: return ("INT", int(s, 0));
        except ValueError: return ("IDEN", s);

def lex_program(string: str) -> list:
    ret: list = [];
    buff: str = "";
    isstring: bool = False;
    for i in string:
        if i == '\"':
            if not isstring:
                if token(buff) != None: ret.append(token(buff));
                buff = "";
            else:
                ret.append(("STRLIT", buff));
                buff = "";
            isstring = not isstring;
            continue;
        if isstring:
            buff += i;
            continue;
        if whitespace(i):
            if token(buff) != None: ret.append(token(buff));
            buff = "";
            continue;
        elif op(i):
            if token(buff) != None: ret.append(token(buff));
            buff = "";
            ret.append(op(i));
            continue;
        buff += i;
    return ret;

def _ASSERT(condition, string):
    if not condition:
        print(string);
        exit(-1);

def parse_iden(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "IDEN": return None;
    return [["IDEN", lexed[offset][1]], 1];

def parse_int(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "INT": return None;
    return [["INT", lexed[offset][1]], 1];

def parse_expr(lexed: list, offset: int) -> list:
    exprs = [parse_iden(lexed, offset), parse_int(lexed, offset), parse_call(lexed, offset)];
    for i in exprs:
        if i != None: return i;
    return None;

def parse_strlit(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "STRLIT": return None;
    return [["STRLIT", lexed[offset][1]], 1];

def parse_asm(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "ASM": return None;
    _strlit = parse_strlit(lexed, offset+1);
    _ASSERT(_strlit != None, "Expected string literal after ASM");
    return [["ASM", _strlit[0]], _strlit[1]+1]

def parse_call(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "CALL": return None;
    _int = parse_int(lexed, offset+1);
    _ASSERT(_int != None, "Expected argument number after CALL");
    _iden = parse_iden(lexed, offset+1+_int[1]);
    _ASSERT(_iden != None, "Expected iden after CALL");
    off = 1+_int[1]+_iden[1];
    ret = ["CALL", _iden[0], []];
    for i in range(_int[0][1]):
        _expr = parse_expr(lexed, offset_off);
        _ASSERT(_expr != None,
            "Expected expression numbers equal to that of the arg number passed" +
            "into call.");
        ret[3].append(_expr[0]);
        off += _expr[1];
    return [ret, off];

def parse_type(lexed: list, offset: int) -> list:
    if lexed[offset][0] == "TINT":       return [["TYPE", "INT"], 1];
    elif lexed[offset][0] == "TCHAR":    return [["TYPE", "CHAR"], 1];
    elif lexed[offset][0] == "TPOINTER": return [["TYPE", "POINTER"], 1];
    elif lexed[offset][0] == "TLONG":    return [["TYPE", "LONG"], 1];
    return None;

def parse_find(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "FIND": return None;
    _type = parse_type(lexed, offset+1);
    _ASSERT(_type != None, "Expected type after FIND");
    _iden = parse_iden(lexed, offset+_type[1]+1);
    _ASSERT(_iden != None, "Expected iden after FIND");
    return [["FIND", _type[0], _iden[0]], _iden[1]+_type[1]+1];

def parse_return(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "RETURN": return None;
    _expr = parse_expr(lexed, offset+1);
    _ASSERT(_expr != None, "Expected expression after RETURN");
    return [["RETURN", _expr[0]], _expr[1]+1];

def parse_statement(lexed: list, offset: int) -> list:
    statements = [parse_find(lexed, offset), parse_return(lexed, offset),
        parse_asm(lexed, offset), parse_call(lexed, offset)];
    for i in statements:
        if i != None:
            print(str(i));
            if lexed[offset+i[1]][0] == "ENDL":
                return [i[0], i[1]+1];
    return None;

def parse_function(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "FUNCTION": return None;
    _iden = parse_iden(lexed, offset+1);
    _ASSERT(_iden != None, "Expected IDEN after FUNCTION");
    _ASSERT(lexed[offset+1+_iden[1]][0] == "START", "Expected START to FUNCTION");
    off = 2+_iden[1];
    ret = ["FUNCTION", _iden[0], []];
    while lexed[off+offset][0] != "END":
        _statement = parse_statement(lexed, offset+off);
        _ASSERT(_statement != None, "must recieve statements until end of function");
        ret[2].append(_statement[0]);
        off += _statement[1];
    return [ret, off+1];
        

def parse_string(lexed: list, offset: int) -> list:
    if lexed[offset][0] != "STRING": return None;
    _iden = parse_iden(lexed, offset+1);
    _ASSERT(_iden != None, "Expected iden after STRING");
    _strlit = parse_strlit(lexed, offset+1+_iden[1]);
    _ASSERT(_strlit != None, "Expected strlit after STRING");
    return [["STRING", _iden[0], _strlit[0]], _iden[1]+_strlit[1]+1];

def parse_protostatement(lexed: list, offset: int) -> list:
    protostatements = [parse_function(lexed, offset), parse_string(lexed, offset)];
    for i in protostatements:
        if i != None: return i;

def parse_program(lexed: list) -> list:
    off: int = 0;
    ret: list = [];
    while True:
        try:
            _protostatement = parse_protostatement(lexed, off);
            if _protostatement == None: break;
            off += _protostatement[1];
            ret.append(_protostatement[0]);
        except IndexError:
            break;
    return ret;


def _T_LENGTH(t: str) -> int:
    if t == "INT": return 4;
    if t == "CHAR": return 1;
    if t == "POINTER": return 8;
    if t == "LONG": return 8;

def preprocess(parsed: list, state: dict) -> str:
    for idx, i in enumerate(parsed):
        if i[0] == "FUNCTION":
            state["functions"].append({
                "name": i[1][1],
                "argnum": 0,
                "variable_len": 0,
                "variables": []
            });
            for j in i[2]:
                if j[0] == "FIND":
                    state["functions"][-1]["argnum"] += 1;
                    state["functions"][-1]["variable_len"] += 8;
                    for i in range(len(state["functions"][-1]["variables"])):
                        state["functions"][-1]["variables"][i]["offset"] += (
                            _T_LENGTH(j[1][1]));
                    state["functions"][-1]["variables"].append({
                        "name": j[2][1],
                        "offset": 0,
                        "length": _T_LENGTH(j[1][1])
                    });
    return 0;

def _HEX(i: int) -> str:
    return "0x" + hex(i)[2:].upper();

def compile_iden(parsed, state):
    if parsed[0] != "IDEN": return None;
    for i in state["functions"][state["current_function"]]["variables"]:
        if i["name"] == parsed[1]:
            return "mov rax, [rsp+" + str(i["offset"] + i["length"]) + "]\n";
    return parsed[1];

def compile_int(parsed, state):
    if parsed[0] != "INT": return None;
    return "mov rax, " + _HEX(parsed[1]) + "\n";

def compile_expr(parsed: list, state: dict) -> str:
    exprs = [compile_iden(parsed, state), compile_int(parsed, state),
            compile_call(parsed, state)];
    for i in exprs:
        if i != None: return i;
    return None;

def compile_call(parsed: list, state: dict) -> str:
    if parsed[0] != "CALL": return None;
    for i in state["functions"]:
        if i["name"] == parsed[1][1]:
            break;
    else: _ASSERT(False, parsed[1][1] + " is not a function");
    ret = "";
    for i in range(len(parsed[2])):
        ret += compile_expr(parsed[2][-i], state) + "\npush rax\n";
    ret += "call " + parsed[1][1] + "\n";
    return ret;

def compile_find(parsed: list, state: dict) -> str:
    if parsed[0] != "FIND": return None;
    return "";

def compile_return(parsed: list, state: dict) -> str:
    if parsed[0] != "RETURN": return None;
    return compile_expr(parsed[1], state) + "ret\n";

def compile_asm(parsed: list, state: dict) -> str:
    if parsed[0] != "ASM": return None;
    return parsed[1][1];

def compile_statement(parsed: list, state: dict) -> str:
    statements = [compile_return(parsed, state), compile_find(parsed, state),
        compile_call(parsed, state)];
    for i in statements:
        if i != None: return i;
    return None;

def compile_function(parsed: list, state: dict) -> str:
    # <func> 'FUNCTION', iden, [<statements>]
    if parsed[0] != "FUNCTION": return None;
    for i in range(len(state["functions"])):
        if state["functions"][i]["name"] == parsed[1][1]:
            state["current_function"] = i;
    state[".text"].append(parsed[1][1] + ":\n");
    for i in parsed[2]:
        state[".text"].append(compile_statement(i, state));
    return "";

def compile_string(parsed: list, state: dict) -> str:
    if parsed[0] != "STRING": return None;
    ret = parsed[1][1] + ":\n\tdb \"";
    skip = False;
    cnew = False;
    _open = True;
    for idx, i in enumerate(parsed[2][1]):
        if skip:
            skip = False;
            continue;
        if cnew:
            ret += ", \"";
            cnew = False;
            _open = True;
        if i == "\\":
            nums = ['a', 'b', 'e',  'f', 'n', 'r', 't', 'v'];
            vals = [0x7, 0x8, 0x1B, 0xC, 0xA, 0xD, 0x9, 0xB];
            j = parsed[2][1][idx+1];
            if j in nums:
                ret += "\", " + _HEX(vals[nums.index(j)]);
                skip = True;
                cnew = True;
                _open = False;
                continue;
            elif j == '\\':
                ret += "\\";
                skip = True;
                continue;
            elif j == '\"':
                ret += "\"";
                skip = True;
                continue;
        ret += i;
    if _open: ret += "\", 0x0\n";
    else: ret += ", 0x0\n";
    state[".data"].append(ret);
    return "";

def compile_protostatement(parsed: list, state: dict) -> str:
    protostatements = [compile_function(parsed, state), compile_string(parsed, state)];
    for i in protostatements:
        if i != None: return i;
    return None;

def compile_program(parsed: list) -> str:
    state = {
        ".text": [],
        ".data": [],
        ".rodata": [],
        "functions": [],
        "current_function": 0,
    };
    preprocess(parsed, state);
    off: int = 0;
    ret: str = "";
    while True:
        try:
            _protostatement = compile_protostatement(parsed[off], state);
            if _protostatement == None: break;
            off += 1;
        except IndexError:
            break;
    ret += (
"""
section .text
    global _start
_start:
    lea rax, [rsp-16]
    push rax
    call MAIN
    mov rdi, rax
    mov rax, 0x3C
    syscall
""")
    for i in state[".text"]:
        ret += i;
    ret += "section .data\n";
    for i in state[".data"]:
        ret += i;
    ret += "section .rodata\n";
    for i in state[".rodata"]:
        ret += i;
    return ret;






if __name__ == "__main__":
    print(
"""
=============================================
 ____  _  _  ____  __   
/ ___)( \\/ )(  _ \\(  )  
\\___ \\/ \\/ \\ ) __// (_/\\
(____/\\_)(_/(__)  \\____/
=============================================
the Simple Memory unsafe Programming Language
"""
    );
    if len(sys.argv) < 2:
        print("ERROR, invalid usage\nUSAGE: " + sys.argv[0] + " <input file>");
        exit(-1);
    ofile = "out.asm";
    for idx, i in enumerate(sys.argv):
        if i == "-o":
            ofile = sys.argv[idx+1];

    file = open(sys.argv[1], "r");
    file_contents = file.read();
    file.close();

    print("Input data:\n" + file_contents + "\n[EOF]");
    print("\nLexing...\n");
    lexed = lex_program(file_contents);
    print("\nlexed contents:\n" + str(lexed));
    print("\nParsing...\n");
    parsed = parse_program(lexed);
    print("\nparsed contents:\n" + str(parsed));
    print("\ncompiling\n");
    compiled = compile_program(parsed);
    print("\ncompiled contents:\n" + compiled);
    print("Creating " + ofile + "...\n");
    file = open(ofile, "w");
    file.write(compiled);
    file.close();
    print("Exiting...\n");
    exit(0);











