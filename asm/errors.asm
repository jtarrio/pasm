ERROR_FILE_OPEN_READ:
    MOV DX, _em_file_open_read
    JMP PRINT_ERROR
_em_file_open_read    DB 'Error opening file for read$'

ERROR_SEEK:
    MOV DX, _em_seek
    JMP PRINT_ERROR
_em_seek DB 'Seek error$'

ERROR_READ:
    MOV DX, _em_read
    JMP PRINT_ERROR
_em_read DB 'Read error$'

ERROR_INVALID_CHAR:
    MOV AL, [LX_RAWC]
    MOV [_em_invalid_char_chr], AL
    MOV DX, _em_invalid_char
    JMP PRINT_ERROR_LINE
_em_invalid_char  DB 'Invalid character ',39
_em_invalid_char_chr  DB 0
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
    MOV DX, _em_invalid_digit
    JMP PRINT_ERROR_LINE
_em_invalid_digit DB 'Invalid digit$'

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
    MOV DX, _em_overflow_msg
    JMP PRINT_ERROR_LINE
_em_overflow_msg DB 'Overflow$'

ERROR_UNDERFLOW:
    MOV DX, _em_underflow_msg
    JMP PRINT_ERROR_LINE
_em_underflow_msg DB 'Underflow$'

; Procedure PRINT_ERROR_LINE
; Displays an error message with a line number and exits.
; Inputs:
;   DX the error message
PRINT_ERROR_LINE:
    PUSH CS
    POP DS
    CMP [LINE], 0
    JZ PRINT_ERROR
    PUSH DX
    MOV AX, [LINE]
    CALL PRINT_UINT16_DEC
    MOV AH, 09h
    MOV DX, _pe_colon_
    INT 21h
    POP DX
    ; fall through to PRINT_ERROR

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
_pe_colon_  DB ': $'
_pe_crlf_   DB 13, 10, '$'
