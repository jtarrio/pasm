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
    MOV ES, [LABELSEG]  ; We operate on the label segment
    MOV SI, LABEL + LABEL_NAMELEN
    MOV DL, LABEL_NAMELEN
    CALL HASH_GET       ; Find the label, or next-element pointer
    JNC _al_exists_
    CALL HASH_ADD       ; Prepare the new hash element
    MOV SI, LABEL
    CALL COPY_LABEL_    ; and copy the label
    MOV ES:[0], DI      ; Update the next empty position
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
    MOV BX, WORD PTR ES:[DI + LABEL_ADDR]
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
    MOV ES, [LABELSEG]  ; We operate on the label segment
    MOV SI, LABEL + LABEL_NAMELEN
    MOV DL, LABEL_NAMELEN
    CALL HASH_GET       ; Find the label
    JC _gl_notfound_    ; Not found?
    MOV AX, ES
    MOV DS, AX
    MOV SI, DI          ; Move ES:DI to DS:SI
    MOV AX, CS
    MOV ES, AX
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
    CMP BYTE PTR [PASS], 1    ; Is this the first pass?
    JZ _gl_notfound_pass1_
    JMP ERROR_LABEL_NOT_FOUND
_gl_notfound_pass1_:
    MOV BYTE PTR [LABEL + LABEL_TYPE], LBL_ADDR
    MOV AX, [PC]
    ADD AX, 260
    MOV WORD PTR [LABEL + LABEL_ADDR], AX
    MOV AX, [LINE]
    MOV WORD PTR [LABEL + LABEL_LINE], AX
    JMP _gl_ret_

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
