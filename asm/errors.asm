ERROR_NO_SOURCE:
    MOV DX, _em_no_source
    JMP PRINT_ERROR
_em_no_source DB 'No source file was specified$'

ERROR_FILE_OPEN_READ:
    MOV DX, _em_file_open_read
    JMP PRINT_ERROR
_em_file_open_read DB 'Error opening file for read$'

ERROR_FILE_OPEN_WRITE:
    MOV DX, _em_file_open_write
    JMP PRINT_ERROR
_em_file_open_write DB 'Error opening file for write$'

ERROR_SEEK:
    MOV DX, _em_seek
    JMP PRINT_ERROR
_em_seek DB 'Seek error$'

ERROR_READ:
    MOV DX, _em_read
    JMP PRINT_ERROR
_em_read DB 'Read error$'

ERROR_WRITE:
    MOV DX, _em_write
    JMP PRINT_ERROR
_em_write DB 'Write error$'

ERROR_INVALID_CHAR:
    MOV AL, [LX_RAWC]
    MOV [_eim_char_chr], AL
    MOV DX, _eim_char
    JMP PRINT_ERROR_LINE
_eim_char       DB 'Invalid character ',39
_eim_char_chr   DB 0
                DB 39,'$'

ERROR_UNEXPECTED_EOF:
    MOV DX, _eum_eof
    JMP PRINT_ERROR_LINE
_eum_eof DB 'Unexpected end of file$'

ERROR_UNEXPECTED_EOL:
    MOV DX, _eum_eol
    JMP PRINT_ERROR_LINE
_eum_eol DB 'Unexpected end of line$'

ERROR_STRING_TOO_LONG:
    MOV DX, _em_string_too_long
    JMP PRINT_ERROR_LINE
_em_string_too_long DB 'String too long$'

ERROR_IDENTIFIER_TOO_LONG:
    MOV DX, _em_identifier_too_long
    JMP PRINT_ERROR_LINE
_em_identifier_too_long DB 'Identifier too long$'

ERROR_NUMBER_TOO_LARGE:
    MOV DX, _em_number_too_large
    JMP PRINT_ERROR_LINE
_em_number_too_large DB 'Number too large$'

ERROR_INVALID_DIGIT:
    MOV DX, _eim_digit
    JMP PRINT_ERROR_LINE
_eim_digit DB 'Invalid digit$'

ERROR_MEMORY:
    MOV DX, _em_memory
    JMP PRINT_ERROR
_em_memory DB 'Not enough memory$'

ERROR_DUPLICATE_LABEL:
    MOV DX, _em_duplicate_label
    JMP PRINT_ERROR_LINE
_em_duplicate_label DB 'Duplicate label$'

ERROR_LABEL_NOT_FOUND:
    MOV DX, _em_label_not_found
    JMP PRINT_ERROR_LINE
_em_label_not_found DB 'Unknown label$'

ERROR_LABEL_CHANGED_ADDR:
    MOV DX, _em_label_changed_addr
    JMP PRINT_ERROR_LINE
_em_label_changed_addr DB 'Internal error: label changed address between passes$'

ERROR_EXPECTED_EOL:
    MOV DX, _eem_eol
    JMP PRINT_ERROR_LINE
_eem_eol DB 'Expected an end of line$'

ERROR_EXPECTED_LABEL_KEYWORD:
    MOV DX, _eem_label_kw
    JMP PRINT_ERROR_LINE
_eem_label_kw DB 'Expected a label or keyword$'

ERROR_EXPECTED_AFTER_LABEL:
    MOV DX, _eem_after_lbl
    JMP PRINT_ERROR_LINE
_eem_after_lbl DB 'Expected a colon, DB, DW, DD, or EQU$'

ERROR_EXPECTED_KEYWORD:
    MOV DX, _eem_kw
    JMP PRINT_ERROR_LINE
_eem_kw DB 'Expected a keyword$'

ERROR_EXPECTED_INSTRUCTION:
    MOV DX, _eem_instruction
    JMP PRINT_ERROR_LINE
_eem_instruction DB 'Expected an instruction$'

ERROR_EXPECTED_NUMBER:
    MOV DX, _eem_num
    JMP PRINT_ERROR_LINE
_eem_num DB 'Expected a number$'

ERROR_EXPECTED_NUMBER_LABEL:
    MOV DX, _eem_numlbl
    JMP PRINT_ERROR_LINE
_eem_numlbl DB 'Expected a number or label$'

ERROR_EXPECTED_BYTE_STRING:
    MOV DX, _eem_byte_str
    JMP PRINT_ERROR_LINE
_eem_byte_str DB 'Expected a byte or a string$'

ERROR_EXPECTED_WORD:
    MOV DX, _eem_word
    JMP PRINT_ERROR_LINE
_eem_word DB 'Expected a word$'

ERROR_EXPECTED_DWORD:
    MOV DX, _eem_dword
    JMP PRINT_ERROR_LINE
_eem_dword DB 'Expected a doubleword$'

ERROR_EXPECTED_COMMA:
    MOV DX, _eem_comma
    JMP PRINT_ERROR_LINE
_eem_comma DB 'Expected a comma$'

ERROR_EXPECTED_LPAREN:
    MOV DX, _eem_lparen
    JMP PRINT_ERROR_LINE
_eem_lparen DB 'Expected a left parenthesis$'

ERROR_EXPECTED_RPAREN:
    MOV DX, _eem_rparen
    JMP PRINT_ERROR_LINE
_eem_rparen DB 'Expected a right parenthesis$'

ERROR_EXPECTED_COLON:
    MOV DX, _eem_colon
    JMP PRINT_ERROR_LINE
_eem_colon DB 'Expected a colon'

ERROR_EXPECTED_LBRACKET:
    MOV DX, _eem_lbracket
    JMP PRINT_ERROR_LINE
_eem_lbracket DB 'Expected a left bracket$'

ERROR_EXPECTED_ARG:
    MOV DX, _eem_arg
    JMP PRINT_ERROR_LINE
_eem_arg DB 'Expected an argument$'

ERROR_EXPECTED_EA_PART:
    MOV DX, _eem_eapart
    JMP PRINT_ERROR_LINE
_eem_eapart DB 'Expected BX, BP, SI, DI, or an offset$'

ERROR_EXPECTED_EA_ONE_REG:
    MOV DX, _eem_eaonereg
    JMP PRINT_ERROR_LINE
_eem_eaonereg DB 'Expected only one BX, BP, SI or DI$'

ERROR_EXPECTED_EA_END:
    MOV DX, _eem_eaend
    JMP PRINT_ERROR_LINE
_eem_eaend DB 'Expected a right bracket or arithmetic operator$'

ERROR_OVERFLOW:
    MOV DX, _em_overflow
    JMP PRINT_ERROR_LINE
_em_overflow DB 'Overflow$'

ERROR_UNDERFLOW:
    MOV DX, _em_underflow
    JMP PRINT_ERROR_LINE
_em_underflow DB 'Underflow$'

ERROR_EXPECTED_SIZE_DISTANCE:
    MOV DX, _eem_size_distance
    JMP PRINT_ERROR_LINE
_eem_size_distance DB 'Expected a size or distance specifier$'

ERROR_EXPECTED_PTR:
    MOV DX, _eem_ptr
    JMP PRINT_ERROR_LINE
_eem_ptr DB 'Expected PTR$'

ERROR_UNEXPECTED_DISTANCE:
    MOV DX, _eum_distance
    JMP PRINT_ERROR_LINE
_eum_distance DB 'Unexpected distance specifier$'

ERROR_INVALID_SHORT_TARGET:
    MOV DX, _eim_short_target
    JMP PRINT_ERROR_LINE
_eim_short_target DB 'Invalid short target$'

ERROR_INVALID_NEAR_TARGET:
    MOV DX, _eim_near_target
    JMP PRINT_ERROR_LINE
_eim_near_target DB 'Invalid near target$'

ERROR_INVALID_FAR_TARGET:
    MOV DX, _eim_far_target
    JMP PRINT_ERROR_LINE
_eim_far_target DB 'Invalid far target$'

ERROR_ORG_REWIND:
    MOV DX, _em_org_rewind
    JMP PRINT_ERROR_LINE
_em_org_rewind DB 'Cannot rewind instruction pointer with ORG$'

ERROR_INVALID_PREFIX:
    MOV DX, _eim_prefix
    JMP PRINT_ERROR_LINE_1
_eim_prefix DB 'Internal error: unexpected prefix $'

ERROR_TOO_FAR:
    MOV DX, _em_too_far
    JMP PRINT_ERROR_LINE
_em_too_far DB 'Destination address is too far for a short jump$'

ERROR_UNEXPECTED_ARGUMENT:
    MOV DX, _eum_argument
    JMP PRINT_ERROR_LINE
_eum_argument DB 'Unexpected argument$'

ERROR_EXPECTED_1_ARGUMENT:
    MOV DX, _eem_1_argument
    JMP PRINT_ERROR_LINE
_eem_1_argument DB 'Unexpected second argument$'

ERROR_EXPECTED_2_ARGUMENTS:
    MOV DX, _eem_2_arguments
    JMP PRINT_ERROR_LINE
_eem_2_arguments DB 'Expected two arguments$'

ERROR_INVALID_ARG:
    MOV DX, _eim_arg
    JMP PRINT_ERROR_LINE
_eim_arg DB 'Invalid argument$'

ERROR_INVALID_ARGS:
    MOV DX, _eim_args
    JMP PRINT_ERROR_LINE
_eim_args DB 'Invalid arguments$'

ERROR_INVALID_ARG1:
    MOV DX, _eim_arg1
    JMP PRINT_ERROR_LINE
_eim_arg1 DB 'Invalid first argument$'

ERROR_INVALID_ARG2:
    MOV DX, _eim_arg2
    JMP PRINT_ERROR_LINE
_eim_arg2 DB 'Invalid second argument$'

ERROR_INVALID_ARG_BP:
    CMP BP, ARG1
    JZ _eiabp_err1_
    CMP BP, ARG2
    JZ _eiabp_err2_
    JMP ERROR_INVALID_ARG
_eiabp_err1_:
    JMP ERROR_INVALID_ARG1
_eiabp_err2_:
    JMP ERROR_INVALID_ARG2

; Procedure PRINT_ERROR_LINE
; Displays an error message with a line number and exits.
; Inputs:
;   DX the error message
PRINT_ERROR_LINE:
    CALL PRINT_ERROR_LINE_
    JMP PRINT_ERROR

; Procedure PRINT_ERROR_LINE_1
; Displays an error message with a line number and 1 argument and exits.
; Inputs:
;   DX the error message
PRINT_ERROR_LINE_1:
    CALL PRINT_ERROR_LINE_
    JMP PRINT_ERROR_1

PRINT_ERROR_LINE_:
    PUSH CS
    POP DS
    CMP WORD PTR [TOKEN + TOKEN_LINE], 0
    JZ PRINT_ERROR
    PUSH DX
    MOV AX, WORD PTR [TOKEN + TOKEN_LINE]
    CALL PRINT_UINT16_DEC
    MOV AH, 09h
    MOV DX, _pe_colon_
    INT 21h
    POP DX
    RET

; Procedure PRINT_ERROR
; Displays an error message and exits.
; Inputs:
;   DX the error message
PRINT_ERROR:
    PUSH CS
    POP DS
    MOV AH, 09h     ; Print string
    INT 21h
    MOV DX, _pe_crlf_
    INT 21h
    MOV AX, 4C01h   ; Exit with status 1
    INT 21h


; Procedure PRINT_ERROR_1
; Displays an error message with 1 numeric argument and exits.
; Inputs:
;   DX the error message
;   AX the argument
PRINT_ERROR_1:
    PUSH AX
    PUSH CS
    POP DS
    MOV AH, 09h     ; Print string
    INT 21h
    POP AX
    MOV BX, 16
    CALL PRINT_UINT16
    MOV DX, _pe_crlf_
    INT 21h
    MOV AX, 4C01h   ; Exit with status 1
    INT 21h
_pe_colon_  DB ': $'
_pe_crlf_   DB 13, 10, '$'
