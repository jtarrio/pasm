; Label definition
LABEL_TYPE          EQU 0   ; Byte
LABEL_ADDR          EQU 1   ; Word
LABEL_LINE          EQU 3   ; Word
LABEL_NAMELEN       EQU 5   ; Byte
LABEL_NAME          EQU 6   ; String
LABEL_NAMEMAXLEN    EQU TOKEN_IDMAXLEN
LABEL_MAXSIZE       EQU LABEL_NAME + LABEL_NAMEMAXLEN

; Label types
LBL_NONE        EQU 0   ; No label
LBL_ADDR        EQU 1   ; Address of any type
LBL_BYTEADDR    EQU 2   ; Byte address
LBL_WORDADDR    EQU 3   ; Word address
LBL_DWORDADDR   EQU 4   ; Dword address

LABELSEG    DW 0    ; The segment where the labels are saved
LABEL       DB LABEL_MAXSIZE DUP(0) ; The "current" label

; Procedure ADD_LABEL
; Adds the label from LABEL.
; Inputs:
;   DS, ES the program segment
;   [LABEL] the label to add
ADD_LABEL:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH DS
    PUSH ES
    MOV DS, [LABELSEG]  ; We start reading, with DS the label segment
    CALL FIND_LABEL_
    JNC _al_exists_     ; Found label? Error on pass 1
    PUSH DS             ; Now we switch from reading to writing
    POP ES              ; so set ES to the label segment
    PUSH CS
    POP DS              ; and DS to the code segment
    MOV DI, SI          ; Set the destination to the new slot
    MOV SI, LABEL       ; and the source to LABEL
    CALL COPY_LABEL_
    MOV BYTE PTR ES:[DI + LABEL_TYPE], LBL_NONE
                        ; Set the next non-label
_al_ret_:
    POP ES
    POP DS
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
_al_exists_:
    CMP BYTE PTR CS:[PASS], 2    ; Is this the second pass?
    JZ _al_exists_pass2_
    JMP ERROR_DUPLICATE_LABEL
_al_exists_pass2_:
    MOV AX, WORD PTR CS:[LABEL + LABEL_ADDR]
    MOV BX, WORD PTR DS:[SI + LABEL_ADDR]
    CMP AX, BX
    JZ _al_ret_
    JMP ERROR_LABEL_CHANGED_ADDR

; Procedure GET_LABEL
; Finds the label whose name is in LABEL and populates it.
; If the label is not found in pass 1, returns a placeholder.
GET_LABEL:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH DS
    PUSH ES
    MOV DS, [LABELSEG]  ; We start reading, with DS the label segment
    CALL FIND_LABEL_
    JC _gl_notfound_    ; Not found?
    MOV DI, LABEL       ; We will copy DS:SI (label) to ES:[LABEL]
    CALL COPY_LABEL_
_gl_ret_:
    POP ES
    POP DS
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
_gl_notfound_:
    CMP BYTE PTR CS:[PASS], 1    ; Is this the first pass?
    JZ _gl_notfound_pass1_
    JMP ERROR_LABEL_NOT_FOUND
_gl_notfound_pass1_:
    PUSH CS
    POP DS
    MOV BYTE PTR [LABEL + LABEL_TYPE], LBL_ADDR
    MOV AX, [PC]
    ADD AX, 260
    MOV WORD PTR [LABEL + LABEL_ADDR], AX
    MOV AX, [LINE]
    MOV WORD PTR [LABEL + LABEL_LINE], AX
    JMP _gl_ret_

; Procedure FIND_LABEL_
; Finds the label whose name is the one set in LABEL.
; Inputs:
;   DS the label segment ([LABELSEG])
;   ES the program segment
; Outputs:
;   DS:SI the position of the label, if found
;   CF unset if found, set if not found
; Destroys:
;   AX, CX, DI, flags
FIND_LABEL_:
    XOR SI, SI          ; Start at the first position
_fl_loop_:
    ; Have we reached the end?
    CMP BYTE PTR DS:[SI + LABEL_TYPE], LBL_NONE
    STC
    JZ _fl_ret_                         ; Yes; return

    MOV AX, SI      ; Save the label's position
    ADD SI, LABEL_NAMELEN
    XOR CX, CX
    MOV CL, DS:[SI] ; Starting at LABEL_NAMELEN...
    INC CX          ; compare LABEL_NAMELEN+1 bytes
    MOV DI, LABEL + LABEL_NAMELEN
    CLD
    REPE CMPSB
    JZ _fl_found_   ; Found! return

    ADD SI, CX      ; Add the remaining length to skip this label
    JMP _fl_loop_
_fl_found_:
    MOV SI, AX      ; Restore the label's position
    CLC
_fl_ret_:
    RET

; Procedure COPY_LABEL_
; Copies a label definition.
; Inputs:
;   DS:SI the source segment/address
;   ES:DI the destination segment/address
; Outputs:
;   DI the byte after the destination label
; Destroys:
;   SI, DI, CX, flags
COPY_LABEL_:
    XOR CX, CX
    MOV CL, DS:[SI + LABEL_NAMELEN]
    ADD CX, LABEL_NAME  ; Compute the label's length
    CLD
    REP MOVSB           ; Copy the label contents
    RET
