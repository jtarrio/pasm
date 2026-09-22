OUTPUT      DW 0        ; Assembler output handle
PC          DW 0        ; Program counter
OUT_BUFSIZE EQU 1024    ; Size of the output buffer
OUT_BUFPOS  DW 0        ; Position in the output buffer
OUT_BUFFER  DB OUT_BUFSIZE DUP (0)    ; Output buffer

; Procedure EMIT_ORG
; Inputs:
;   AX the new program pointer
EMIT_ORG:
    PUSH AX
    PUSH BX
    PUSH CX
    MOV BX, [PC]
    CMP BX, 0
    JZ _eorg_zero_
    CMP BX, AX
    JA _eorg_rewind_
    MOV CX, AX
    SUB CX, BX
    MOV AL, 0
    CALL WRITE_BYTES_
_eorg_zero_:
    POP CX
    POP BX
    POP AX
    MOV [PC], AX
    RET
_eorg_rewind_:
    JMP ERROR_ORG_REWIND

; Procedure EMIT_BYTE
; Inputs:
;   AL the byte to emit
EMIT_BYTE:
    INC [PC]
    JMP WRITE_BYTE_

; Procedure EMIT_WORD
; Inputs:
;   AX the word to emit
EMIT_WORD:
    PUSH AX
    ADD [PC], 2
    CALL WRITE_BYTE_
    MOV AL, AH
    CALL WRITE_BYTE_
    POP AX
    RET

; Procedure EMIT_DWORD
; Inputs:
;   DX:AX the dword to emit
EMIT_DWORD:
    PUSH AX
    ADD [PC], 4
    CALL WRITE_BYTE_
    MOV AL, AH
    CALL WRITE_BYTE_
    MOV AL, DL
    CALL WRITE_BYTE_
    MOV AL, DH
    CALL WRITE_BYTE_
    POP AX
    RET

; Procedure EMIT_STRING
; Inputs:
;   DS:SI the length-prefixed string to emit
EMIT_STRING:
    PUSH AX
    XOR AX, AX
    MOV AL, [SI]
    ADD [PC], AX
    CALL WRITE_STRING_
    POP AX
    RET

; Procedure EMIT_PREFIX
; Inputs:
;   AL the keyword of the prefix instruction to emit
EMIT_PREFIX:
    PUSH AX
    CMP AL, KW_LOCK
    JZ _epfx_lock_
    CMP AL, KW_REP
    JZ _epfx_repz_
    CMP AL, KW_REPE
    JZ _epfx_repz_
    CMP AL, KW_REPZ
    JZ _epfx_repz_
    CMP AL, KW_REPNE
    JZ _epfx_repnz_
    CMP AL, KW_REPNZ
    JZ _epfx_repnz_
    XOR AH, AH
    JMP ERROR_INVALID_PREFIX
_epfx_lock_:
    MOV AL, 11110000b
    JMP SHORT _epfx_emit_
_epfx_repz_:
    MOV AL, 11110011b
    JMP SHORT _epfx_emit_
_epfx_repnz_:
    MOV AL, 11110010b
_epfx_emit_:
    CALL EMIT_BYTE
    POP AX
    RET



; Procedure EMIT_INSTRUCTION
; Inputs:
;   AL the keyword of the instruction to emit
;   [ARG1] the first argument
;   [ARG2] the second argument
EMIT_INSTRUCTION:
    PUSH AX
    PUSH BX
    MOV BX, ARG1
    CALL EMIT_SEGMENT_OVERRIDE_
    JC _eins_emit_
    MOV BX, ARG2
    CALL EMIT_SEGMENT_OVERRIDE_

_eins_emit_:
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI
    XOR AH, AH
    MOV SI, AX
    SUB SI, KW_AAA
    ; Now SI has the index of the pointer to the instruction's definition
    ADD SI, SI
    MOV BP, WORD PTR [INSTR_TABLE + SI]
    ; Now BP has a pointer to the instruction's definition
    MOV SI, [BP]
    ADD BP, 2
    MOV AL, BYTE PTR [ARG1 + ARG_TYPE]
    MOV AH, BYTE PTR [ARG2 + ARG_TYPE]
    ; AL = arg1's type
    ; AH = arg2's type
    ; SI = address of the instruction emitter
    ; BP = address of arguments for the instruction emitter
    CALL SI
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

; Procedure EMIT_SEGMENT_OVERRIDE_
; Inputs:
;   BX pointer to the argument
; Outputs:
;   CF set if an override was emitted, unset otherwise
EMIT_SEGMENT_OVERRIDE_:
    PUSH AX
    PUSH CX
    CLC
    MOV AL, BYTE PTR [BX + ARG_TYPE]
    TEST AL, ARGT_PTR
    JZ _esegovr_ret_
    MOV AL, BYTE PTR [BX + ARG_EAMODE]
    TEST AL, EA_SEGMENT
    JZ _esegovr_ret_
    AND AL, EA_NOSEGMENT
    MOV BYTE PTR [BX + ARG_EAMODE], AL
    MOV AL, [BX + ARG_SEGMENT]
    AND AL, 3
    MOV CL, 3
    SHL AL, CL
    OR AL, 00100110b
    CALL EMIT_BYTE
    STC
_esegovr_ret_:
    POP CX
    POP AX
    RET

; Procedure WRITE_FLUSH
; Writes out the content of the buffer
WRITE_FLUSH:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSHF
    MOV BX, [OUTPUT]        ; Exit early on handler = 0
    CMP BX, 0
    JZ _wf_ret_
    MOV CX, [OUT_BUFPOS]    ; Exit early if the buffer is empty
    JCXZ _wf_ret_
    MOV AH, 40h
    MOV DX, OUT_BUFFER
    INT 21h                 ; Write the content of the buffer
    JC _wf_err_             ; Detect error
    CMP AX, CX              ; Detect partial write
    JB _wf_err_
    MOV [OUT_BUFPOS], 0     ; Reset the position in the buffer
_wf_ret_:
    POPF
    POP DX
    POP CX
    POP BX
    POP AX
    RET
_wf_err_:
    JMP ERROR_WRITE

; Procedure WRITE_BYTE_
; Writes a byte to the output
; Inputs:
;   AL the byte
WRITE_BYTE_:
    CMP [OUTPUT], 0         ; Skip writes on handler = 0
    JZ _wb_ret_
    CALL WRITE_FLUSH_COND_  ; Flush if necessary
    PUSHF
    PUSH BX
    MOV BX, [OUT_BUFPOS]    ; BX has the position
_wb_add_:
    MOV [OUT_BUFFER + BX], AL   ; Write the byte
    INC [OUT_BUFPOS]        ; Increment the position
    POP BX
    POPF
_wb_ret_:
    RET

; Procedure WRITE_BYTES_
; Writes a stream of bytes to the output
; Inputs:
;   AL the byte
;   CX the number of copies
WRITE_BYTES_:
    CMP [OUTPUT], 0         ; Skip writes on handler = 0
    JZ _wbs_ret_
    PUSHF
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES
    PUSH DS
    POP ES
    CLD
    MOV BX, CX              ; Remaining bytes in BX
_wbs_loop_:
    CMP BX, 0               ; None remaining? exit
    JE _wbs_break_
    CALL WRITE_FLUSH_COND_  ; Flush if necessary
    MOV DX, OUT_BUFSIZE
    SUB DX, [OUT_BUFPOS]    ; DX has the available space in the buffer
    MOV CX, BX              ; CX is the number of bytes to copy
    CMP DX, BX              ; If it's more than the available space...
    JAE _wbs_noclamp_
    MOV CX, DX              ; clamp to the available space
_wbs_noclamp_:
    MOV DI, OUT_BUFFER      ; Write to OUT_BUFFER + [OUT_BUFPOS]
    ADD DI, [OUT_BUFPOS]
    ADD [OUT_BUFPOS], CX    ; Change the position and remaining
    SUB BX, CX
    REP STOSB               ; Store the data
    JMP _wbs_loop_
_wbs_break_:
    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POPF
_wbs_ret_:
    RET

; Procedure WRITE_STRING_
; Writes a string to the output
; Inputs:
;   DS:SI the length-prefixed string
WRITE_STRING_:
    CMP [OUTPUT], 0         ; Skip writes on handler = 0
    JZ _ws_ret_
    PUSHF
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES
    PUSH DS
    POP ES
    CLD
    XOR BX, BX
    MOV BL, BYTE PTR [SI]   ; Remaining bytes in BX
    INC SI                  ; SI is the current source position
_ws_loop_:
    CMP BX, 0               ; No bytes remaining? exit
    JE _ws_break_
    CALL WRITE_FLUSH_COND_  ; Flush if necessary
    MOV DX, OUT_BUFSIZE
    SUB DX, [OUT_BUFPOS]    ; DX has the available space in the buffer
    MOV CX, BX              ; CX is the number of bytes to copy
    CMP DX, BX              ; If it's more than the available space...
    JAE _ws_noclamp_
    MOV CX, DX              ; clamp to the available space
_ws_noclamp_:
    MOV DI, OUT_BUFFER      ; Write to OUT_BUFFER + [OUT_BUFPOS]
    ADD DI, [OUT_BUFPOS]
    ADD [OUT_BUFPOS], CX    ; Change the position and remaining
    SUB BX, CX
    REP MOVSB               ; Copy the data
    JMP _ws_loop_
_ws_break_:
    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POPF
_ws_ret_:
    RET

; Procedure WRITE_FLUSH_COND_
; Writes out the content of the buffer if it's full.
WRITE_FLUSH_COND_:
    PUSHF
    CMP [OUT_BUFPOS], OUT_BUFSIZE   ; Are we at the end?
    JB _wfc_ret_
    CALL WRITE_FLUSH                ; No; flush
_wfc_ret_:
    POPF
    RET
