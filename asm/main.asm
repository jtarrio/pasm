ERROR_FILE_OPEN_READ:
    MOV DX, error_file_open_read_msg
    JMP PRINT_ERROR
error_file_open_read_msg    DB 'Error opening file for read$'

start:
    MOV AH, 09h             ; Display the copyright notice
    MOV DX, copyright
    INT 21h

    ; Open 'pasm.asm'
    MOV AX, 3D00h
    MOV DX, pasm_asm
    INT 21h
    JC ERROR_FILE_OPEN_READ

    CALL LEXER_START

    MOV AX, 4C00h
    INT 21h

copyright   DB 'PASM version ', version, ' Copyright 2026 Jacobo Tarrio.'
            DB 13,10,'$'
pasm_asm    DB 'pasm.asm',0

