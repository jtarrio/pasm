ERROR_FILE_OPEN_READ:
    MOV DX, error_file_open_read_msg
    JMP PRINT_ERROR_NOLINE
error_file_open_read_msg    DB 'Error opening file for read$'

ERROR_SEEK:
    MOV DX, error_seek_msg
    JMP PRINT_ERROR_NOLINE
error_seek_msg DB 'Seek error$'

ERROR_READ:
    MOV DX, error_read_msg
    JMP PRINT_ERROR_NOLINE
error_read_msg DB 'Read error$'

ERROR_INVALID_CHAR:
    MOV AL, [LX_RAWC]
    MOV [error_invalid_char_chr], AL
    MOV DX, error_invalid_char_msg
    JMP PRINT_ERROR
error_invalid_char_msg  DB 'Invalid character ',39
error_invalid_char_chr  DB 0
                        DB 39,'$'

ERROR_UNEXPECTED_EOF:
    MOV DX, error_unexpected_eof_msg
    JMP PRINT_ERROR
error_unexpected_eof_msg DB 'Unexpected end of file$'

ERROR_UNEXPECTED_EOL:
    MOV DX, error_unexpected_eol_msg
    JMP PRINT_ERROR
error_unexpected_eol_msg DB 'Unexpected end of line$'

ERROR_STRING_TOO_LONG:
    MOV DX, error_string_too_long_msg
    JMP PRINT_ERROR
error_string_too_long_msg DB 'String too long$'

ERROR_IDENTIFIER_TOO_LONG:
    MOV DX, error_identifier_too_long_msg
    JMP PRINT_ERROR
error_identifier_too_long_msg DB 'Identifier too long$'

ERROR_NUMBER_TOO_LARGE:
    MOV DX, error_number_too_large_msg
    JMP PRINT_ERROR
error_number_too_large_msg DB 'Number too large$'

ERROR_INVALID_DIGIT:
    MOV DX, error_invalid_digit_msg
    JMP PRINT_ERROR
error_invalid_digit_msg DB 'Invalid digit$'

ERROR_MEMORY:
    MOV DX, error_memory_msg
    JMP PRINT_ERROR_NOLINE
error_memory_msg DB 'Not enough memory$'

ERROR_DUPLICATE_LABEL:
    MOV DX, error_duplicate_label_msg
    JMP PRINT_ERROR
error_duplicate_label_msg DB 'Duplicate label$'

ERROR_LABEL_NOT_FOUND:
    MOV DX, error_label_not_found_msg
    JMP PRINT_ERROR
error_label_not_found_msg DB 'Unknown label$'

ERROR_LABEL_CHANGED_ADDR:
    MOV DX, error_label_changed_addr_msg
    JMP PRINT_ERROR
error_label_changed_addr_msg DB 'Internal error: label changed address between passes$'

; Procedure PRINT_ERROR
; Displays an error message and exits.
; Inputs:
;   DX the error message
PRINT_ERROR:
    PUSH CS
    POP DS
    CMP [LINE], 0
    JZ PRINT_ERROR_NOLINE
    PUSH DX
    MOV AX, [LINE]
    CALL PRINT_UINT16_DEC
    MOV AH, 09h
    MOV DX, _pe_colon_
    INT 21h
    POP DX
PRINT_ERROR_NOLINE:
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
