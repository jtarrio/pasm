PASS    DB 0    ; Assembler pass
ARG1    DB ARG_MAXSIZE DUP(0)   ; First argument
ARG2    DB ARG_MAXSIZE DUP(0)   ; Second argument

; Procedure ASSEMBLE
; Runs one assembly pass
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
ASSEMBLE:
    INC [PASS]          ; Start a new pass
    MOV WORD PTR [PC], 0; Reset the program counter
    CALL LEXER_RESTART  ; Reset the lexer
    CALL RESET_MACROS   ; Reset the macro table for the pass
    JMP PARSE_SOURCE_   ; Start parsing

; Macro to compare the token type
CMP_TOKEN_TYPE  EQU CMP BYTE PTR [TOKEN + TOKEN_TYPE],
; Macro to load the token type to AL
LD_TOKEN_TYPE   EQU MOV AL, [TOKEN + TOKEN_TYPE]
; Macro to compare the token value (as a byte)
CMP_TOKEN_VALUE EQU CMP BYTE PTR [TOKEN + TOKEN_VALUE],
; Macro to load the token value to AL
LD_TOKEN_VALUE  EQU MOV AL, [TOKEN + TOKEN_VALUE]

; Procedure PARSE_SOURCE_
; Parses a source file
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_SOURCE_:
    CALL LEXER_NEXT         ; Load the next token
    CMP_TOKEN_TYPE TK_EOF   ; If EOF, return
    JZ _psrc_done_
    CALL PARSE_LINE_        ; Parse a line
    CMP_TOKEN_TYPE TK_EOL   ; Expect EOL
    JNZ _psrc_noeol_
    JMP PARSE_SOURCE_       ; Parse the next line
_psrc_done_:
    RET
_psrc_noeol_:
    JMP ERROR_EXPECTED_EOL

; Procedure PARSE_LINE_
; Parses a single line
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_LINE_:
    LD_TOKEN_TYPE
    CMP AL, TK_IDENTIFIER   ; Identifier?
    JZ PARSE_LABELED_STMT_  ; Yes -> labeled statement
    CMP AL, TK_KEYWORD      ; Keyword?
    JNZ _pline_invalid_
    CMP_TOKEN_VALUE KW_ORG  ;   Keyword is ORG?
    JZ _pline_org_          ;   Yes -> ORG directive
    JMP PARSE_STATEMENT_    ;   Other -> statement
_pline_org_:
    JMP PARSE_ORG_DIRECTIVE_
_pline_invalid_:
    JMP ERROR_EXPECTED_LABEL_KEYWORD

; Procedure PARSE_LABELED_STMT_
; Parses a labeled statement
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_LABELED_STMT_:
    ; Create a label from the token's content
    MOV SI, TOKEN + TOKEN_IDLEN
    MOV DI, LABEL + LABEL_NAMELEN
    XOR CX, CX
    MOV CL, [SI]
    INC CX
    CLD
    REP MOVSB                               ; Copy the name
    MOV CX, WORD PTR [TOKEN + TOKEN_LINE]   ; The line number
    MOV WORD PTR [LABEL + LABEL_LINE], CX
    MOV CX, [PC]                            ; The address
    MOV WORD PTR [LABEL + LABEL_ADDR], CX

    CALL LEXER_NEXT         ; Next token
    LD_TOKEN_TYPE
    CMP AL, TK_COLON        ; Colon?
    JZ _pls_parse_label_    ; Yes -> label
    CMP AL, TK_KEYWORD      ; Keyword?
    JZ _pls_parse_dataequ_  ; Yes -> possible data or EQU directive
    JMP ERROR_EXPECTED_AFTER_LABEL
_pls_done_:
    RET

_pls_parse_label_:
    MOV [LABEL + LABEL_TYPE], LBL_ADDR
    CALL ADD_LABEL          ; Add an "any address" label
    CALL LEXER_NEXT         ; Next token
    LD_TOKEN_TYPE
    CMP AL, TK_EOL          ; EOL?
    JZ _pls_done_           ; Yes -> end of statement
    CMP AL, TK_KEYWORD      ; Keyword?
    JZ _pls_stmt_           ; Yes -> parse the statement
    JMP ERROR_EXPECTED_KEYWORD
_pls_stmt_:
    JMP PARSE_STATEMENT_

_pls_parse_dataequ_:
    LD_TOKEN_VALUE
    CMP AL, KW_EQU          ; EQU?
    JZ _pls_found_equ_
    MOV BX, LBL_BYTEADDR
    CMP AL, KW_DB           ; DB?
    JZ _pls_found_data_
    MOV BX, LBL_WORDADDR
    CMP AL, KW_DW           ; DW?
    JZ _pls_found_data_
    MOV BX, LBL_DWORDADDR
    CMP AL, KW_DD           ; DD?
    JZ _pls_found_data_
    JMP ERROR_EXPECTED_AFTER_LABEL
_pls_found_equ_:
    JMP PARSE_EQU_DIRECTIVE_
_pls_found_data_:
    MOV [LABEL + LABEL_TYPE], BL
    CALL ADD_LABEL
    JMP PARSE_DATA_STMT_

; Procedure PARSE_ORG_DIRECTIVE_
; Parses an ORG directive
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_ORG_DIRECTIVE_:
    CALL LEXER_NEXT
    CMP_TOKEN_TYPE TK_NUMBER    ; Number?
    JNZ _porg_nonum_
    MOV AX, WORD PTR [TOKEN + TOKEN_NUMBER]
    CALL EMIT_ORG               ; Yes, emit an ORG
    JMP LEXER_NEXT              ; Get next token and return
_porg_nonum_:
    JMP ERROR_EXPECTED_NUMBER

; Procedure PARSE_EQU_DIRECTIVE_
; Parses an EQU directive
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_EQU_DIRECTIVE_:
    MOV SI, LABEL + LABEL_NAMELEN
    CALL START_EQU              ; Create an EQU with the label's name
_pequ_loop_:
    PUSH DI     ; LEXER_NEXT destroys DI, so preserve it
    CALL LEXER_NEXT             ; Grab one token
    POP DI
    CMP_TOKEN_TYPE TK_EOL       ; Repeating until EOL
    JZ _pequ_done_
    CALL ADD_TOKEN_TO_EQU       ; Add the token to the new EQU
    JMP _pequ_loop_
_pequ_done_:
    RET

; Procedure PARSE_STATEMENT_
; Parses a statement
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_STATEMENT_:
    LD_TOKEN_VALUE          ; Keyword
    CMP AL, KW_LOCK         ; >= LOCK?
    JB _pstmt_noprefix_
    CMP AL, KW_REPZ         ; <= REPZ?
    JA _pstmt_noprefix_

    CALL EMIT_PREFIX        ; Yes; emit the prefix
    CALL LEXER_NEXT
    CMP_TOKEN_TYPE TK_EOL   ; If EOL, done
    JZ _pstmt_ret_
    CMP_TOKEN_TYPE TK_KEYWORD
    JNZ _pstmt_nokeyword_
    JMP PARSE_STATEMENT_    ; otherwise, parse the following statement
_pstmt_ret_:
    RET
_pstmt_nokeyword_:
    JMP ERROR_EXPECTED_INSTRUCTION

_pstmt_noprefix_:
    CMP AL, KW_DB           ; >= DB?
    JB _pstmt_nodata_
    CMP AL, KW_DW           ; <= DW?
    JA _pstmt_nodata_

    JMP PARSE_DATA_STMT_    ; Yes; parse the data statement

_pstmt_nodata_:
    CMP AL, KW_AAA
    JAE _pstmt_instr_
    JMP ERROR_EXPECTED_INSTRUCTION

_pstmt_instr_:
    MOV BYTE PTR [ARG1 + ARG_TYPE], ARGT_NONE
    MOV BYTE PTR [ARG2 + ARG_TYPE], ARGT_NONE
    PUSH AX
    CALL LEXER_NEXT
    CMP_TOKEN_TYPE TK_EOL   ; EOL? Emit the instruction
    JNZ _pstmt_arg1_
    POP AX
    JMP EMIT_INSTRUCTION

_pstmt_arg1_:
    MOV DI, ARG1
    CALL CLEAR_ARGUMENT_
    CALL PARSE_ARGUMENT_    ; Parse the first argument
    CMP_TOKEN_TYPE TK_EOL   ; EOL? Emit the instruction
    JNZ _pstmt_comma_
    POP AX
    JMP EMIT_INSTRUCTION

_pstmt_comma_:
    CMP_TOKEN_TYPE TK_COMMA ; Expect a comma between arguments
    JZ _pstmt_arg2_
    JMP ERROR_EXPECTED_COMMA

_pstmt_arg2_:
    CALL LEXER_NEXT
    MOV DI, ARG2
    CALL CLEAR_ARGUMENT_
    CALL PARSE_ARGUMENT_    ; Parse the second argument
    POP AX
    JMP EMIT_INSTRUCTION


; Procedure PARSE_DATA_STMT_
; Parses a data statement (DB, DW, DD)
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_DATA_STMT_:
    LD_TOKEN_VALUE      ; Put the keyword in AL
    PUSH AX
    CALL LEXER_NEXT
    POP AX
    CMP AL, KW_DB       ; DB?
    JZ PARSE_DB_SEQ_
    CMP AL, KW_DW       ; DW?
    JZ PARSE_DW_SEQ_
    JMP PARSE_DD_SEQ_   ; We assume DD

; Procedure PARSE_DB_SEQ_
; Parses a data sequence for a DB statement
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_DB_SEQ_:
    MOV DI, ARG1
    CALL CLEAR_ARGUMENT_
    CALL PARSE_ARGUMENT_        ; Saves the argument in [DI]
    CALL PARSE_DUP_             ; Puts count in CX, argument in [DI]
    JCXZ _pdbs_epilog_          ; Skip if the count is zero
    MOV AL, [ARG1 + ARG_TYPE]
    CMP AL, ARGT_NUM + ARGS_BYTE    ; Byte?
    JZ _pdbs_bytes_
    CMP AL, ARGT_STR                ; String?
    JZ _pdbs_string_
    JMP ERROR_EXPECTED_BYTE_STRING
_pdbs_bytes_:
    MOV AL, [ARG1 + ARG_BYTE]
    CALL EMIT_BYTE                  ; Emit bytes
    LOOP _pdbs_bytes_               ; Until CX is zero
    JMP _pdbs_epilog_
_pdbs_string_:
    MOV SI, ARG1 + ARG_STRLEN
    CALL EMIT_STRING                ; Emit strings
    LOOP _pdbs_string_              ; Until CX is zero
    ; fall through to _pdbs_epilog_
_pdbs_epilog_:
    LD_TOKEN_TYPE
    CMP AL, TK_EOL                  ; Done on EOL
    JZ _pdbs_done_
    CMP AL, TK_COMMA                ; Continue on comma
    JNZ _pdbs_nocomma_
    CALL LEXER_NEXT
    JMP PARSE_DB_SEQ_
_pdbs_done_:
    RET
_pdbs_nocomma_:
    JMP ERROR_EXPECTED_COMMA

; Procedure PARSE_DW_SEQ_
; Parses a data sequence for a DW statement
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_DW_SEQ_:
    MOV DI, ARG1
    CALL CLEAR_ARGUMENT_
    CALL PARSE_ARGUMENT_        ; Saves the argument in [DI]
    CALL PARSE_DUP_             ; Puts count in CX, argument in [DI]
    JCXZ _pdws_epilog_          ; Skip if the count is zero
    MOV AL, [ARG1 + ARG_TYPE]
    TEST AL, ARGT_NUM           ; Number?
    JNZ _pdws_nums_
    TEST AL, ARGT_STR           ; String?
    JNZ _pdws_string_
_pdws_error_:
    JMP ERROR_EXPECTED_WORD
_pdws_nums_:
    MOV AX, WORD PTR [ARG1 + ARG_WORD]
    CALL EMIT_WORD              ; Emit words
    LOOP _pdws_nums_            ; Until CX is zero
    JMP _pdws_epilog_
_pdws_string_:
    CMP [ARG1 + ARG_STRLEN], 2
    JNZ _pdws_error_            ; Check that the string has length 2
_pdws_string_loop_:
    MOV SI, ARG1 + ARG_STRLEN
    CALL EMIT_STRING            ; Emit strings
    LOOP _pdws_string_loop_     ; Until CX is zero
    ; fall through to _pdws_epilog_
_pdws_epilog_:
    LD_TOKEN_TYPE
    CMP AL, TK_EOL              ; Done on EOL
    JZ _pdws_done_
    CMP AL, TK_COMMA            ; Continue on comma
    JNZ _pdws_nocomma_
    CALL LEXER_NEXT
    JMP PARSE_DW_SEQ_
_pdws_done_:
    RET
_pdws_nocomma_:
    JMP ERROR_EXPECTED_COMMA

; Procedure PARSE_DD_SEQ_
; Parses a data sequence for a DD statement
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
PARSE_DD_SEQ_:
    MOV DI, ARG1
    CALL CLEAR_ARGUMENT_
    CALL PARSE_ARGUMENT_        ; Saves the argument in [DI]
    CALL PARSE_DUP_             ; Puts count in CX, argument in [DI]
    JCXZ _pdds_epilog_          ; Skip if the count is zero
    MOV AL, [ARG1 + ARG_TYPE]
    CMP AL, ARGT_NUM + ARGS_DWORD   ; Dword?
    JZ _pdds_dwords_
    CMP AL, ARGT_STR                ; String?
    JZ _pdds_string_
_pdds_error_:
    JMP ERROR_EXPECTED_DWORD
_pdds_dwords_:
    MOV AX, WORD PTR [ARG1 + ARG_DWORD]
    MOV DX, WORD PTR [ARG1 + ARG_DWORD + 2]
    CALL EMIT_DWORD                  ; Emit dword
    LOOP _pdds_dwords_               ; Until CX is zero
    JMP _pdds_epilog_
_pdds_string_:
    CMP [ARG1 + ARG_STRLEN], 4
    JNZ _pdds_error_            ; Check that the string has length 4
_pdds_string_loop_:
    MOV SI, ARG1 + ARG_STRLEN
    CALL EMIT_STRING            ; Emit strings
    LOOP _pdds_string_loop_     ; Until CX is zero
    ; fall through to _pdds_epilog_
_pdds_epilog_:
    LD_TOKEN_TYPE
    CMP AL, TK_EOL                  ; Done on EOL
    JZ _pdds_done_
    CMP AL, TK_COMMA                ; Continue on comma
    JNZ _pdds_nocomma_
    CALL LEXER_NEXT
    JMP PARSE_DD_SEQ_
_pdds_done_:
    RET
_pdds_nocomma_:
    JMP ERROR_EXPECTED_COMMA

; Procedure PARSE_DUP_
; Parses a DUP directive
; Outputs:
;   CX the repeat count
;   [ARG1] the argument to repeat
; Destroys:
;   AX, BX, DX, SI, DI, flags
PARSE_DUP_:
    MOV AX, 1                   ; Set count to 1
    XOR BX, BX                  ; Set level to 0
    PUSH AX                     ; Stash the count
_pdup_loop_:
    MOV AL, [ARG1 + ARG_TYPE]
    TEST AL, ARGT_NUM           ; Argument is a number?
    JZ _pdup_exit_              ; No, so don't look for DUP
    CMP_TOKEN_TYPE TK_KEYWORD   ; Keyword?
    JNZ _pdup_exit_             ; No, so don't look for DUP
    CMP_TOKEN_VALUE KW_DUP      ; DUP?
    JNZ _pdup_exit_             ; No, so exit the loop
    INC BX                      ; We are one more level deep
    POP AX
    MUL WORD PTR [ARG1 + ARG_WORD]  ; Multiply the count by the argument
    JC _pdup_toomuch_           ; Too many copies!
    PUSH AX
    PUSH BX
    CALL LEXER_NEXT             ; Get the next token
    CMP_TOKEN_TYPE TK_LPAREN    ; Which must be an lparen
    JNZ _pdup_left_
    CALL LEXER_NEXT             ; Get the next token
    MOV DI, ARG1
    CALL CLEAR_ARGUMENT_
    CALL PARSE_ARGUMENT_        ; Parse the argument
    POP BX
    JMP _pdup_loop_             ; ... and check for DUP again
_pdup_exit_:
    MOV CX, BX                  ; Now we will loop on the level
    JCXZ _pdup_loop_done_
_pdup_exit_loop_:
    CMP_TOKEN_TYPE TK_RPAREN    ; rparen?
    JNZ _pdup_right_
    PUSH CX
    CALL LEXER_NEXT             ; Yes, get the next token
    POP CX
    LOOP _pdup_exit_loop_       ; Until we are back at level 0
_pdup_loop_done_:
    POP CX                      ; We had stashed the count in the stack
    RET
_pdup_toomuch_:
    JMP ERROR_OVERFLOW
_pdup_left_:
    JMP ERROR_EXPECTED_LPAREN
_pdup_right_:
    JMP ERROR_EXPECTED_RPAREN

; Procedure PARSE_SINGLE_NUMBER_
; Parses a number
; Outputs:
;   DL:AX a 24-bit number, AX the low 16 bits
;   DH the label type
; Destroys:
;   BX, CX, SI, DI, flags
PARSE_SINGLE_NUMBER_:
    CMP_TOKEN_TYPE TK_MINUS
    PUSHF                   ; Save the result of the comparison
    JZ _psnum_prefix_
    CMP_TOKEN_TYPE TK_PLUS
    JNZ _psnum_noprefix_
_psnum_prefix_:
    CALL LEXER_NEXT         ; Skip the plus or minus sign
_psnum_noprefix_:
    XOR AX, AX
    XOR DL, DL
    CMP_TOKEN_TYPE TK_NUMBER        ; Number?
    JNZ _psnum_maybe_id_
    MOV AX, WORD PTR [TOKEN + TOKEN_NUMBER]
    XOR DX, DX
    JMP _psnum_adjust_
_psnum_maybe_id_:
    CMP_TOKEN_TYPE TK_IDENTIFIER    ; Identifier?
    JZ _psnum_id_
    JMP ERROR_EXPECTED_NUMBER_LABEL
_psnum_id_:
    MOV SI, TOKEN + TOKEN_IDLEN     ; Copy the identifier to LABEL
    MOV DI, LABEL + LABEL_NAMELEN
    XOR CX, CX
    MOV CL, [SI]
    INC CX
    CLD
    REP MOVSB
    CALL GET_LABEL
    MOV AX, WORD PTR [LABEL + LABEL_ADDR]
    MOV DH, BYTE PTR [LABEL + LABEL_TYPE]
_psnum_adjust_:
    POPF
    JNZ _psnum_ret_         ; The first token was TK_MINUS?
    CMP AX, 32768           ; Yes; negate DL:AX
    JA _psnum_underflow_    ; (but avoiding underflow)
    NEG DL
    NEG AX
    SBB DL, 0
_psnum_ret_:
    PUSH AX
    PUSH DX
    CALL LEXER_NEXT
    POP DX
    POP AX
    RET
_psnum_underflow_:
    JMP ERROR_UNDERFLOW

; Procedure PARSE_NUMBER_EXPR_
; Parses a number expression and adds the result to DL:AX
; Inputs:
;   DL:AX a 24-bit number, AX the low 16 bits
;   DH the label type
; Outputs:
;   DL:AX a 24-bit number, AX the low 16 bits
;   DH the label type
; Destroys:
;   BX, CX, SI, DI, flags
PARSE_NUMBER_EXPR_:
    PUSH AX         ; Save the previous values
    PUSH DX
    XOR BX, BX      ; BL contains whether the next term is a sum
    PUSH BX
_pnumexp_loop_:
    CALL PARSE_SINGLE_NUMBER_   ; Parse a number
    POP BX
    CMP BL, 0       ; Were we adding?
    JNZ _pnumexp_sub_
    POP CX          ; Yes; add the new DL:AX to the old DL:AX
    POP BX
    ADD BX, AX
    ADC CL, DL
    JMP _numexp_label_
_pnumexp_sub_:
    POP CX          ; No; subtract the new DL:AX from the old DL:AX
    POP BX
    SUB BX, AX
    SBB CL, DL
_numexp_label_:
    CMP DH, LBL_NONE    ; Is the new label LBL_NONE?
    JZ _numexp_samelabel_
    MOV CH, DH          ; No; update it
_numexp_samelabel_:
    PUSH BX
    PUSH CX
_numexp_next_:
    CMP_TOKEN_TYPE TK_MINUS     ; Next token is TK_MINUS?
    MOV BL, 1
    JZ _pnumexp_op_
    CMP_TOKEN_TYPE TK_PLUS      ; Maybe TK_PLUS?
    MOV BL, 0
    JZ _pnumexp_op_
    POP DX                      ; None; return
    POP AX
    RET
_pnumexp_op_:
    PUSH BX                     ; Save BX and get the next token
    PUSH AX
    PUSH DX
    CALL LEXER_NEXT
    POP DX
    POP AX
    JMP _pnumexp_loop_

; Procedure CLEAR_ARGUMENT_
; Clears the space for an argument
; Inputs:
;   DI the location of the argument's buffer
CLEAR_ARGUMENT_:
    PUSH AX
    PUSH CX
    PUSH DI
    XOR AL, AL
    MOV CX, ARG_MAXSIZE
    CLD
    REP STOSB
    POP DI
    POP CX
    POP AX
    RET

; Procedure PARSE_ARGUMENT_
; Parses an argument of any type
; Inputs:
;   DI the location of the buffer to store the argument in
; Destroys:
;   AX, BX, CX, DX, SI, flags
PARSE_ARGUMENT_:
    LD_TOKEN_TYPE
    CMP AL, TK_STRING   ; Tokens above TK_STRING get remapped to EOF
    JBE _parg_ok_
    MOV AL, TK_EOF
_parg_ok_:
    CBW
    SHL AX, 1
    MOV BX, AX          ; Turn the token type into an index
    JMP [_parg_table_ + BX] ; Jump to the corresponding address
_parg_table_    DW 2 DUP (ERROR_EXPECTED_ARG)
                DW PARSE_BARE_PTR_ARG_
                DW 3 DUP (ERROR_EXPECTED_ARG)
                DW 2 DUP (PARSE_NUMBER_ARG_)
                DW 2 DUP (ERROR_EXPECTED_ARG)
                DW PARSE_REGISTER_ARG_
                DW PARSE_SEGMENT_ARG_
                DW PARSE_KEYWORD_ARG_
                DW 2 DUP (PARSE_NUMBER_ARG_)
                DW PARSE_STRING_ARG_

; Procedure PARSE_NUMBER_ARG_
; Parses an argument containing a number
; Inputs:
;   DI the location of the buffer to store the argument in
; Destroys:
;   AX, BX, CX, DX, SI, flags
PARSE_NUMBER_ARG_:
    XOR AX, AX              ; Value in DL:AX
    XOR DX, DX
    MOV DH, LBL_NONE        ; Label type in DH
    PUSH DI
    CALL PARSE_NUMBER_EXPR_ ; Parse the numeric expression
    POP DI
    CALL _pnumarg_check_range_  ; Check if the number is in range
    CMP_TOKEN_TYPE TK_COLON ; Dword if there's a colon
    JZ _pnumarg_dword_
    MOV WORD PTR [DI + ARG_WORD], AX    ; Save the value
    CMP DH, LBL_NONE        ; Word type if it's a label
    JNZ _pnumarg_word_
    CMP DL, 0
    JZ _pnumarg_pos_
    CMP AX, -128
    JL _pnumarg_word_
    JMP _pnumarg_byte_
_pnumarg_pos_:
    CMP AX, 255
    JA _pnumarg_word_
_pnumarg_byte_:
    MOV BYTE PTR [DI + ARG_TYPE], ARGT_NUM + ARGS_BYTE
    RET
_pnumarg_word_:
    MOV BYTE PTR [DI + ARG_TYPE], ARGT_NUM + ARGS_WORD
    RET
_pnumarg_dword_:
    PUSH AX
    PUSH DI
    CALL LEXER_NEXT         ; Skip the colon
    XOR AX, AX
    XOR DX, DX
    CALL PARSE_NUMBER_EXPR_ ; Parse another number
    POP DI
    CALL _pnumarg_check_range_
    MOV BYTE PTR [DI + ARG_TYPE], ARGT_NUM + ARGS_DWORD
    MOV WORD PTR [DI + ARG_WORD], AX        ; Save the offset
    POP AX
    MOV WORD PTR [DI + ARG_WORD + 2], AX    ; Save the segment
    RET
_pnumarg_check_range_:
    CMP DL, 0               ; If DL > 1, the number is > 65535
    JG _pnumarg_overflow_
    CMP DL, -1              ; If DL < -1, the number is < -65536
    JL _pnumarg_underflow_
    JZ _pnumarg_checkneg_
    RET
_pnumarg_checkneg_:
    TEST AX, 8000h          ; If DL=-1 and AX LSB = 0
    JZ _pnumarg_underflow_  ; the number is < -32768
    RET
_pnumarg_overflow_:
    JMP ERROR_OVERFLOW
_pnumarg_underflow_:
    JMP ERROR_UNDERFLOW

; Procedure PARSE_STRING_ARG_
; Parses an argument containing a string
; Inputs:
;   DI the location of the buffer to store the argument in
; Destroys:
;   AX, BX, CX, DX, SI, flags
PARSE_STRING_ARG_:
    CMP_TOKEN_VALUE 1  ; Is the length 1?
    JZ _pstrarg_byte_   ; Yes, so return a byte argument
    PUSH DI
    MOV SI, TOKEN + TOKEN_STRLEN
    XOR CX, CX
    MOV CL, [SI]
    INC CX
    ADD DI, ARG_STRLEN
    CLD
    REP MOVSB           ; Copy the string from the token to the arg
    POP DI
    MOV BYTE PTR [DI + ARG_TYPE], ARGT_STR  ; Set the type
    JMP SHORT _pstrarg_ret_
_pstrarg_byte_:
    MOV AL, BYTE PTR [TOKEN + TOKEN_STR]
    XOR AH, AH
    MOV BYTE PTR [DI + ARG_TYPE], ARGT_NUM + ARGS_BYTE  ; Set the type
    MOV WORD PTR [DI + ARG_WORD], AX        ; Copy the value
_pstrarg_ret_:
    PUSH DI
    CALL LEXER_NEXT
    POP DI
    RET

; Procedure PARSE_REGISTER_ARG_
; Parses an argument containing a register
; Inputs:
;   DI the location of the buffer to store the argument in
; Destroys:
;   AX, BX, CX, DX, SI, flags
PARSE_REGISTER_ARG_:
    LD_TOKEN_VALUE
    CMP AL, REG_AL      ; AX and AL map to the same values
    JAE _pregarg_8bit_  ; so we have to jump appropriately
    MOV BYTE PTR [DI + ARG_TYPE], ARGT_REG + ARGS_WORD
    MOV BYTE PTR [DI + ARG_REGISTER], AL
    JMP SHORT _pregarg_ret_
_pregarg_8bit_:
    SUB AL, REG_AL
    MOV BYTE PTR [DI + ARG_TYPE], ARGT_REG + ARGS_BYTE
    MOV BYTE PTR [DI + ARG_REGISTER], AL
_pregarg_ret_:
    PUSH DI
    CALL LEXER_NEXT
    POP DI
    RET

; Procedure PARSE_SEGMENT_ARG_
; Parses an argument containing a segment
; Inputs:
;   DI the location of the buffer to store the argument in
; Destroys:
;   AX, BX, CX, DX, SI, flags
PARSE_SEGMENT_ARG_:
    LD_TOKEN_VALUE
    MOV BYTE PTR [DI + ARG_SEGMENT], AL
    PUSH DI
    CALL LEXER_NEXT
    CMP_TOKEN_TYPE TK_COLON
    JZ _psegarg_ptr_
    POP DI
    MOV BYTE PTR [DI + ARG_TYPE], ARGT_SEG
    RET
_psegarg_ptr_:
    CALL LEXER_NEXT
    POP DI
    CMP_TOKEN_TYPE TK_LBRACKET
    JNZ _psegarg_bracket_
    MOV BYTE PTR [DI + ARG_EAMODE], EA_SEGMENT
    JMP PARSE_BARE_PTR_ARG_
_psegarg_bracket_:
    JMP ERROR_EXPECTED_LBRACKET

; Procedure PARSE_BARE_PTR_ARG_
; Parses a pointer
; Inputs:
;   DI the location of the buffer to store the argument in
; Destroys:
;   AX, BX, CX, DX, SI, flags
PARSE_BARE_PTR_ARG_:
    ; Parse the EA mode
    PUSH DI
    CALL LEXER_NEXT
    POP DI
    XOR CX, CX          ; CH=BX/BP CL=SI/DI
    XOR AX, AX
    PUSH AX
    PUSH AX             ; Save DL:AX and DH in the stack
_pbpa_loop_:            ; Parse the part in brackets
    LD_TOKEN_TYPE
    CMP AL, TK_REGISTER     ; Register?
    JZ _pbpa_register_
    CMP AL, TK_PLUS         ; Plus,
    JZ _pbpa_offset_
    CMP AL, TK_MINUS        ; minus,
    JZ _pbpa_offset_
    CMP AL, TK_NUMBER       ; number,
    JZ _pbpa_offset_
    CMP AL, TK_IDENTIFIER   ; identifier?
    JZ _pbpa_offset_
    JMP ERROR_EXPECTED_EA_PART
_pbpa_parse_token_:
    LD_TOKEN_TYPE
    CMP AL, TK_RBRACKET     ; left bracket?
    JZ _pbpa_loop_break_
    CMP AL, TK_PLUS         ; plus sign?
    JZ _pbpa_plus_
    CMP AL, TK_MINUS        ; minus sign?
    JZ _pbpa_loop_
    JMP ERROR_EXPECTED_EA_END
_pbpa_register_:
    LD_TOKEN_VALUE
    CMP AL, REG_BX
    JZ _pbpa_reg_bx_
    CMP AL, REG_BP
    JZ _pbpa_reg_bp_
    CMP AL, REG_SI
    JZ _pbpa_reg_si_
    CMP AL, REG_DI
    JZ _pbpa_reg_di_
    JMP ERROR_EXPECTED_EA_PART
_pbpa_reg_bx_:
    CMP CH, 0
    JNZ _pbpa_bad_reg_      ; only allow one BX
    MOV CH, 1
    JMP _pbpa_next_token_
_pbpa_reg_bp_:
    CMP CH, 0
    JNZ _pbpa_bad_reg_      ; only allow one BP
    MOV CH, 2
    JMP _pbpa_next_token_
_pbpa_reg_si_:
    CMP CL, 0
    JNZ _pbpa_bad_reg_      ; only allow one SI
    MOV CL, 1
    JMP _pbpa_next_token_
_pbpa_reg_di_:
    CMP CL, 0
    JNZ _pbpa_bad_reg_      ; only allow one DI
    MOV CL, 2
    JMP _pbpa_next_token_
_pbpa_bad_reg_:
    JMP ERROR_EXPECTED_EA_ONE_REG
_pbpa_next_token_:
    PUSH CX
    PUSH DI
    CALL LEXER_NEXT
    POP DI
    POP CX
    JMP _pbpa_parse_token_
_pbpa_offset_:
    PUSH CX
    PUSH DI
    CALL PARSE_SINGLE_NUMBER_
    POP DI
    POP CX
    POP BX                  ; Add the parsed number
    ADD AX, BX
    POP BX
    CMP BH, LBL_NONE
    JZ _pbpa_noset_label_
    MOV DH, BH
_pbpa_noset_label_:
    PUSH DX
    PUSH AX
    JMP _pbpa_parse_token_
_pbpa_plus_:
    PUSH CX
    PUSH DI
    CALL LEXER_NEXT
    POP DI
    POP CX
    JMP _pbpa_loop_

_pbpa_loop_break_:          ; Done parsing; now make sense of it
    ; Remove redundant segment override
    MOV AH, BYTE PTR [DI + ARG_EAMODE]
    TEST AH, EA_SEGMENT
    JZ _pbpa_noseg_
    MOV AL, BYTE PTR [DI + ARG_SEGMENT]
    CMP CH, 2
    JZ _pbpa_seg_bp_        ; BP? then remove redundant SS
    CMP AL, ASEG_DS         ; And for BX, remove redundant DS
    JNZ _pbpa_noseg_
    JMP _pbpa_rmseg_
_pbpa_seg_bp_:
    CMP AL, ASEG_SS
    JNZ _pbpa_noseg_
_pbpa_rmseg_:
    AND AH, EA_NOSEGMENT
    MOV BYTE PTR [DI + ARG_EAMODE], AH
_pbpa_noseg_:

    ; Set the offset and offset flags
    XOR AX, AX
    MOV AH, BYTE PTR [DI + ARG_EAMODE]
    MOV AL, CH
    ADD AL, CH
    ADD AL, CH
    ADD AL, CL      ; AL = (BXBP * 3) + DISI, AH = EA mode
    POP CX
    POP DX          ; CX = offset, DH = label type
    CMP AL, 0       ; If only offset, set the offset
    JZ _pbpa_setoffset_
    CMP DH, LBL_NONE    ; If there is a label, flag the label
    JNZ _pbpa_flagoffset16_
    CMP CX, 0       ; If offset is not zero, flag the offset
    JNZ _pbpa_flagoffset_
    JMP _pbpa_nooffset_
_pbpa_flagoffset16_:
    OR AH, EA_OFFSET16
_pbpa_flagoffset_:
    OR AH, EA_OFFSET
_pbpa_setoffset_:
    MOV WORD PTR [DI + ARG_OFFSET], CX
_pbpa_nooffset_:

    ; Set the EA mode bytes
    MOV BX, _pbpa_eatable_
    XLAT            ; AL now has the entry from _pbpa_eatable_
    OR AH, AL
    MOV BYTE PTR [DI + ARG_EAMODE], AH

    ; Set the size
    MOV AL, ARGT_PTR + ARGS_BYTE
    CMP DH, LBL_BYTEADDR            ; Byte?
    JZ _pbpa_setsize_
    MOV AL, ARGT_PTR + ARGS_WORD
    CMP DH, LBL_WORDADDR            ; Word?
    JZ _pbpa_setsize_
    MOV AL, ARGT_PTR + ARGS_DWORD
    CMP DH, LBL_DWORDADDR           ; Dword?
    JZ _pbpa_setsize_
    MOV AL, ARGT_PTR
_pbpa_setsize_:
    MOV BYTE PTR [DI + ARG_TYPE], AL
    PUSH DI
    CALL LEXER_NEXT
    POP DI
    RET
_pbpa_eatable_  DB EA_DIRECT, EA_SI, EA_DI
                DB EA_BX, EA_BXSI, EA_BXDI
                DB EA_BP + EA_OFFSET, EA_BPSI, EA_BPDI

; Procedure PARSE_KEYWORD_ARG_
; Parses a keyword argument
; Inputs:
;   DI the location of the buffer to store the argument in
; Destroys:
;   AX, BX, CX, DX, SI, flags
PARSE_KEYWORD_ARG_:
    LD_TOKEN_VALUE
    MOV AH, ARGS_BYTE
    CMP AL, KW_BYTE
    JZ _pkwarg_size_
    MOV AH, ARGS_WORD
    CMP AL, KW_WORD
    JZ _pkwarg_size_
    MOV AH, ARGS_DWORD
    CMP AL, KW_DWORD
    JZ _pkwarg_size_
    MOV AH, DST_SHORT
    CMP AL, KW_SHORT
    JZ _pkwarg_distance_
    MOV AH, DST_NEAR
    CMP AL, KW_NEAR
    JZ _pkwarg_distance_
    MOV AH, DST_FAR
    CMP AL, KW_FAR
    JZ _pkwarg_distance_
    JMP ERROR_EXPECTED_SIZE_DISTANCE
_pkwarg_size_:
    PUSH AX
    PUSH DI
    CALL LEXER_NEXT
    CMP_TOKEN_TYPE TK_KEYWORD
    JNZ _pkwarg_noptr_
    CMP_TOKEN_VALUE KW_PTR
    JNZ _pkwarg_noptr_
    CALL LEXER_NEXT
    POP DI
    CALL PARSE_PTR_ARG_
    POP AX
    MOV AL, BYTE PTR [DI + ARG_TYPE]
    AND AL, ARGT_MASK
    OR AL, AH
    MOV BYTE PTR [DI + ARG_TYPE], AL
    RET
_pkwarg_noptr_:
    JMP ERROR_EXPECTED_PTR
_pkwarg_distance_:
    CMP BYTE PTR [DI + ARG_DISTANCE], 0
    JZ _pkwarg_distance_ok_
    JMP ERROR_UNEXPECTED_DISTANCE
_pkwarg_distance_ok_:
    MOV [DI + ARG_DISTANCE], AH
    PUSH DI
    CALL LEXER_NEXT
    POP DI
    CALL PARSE_ARGUMENT_
    MOV AL, BYTE PTR [DI + ARG_TYPE]
    MOV AH, BYTE PTR [DI + ARG_DISTANCE]
    CMP AH, DST_SHORT
    JNZ _pkwarg_maybe_near_
    CMP AL, ARGT_NUM + ARGS_BYTE
    JZ _pkwarg_distance_ret_
    CMP AL, ARGT_NUM + ARGS_WORD
    JZ _pkwarg_distance_ret_
    JMP ERROR_INVALID_SHORT_TARGET
_pkwarg_maybe_near_:
    CMP AH, DST_NEAR
    JNZ _pkwarg_far_
    CMP AL, ARGT_PTR
    JNZ _pkwarg_maybe_near_size_
    OR AL, ARGS_WORD
    MOV BYTE PTR [DI + ARG_TYPE], AL
    JMP _pkwarg_distance_ret_
_pkwarg_maybe_near_size_:
    TEST AL, ARGS_BYTE
    JNZ _pkwarg_distance_ret_
    TEST AL, ARGS_WORD
    JNZ _pkwarg_distance_ret_
    JMP ERROR_INVALID_NEAR_TARGET
_pkwarg_far_:
    CMP AL, ARGT_PTR
    JNZ _pkwarg_maybe_far_size_
    OR AL, ARGS_DWORD
    MOV BYTE PTR [DI + ARG_TYPE], AL
    JMP _pkwarg_distance_ret_
_pkwarg_maybe_far_size_:
    TEST AL, ARGS_DWORD
    JNZ _pkwarg_distance_ret_
    JMP ERROR_INVALID_FAR_TARGET
_pkwarg_distance_ret_:
    RET

; Procedure PARSE_PTR_ARG_
; Parses a pointer argument
; Inputs:
;   DI the location of the buffer to store the argument in
; Destroys:
;   AX, BX, CX, DX, SI, flags
PARSE_PTR_ARG_:
    CMP_TOKEN_TYPE TK_SEGMENT
    JNZ _pptrarg_noseg_
    MOV AL, BYTE PTR [TOKEN + TOKEN_SEGMENT]
    MOV BYTE PTR [DI + ARG_SEGMENT], AL
    MOV AL, BYTE PTR [DI + ARG_EAMODE]
    OR AL, EA_SEGMENT
    MOV BYTE PTR [DI + ARG_EAMODE], AL
    PUSH DI
    CALL LEXER_NEXT
    CMP_TOKEN_TYPE TK_COLON
    JZ _pptrarg_colon_
    JMP ERROR_EXPECTED_COLON
_pptrarg_colon_:
    CALL LEXER_NEXT
    POP DI
_pptrarg_noseg_:
    CMP_TOKEN_TYPE TK_LBRACKET
    JZ _pptrarg_lbracket_
    JMP ERROR_EXPECTED_LBRACKET
_pptrarg_lbracket_:
    JMP PARSE_BARE_PTR_ARG_

