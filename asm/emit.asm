OUTPUT      DW 0        ; Assembler output handle
PC          DW 0        ; Program counter
OC          DW 0        ; Output counter (position of the next write)
OUT_BUFSIZE EQU 1024    ; Size of the output buffer
OUT_BUFPOS  DW 0        ; Position in the output buffer

; Procedure EMIT_ORG
; Inputs:
;   AX the new program pointer
EMIT_ORG:
    CMP [PC], 0     ; If PC is not zero, just set it
    JZ _eorg_zero_
_eorg_set_:
    MOV [PC], AX
    RET
_eorg_zero_:
    CMP [OC], 0     ; If PC and OC are zero, set OC and PC
    JNZ _eorg_set_
    MOV [OC], AX
    JMP _eorg_set_

; Procedure EMIT_ALIGN
; Inputs:
;   AX the alignment (positive power of 2)
EMIT_ALIGN:
    PUSH AX
    PUSH BX
    PUSH CX
    CMP AX, 1               ; Less than 1?
    JL _ealign_invalid_     ; Yes, invalid
    MOV BX, AX
    DEC BX
    MOV CX, BX
    AND CX, AX              ; AX & (AX - 1) == 0?
    JNZ _ealign_invalid_    ; Yes, invalid
    AND BX, [PC]            ; BX = [PC] mod BX
    JZ _ealign_ret_         ; If zero, we are aligned
    SUB AX, BX
    ADD [PC], AX            ; Add the necessary padding
_ealign_ret_:
    POP CX
    POP BX
    POP AX
    RET
_ealign_invalid_:
    JMP ERROR_INVALID_ARG

; Procedure EMIT_UNDEF
; Emits undefined bytes
; Inputs:
;   CX the nubmer of undefined bytes to emit
EMIT_UNDEF:
    ADD [PC], CX
    RET

; Procedure EMIT_BYTE
; Inputs:
;   AL the byte to emit
EMIT_BYTE:
    CALL ADJUST_OC_
EMIT_BYTE_:
    INC [PC]
    INC [OC]
    CMP [OUTPUT], 0         ; Skip writes on handler = 0
    JZ _eb_ret_
    PUSH BX
    MOV BX, [OUT_BUFPOS]
    CMP BX, OUT_BUFSIZE   ; Are we at the end?
    JAE _eb_flush_          ; Yes, flush
_eb_add_:
    MOV [OUT_BUFFER + BX], AL   ; Write the byte
    INC BX
    MOV [OUT_BUFPOS], BX        ; Increment the position
    POP BX
_eb_ret_:
    RET
_eb_flush_:
    CALL WRITE_FLUSH
    XOR BX, BX
    JMP _eb_add_

; Procedure EMIT_WORD
; Inputs:
;   AX the word to emit
EMIT_WORD:
    CALL ADJUST_OC_
EMIT_WORD_:
    ADD [PC], 2
    ADD [OC], 2
    CMP [OUTPUT], 0         ; Skip writes on handler = 0
    JZ _ew_ret_
    PUSH BX
    MOV BX, [OUT_BUFPOS]    ; BX has the position
    CMP BX, OUT_BUFSIZE - 1   ; Are we at the end?
    JAE _ew_flush_          ; Yes, flush
_ew_add_:
    MOV WORD PTR [OUT_BUFFER + BX], AX   ; Write the word
    INC BX                  ; Increment the position
    INC BX
    MOV [OUT_BUFPOS], BX
    POP BX
_ew_ret_:
    RET
_ew_flush_:
    CALL WRITE_FLUSH
    XOR BX, BX
    JMP _ew_add_

; Procedure EMIT_DWORD
; Inputs:
;   DX:AX the dword to emit
EMIT_DWORD:
    CALL ADJUST_OC_
EMIT_DWORD_:
    ADD [PC], 4
    ADD [OC], 4
    CMP [OUTPUT], 0         ; Skip writes on handler = 0
    JZ _edw_ret_
    PUSH BX
    MOV BX, [OUT_BUFPOS]    ; BX has the position
    CMP BX, OUT_BUFSIZE - 3   ; Are we at the end?
    JAE _edw_flush_          ; Yes, flush
_edw_add_:
    MOV WORD PTR [OUT_BUFFER + BX], AX       ; Write the dword
    MOV WORD PTR [OUT_BUFFER + BX + 2], DX
    ADD BX, 4               ; Increment the position
    MOV [OUT_BUFPOS], BX
    POP BX
_edw_ret_:
    RET
_edw_flush_:
    CALL WRITE_FLUSH
    XOR BX, BX
    JMP _edw_add_

; Procedure EMIT_STRING
; Inputs:
;   DS:SI the length-prefixed string to emit
EMIT_STRING:
    CALL ADJUST_OC_
EMIT_STRING_:
    PUSH BX
    XOR BX, BX
    MOV BL, BYTE PTR [SI]   ; Remaining bytes in BX
    CMP BX, 0               ; No bytes remaining? exit
    JE _es_ret_
    ADD [PC], BX
    ADD [OC], BX
    CMP [OUTPUT], 0         ; Skip writes on handler = 0
    JZ _es_ret_
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES
    PUSH DS
    POP ES
    CLD
    INC SI                  ; SI is the current source position
_es_loop_:
    MOV DX, OUT_BUFSIZE
    SUB DX, [OUT_BUFPOS]    ; DX has the available space in the buffer
    JBE _es_flush_          ; If no available space, flush
_es_do_:
    MOV CX, BX              ; CX is the number of bytes to copy
    CMP DX, BX              ; If it's more than the available space...
    JAE _es_noclamp_
    MOV CX, DX              ; clamp to the available space
_es_noclamp_:
    MOV DI, OUT_BUFFER      ; Write to OUT_BUFFER + [OUT_BUFPOS]
    ADD DI, [OUT_BUFPOS]
    ADD [OUT_BUFPOS], CX    ; Change the position and remaining
    SUB BX, CX
    REP MOVSB               ; Copy the data
    JNZ _es_loop_
_es_break_:
    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
_es_ret_:
    POP BX
    RET
_es_flush_:
    CALL WRITE_FLUSH
    MOV DX, OUT_BUFSIZE
    JMP _es_do_

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
    CALL ADJUST_OC_
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
    TEST BYTE PTR [BX + ARG_TYPE], ARGT_PTR
    JZ _esegovr_ret_
    TEST BYTE PTR [BX + ARG_EAMODE], EA_SEGMENT
    JZ _esegovr_ret_
    PUSH AX
    AND BYTE PTR [BX + ARG_EAMODE], EA_NOSEGMENT
    MOV AL, [BX + ARG_SEGMENT]
    AND AL, 3
    SHL AL, 1
    SHL AL, 1
    SHL AL, 1
    OR AL, 00100110b
    CALL EMIT_BYTE_
    POP AX
    STC
    RET
_esegovr_ret_:
    CLC
    RET

; Procedure ADJUST_OC_
; Advances OC up to PC, padding with zeros if necessary.
ADJUST_OC_:
    PUSH CX
    MOV CX, [PC]
    SUB CX, [OC]
    JNZ _adjoc_adjust_
    POP CX
    RET
_adjoc_adjust_:
    JB _adjoc_rewind_
    ADD [OC], CX
    CMP [OUTPUT], 0         ; Skip writes on handler = 0
    JZ _adjoc_ret_
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH DI
    PUSH ES
    PUSH DS
    POP ES
    CLD
    MOV AL, 90h             ; We'll pad with 90h (NOP)
    MOV BX, CX              ; Remaining bytes in BX
_adjoc_loop_:
    MOV DX, OUT_BUFSIZE
    SUB DX, [OUT_BUFPOS]    ; DX has the available space in the buffer
    JBE _adjoc_flush_         ; If zero (or less?!?!) flush
_adjoc_do_:
    MOV CX, BX              ; CX is the number of bytes to copy
    CMP DX, BX              ; If it's more than the available space...
    JAE _adjoc_noclamp_
    MOV CX, DX
_adjoc_noclamp_:
    MOV DI, OUT_BUFFER
    ADD DI, [OUT_BUFPOS]    ; Write to OUT_BUFFER + [OUT_BUFPOS]
    ADD [OUT_BUFPOS], CX    ; Change the position and remaining
    SUB BX, CX
    REP STOSB               ; Store the data
    JNZ _adjoc_loop_          ; Loop more if BX is not 0 (from the SUB)
_adjoc_break_:
    POP ES
    POP DI
    POP DX
    POP BX
    POP AX
_adjoc_ret_:
    POP CX
    RET
_adjoc_flush_:
    CALL WRITE_FLUSH
    MOV DX, OUT_BUFSIZE     ; Now all of OUT_BUFSIZE remains in the buffer
    JMP _adjoc_do_
_adjoc_rewind_:
    JMP ERROR_REWIND

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


