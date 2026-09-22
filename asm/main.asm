start:
    MOV AH, 09h             ; Display the copyright notice
    MOV DX, copyright
    INT 21h

    CALL RESERVE_MEMORY

    ; Open 'pasm.asm'
    MOV AX, 3D00h
    MOV DX, pasm_asm
    INT 21h
    JNC start_assembly
    JMP ERROR_FILE_OPEN_READ

start_assembly:
    CALL LEXER_START
    CALL ASSEMBLE

    ; Open 'pasm.co2'
    MOV AH, 3Ch
    XOR CX, CX
    MOV DX, pasm_co2
    INT 21h
    JC output_error
    MOV [OUTPUT], AX
    CALL ASSEMBLE

    CALL WRITE_FLUSH

    MOV AH, 3Eh
    MOV BX, [LX_FILE_HANDLE]
    INT 21h
    MOV AH, 3Eh
    MOV BX, [OUTPUT]
    INT 21h

    MOV AX, 4C00h
    INT 21h

output_error:
    JMP ERROR_FILE_OPEN_WRITE

copyright   DB 'PASM version ', version, ' Copyright 2026 Jacobo Tarrio.'
            DB 13,10,'$'
pasm_asm    DB 'pasm.asm',0
pasm_co2    DB 'pasm.co2',0


; Procedure RESERVE_MEMORY
; Prepares the storage space for labels and macros
; Output:
;   [LABELSEG] the segment where the labels are stored
;   [MACROSEG] the segment where the macros are stored
RESERVE_MEMORY:
    PUSH AX
    PUSH BX
    PUSH ES
    PUSHF
    ; Check if there is enough memory
    MOV AX, [0002h]     ; Last segment allocated to the program
    MOV BX, CS
    SUB AX, BX          ; See how much memory has been allocated
    CMP AX, 3000h       ; We need at least 3 segments (1000h paras each)
    JAE _pl_ok_
    JMP ERROR_MEMORY
_pl_ok_:
    MOV AX, CS          ; Get the segment right after CS
    ADD AX, 1000h
    MOV [LABELSEG], AX  ; and store it in LABELSEG
    MOV ES, AX          ; Mark the first non-label
    MOV BYTE PTR ES:[0 + LABEL_TYPE], LBL_NONE
    ADD AX, 1000h       ; Next segment
    MOV [MACROSEG], AX  ; store it in MACROSEG
    CALL RESET_MACROS
    POPF
    POP ES
    POP BX
    POP AX
    RET
