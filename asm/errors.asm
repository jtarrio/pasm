ERROR_FILE_OPEN_READ:
    MOV DX, error_file_open_read_msg
    JMP PRINT_ERROR
error_file_open_read_msg    DB 'Error opening file for read$'

ERROR_SEEK:
    MOV DX, error_seek_msg
    JMP PRINT_ERROR
error_seek_msg DB 'Seek error$'

ERROR_READ:
    MOV DX, error_read_msg
    JMP PRINT_ERROR
error_read_msg DB 'Read error$'

ERROR_INVALID_CHAR:
    MOV AL, [LX_RAWC]
    MOV [error_invalid_char_chr], AL
    MOV DX, error_invalid_char_msg
    JMP PRINT_ERROR_LINE
error_invalid_char_msg  DB 'Invalid character ',39
error_invalid_char_chr  DB 0
                        DB 39,'$'

ERROR_UNEXPECTED_EOF:
    MOV DX, error_unexpected_eof_msg
    JMP PRINT_ERROR_LINE
error_unexpected_eof_msg DB 'Unexpected end of file$'

ERROR_UNEXPECTED_EOL:
    MOV DX, error_unexpected_eol_msg
    JMP PRINT_ERROR_LINE
error_unexpected_eol_msg DB 'Unexpected end of line$'

ERROR_STRING_TOO_LONG:
    MOV DX, error_string_too_long_msg
    JMP PRINT_ERROR_LINE
error_string_too_long_msg DB 'String too long$'

ERROR_IDENTIFIER_TOO_LONG:
    MOV DX, error_identifier_too_long_msg
    JMP PRINT_ERROR_LINE
error_identifier_too_long_msg DB 'Identifier too long$'

ERROR_NUMBER_TOO_LARGE:
    MOV DX, error_number_too_large_msg
    JMP PRINT_ERROR_LINE
error_number_too_large_msg DB 'Number too large$'

ERROR_INVALID_DIGIT:
    MOV DX, error_invalid_digit_msg
    JMP PRINT_ERROR_LINE
error_invalid_digit_msg DB 'Invalid digit$'

ERROR_MEMORY:
    MOV DX, error_memory_msg
    JMP PRINT_ERROR
error_memory_msg DB 'Not enough memory$'

ERROR_DUPLICATE_LABEL:
    MOV DX, error_duplicate_label_msg
    JMP PRINT_ERROR_LINE
error_duplicate_label_msg DB 'Duplicate label$'

ERROR_LABEL_NOT_FOUND:
    MOV DX, error_label_not_found_msg
    JMP PRINT_ERROR_LINE
error_label_not_found_msg DB 'Unknown label$'

ERROR_LABEL_CHANGED_ADDR:
    MOV DX, error_label_changed_addr_msg
    JMP PRINT_ERROR_LINE
error_label_changed_addr_msg DB 'Internal error: label changed address between passes$'

ERROR_EXPECTED_EOL:
    MOV DX, error_expected_eol_msg
    JMP PRINT_ERROR_LINE
error_expected_eol_msg DB 'Expected an end of line$'

ERROR_EXPECTED_LABEL_KEYWORD:
    MOV DX, error_expected_label_kw_msg
    JMP PRINT_ERROR_LINE
error_expected_label_kw_msg DB 'Expected a label or keyword$'

ERROR_EXPECTED_AFTER_LABEL:
    MOV DX, error_expected_after_lbl_msg
    JMP PRINT_ERROR_LINE
error_expected_after_lbl_msg DB 'Expected a colon, DB, DW, DD, or EQU$'

ERROR_EXPECTED_KEYWORD:
    MOV DX, error_expected_kw_msg
    JMP PRINT_ERROR_LINE
error_expected_kw_msg DB 'Expected a keyword$'

ERROR_EXPECTED_NUMBER:
    MOV DX, error_expected_num_msg
    JMP PRINT_ERROR_LINE
error_expected_num_msg DB 'Expected a number$'

ERROR_EXPECTED_NUMBER_LABEL:
    MOV DX, error_expected_numlbl_msg
    JMP PRINT_ERROR_LINE
error_expected_numlbl_msg DB 'Expected a number or label$'

ERROR_EXPECTED_BYTE_STRING:
    MOV DX, error_expected_byte_str_msg
    JMP PRINT_ERROR_LINE
error_expected_byte_str_msg DB 'Expected a byte or a string$'

ERROR_EXPECTED_WORD:
    MOV DX, error_expected_word_msg
    JMP PRINT_ERROR_LINE
error_expected_word_msg DB 'Expected a word$'

ERROR_EXPECTED_DWORD:
    MOV DX, error_expected_dword_msg
    JMP PRINT_ERROR_LINE
error_expected_dword_msg DB 'Expected a doubleword$'

ERROR_EXPECTED_COMMA:
    MOV DX, error_expected_comma_msg
    JMP PRINT_ERROR_LINE
error_expected_comma_msg DB 'Expected a comma$'

ERROR_EXPECTED_LPAREN:
    MOV DX, error_expected_lparen_msg
    JMP PRINT_ERROR_LINE
error_expected_lparen_msg DB 'Expected a left parenthesis$'

ERROR_EXPECTED_RPAREN:
    MOV DX, error_expected_rparen_msg
    JMP PRINT_ERROR_LINE
error_expected_rparen_msg DB 'Expected a right parenthesis$'

ERROR_EXPECTED_LBRACKET:
    MOV DX, error_expected_lbracket_msg
    JMP PRINT_ERROR_LINE
error_expected_lbracket_msg DB 'Expected a left bracket$'

ERROR_EXPECTED_ARG:
    MOV DX, error_expected_arg_msg
    JMP PRINT_ERROR_LINE
error_expected_arg_msg DB 'Expected an argument$'

ERROR_EXPECTED_EA_PART:
    MOV DX, error_expected_eapart_msg
    JMP PRINT_ERROR_LINE
error_expected_eapart_msg DB 'Expected BX, BP, SI, DI, or an offset$'

ERROR_OVERFLOW:
    MOV DX, error_overflow_msg
    JMP PRINT_ERROR_LINE
error_overflow_msg DB 'Overflow$'

ERROR_UNDERFLOW:
    MOV DX, error_underflow_msg
    JMP PRINT_ERROR_LINE
error_underflow_msg DB 'Underflow$'

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
