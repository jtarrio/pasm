; Macro definition
MACRO_TYPE          EQU 0   ; Byte
MACRO_NAMELEN       EQU 1   ; Byte
MACRO_NAME          EQU 2   ; String
MACRO_NAMEMAXLEN    EQU TOKEN_IDMAXLEN
MACRO_MAXLEN        EQU MACRO_NAME + MACRO_NAMEMAXLEN

; Macro types
MAC_NONE    EQU 0   ; No macro
MAC_EQU     EQU 1   ; EQU

MACROSEG    DW 0    ; The segment where macros are saved

; Procedure RESET_MACROS
; Marks the macros segment as empty.
RESET_MACROS:
    PUSH AX
    PUSH ES
    MOV AX, [MACROSEG]
    MOV ES, AX
    CALL HASH_PREPARE
    POP ES
    POP AX
    RET

; Procedure START_EQU
; Starts an empty EQU definition.
; Inputs:
;   DS:SI the position of the name of the EQU
; Outputs:
;   DI the position in MACROSEG where to write tokens
START_EQU:
    PUSH AX
    PUSH CX
    PUSH DS
    PUSH SI
    PUSH ES
    PUSHF
    MOV ES, [MACROSEG]      ; We operate on the label segment
    MOV DL, MACRO_NAMELEN
    CALL HASH_GET           ; Find the label
    JNC _se_exists_         ; Error if found
    CALL HASH_ADD
    MOV BYTE PTR ES:[DI + MACRO_TYPE], MAC_EQU   ; Set the macro type
    XOR CX, CX              ; How many chars in the name?
    MOV CL, DS:[SI]
    INC CX
    ADD DI, MACRO_NAMELEN   ; Copy the name
    CLD
    REP MOVSB
    MOV BYTE PTR ES:[DI], TK_EOF    ; Add an EOF token marker
    MOV WORD PTR ES:[DI + 1], 0     ; Set a null pointer past the token
    MOV AX, DI
    ADD AX, 3
    MOV ES:[0], AX          ; Update the free-memory pointer
    POPF
    POP ES
    POP SI
    POP DS
    POP CX
    POP AX
    RET
_se_exists_:
    JMP ERROR_DUPLICATE_LABEL

; Procedure ADD_TOKEN_TO_EQU
; Adds the current token to the current EQU
; Inputs:
;   [TOKEN] the current token
;   DI the position in MACROSEG where to add the token
; Outputs:
;   DI the new position after adding the token
ADD_TOKEN_TO_EQU:
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH ES
    PUSHF
    MOV ES, [MACROSEG]
    MOV SI, TOKEN
    CALL TOKEN_LENGTH
    CLD
    REP MOVSB                           ; Copy the token
    MOV BYTE PTR ES:[DI], TK_EOF        ; Append an EOF token marker
    MOV WORD PTR ES:[DI + 1], 0     ; Set a null pointer past the token
    MOV AX, DI
    ADD AX, 3
    MOV ES:[0], AX                      ; Update the free-memory pointer
    POPF
    POP ES
    POP SI
    POP CX
    POP AX
    RET

; Procedure GET_EQU_FIRST_TOKEN
; Finds the first token of the EQU with the given name
; Inputs:
;   DS:SI the position of the length-prefixed name
; Outputs:
;   SI the position of the first token in ES, if found
;   CF unset if found, set if not found
; Destroys:
;   Flags
GET_EQU_FIRST_TOKEN:
    PUSH AX
    PUSH CX
    PUSH ES
    PUSH DI

    MOV ES, [MACROSEG]      ; We operate on the label segment
    MOV DL, MACRO_NAMELEN
    CALL HASH_GET           ; Find the label
    JC _geft_notfound_
    XOR CX, CX
    MOV CL, ES:[DI + MACRO_NAMELEN]
    INC CX
    INC CX
    ADD DI, CX              ; Advance DI past the macro definition
    MOV SI, DI              ; Move ES:DI to DS:SI
_geft_notfound_:
    POP DI
    POP ES
    POP CX
    POP AX
    RET

; Procedure GET_EQU_NEXT_TOKEN
; Returns the address to the next token in the EQU
; Inputs:
;   SI the current token's position
; Outputs:
;   SI the next token's position, if found
;   CF unset if found, set if not found
; Destroys:
;   Flags
GET_EQU_NEXT_TOKEN:
    PUSH AX
    PUSH CX
    PUSH DS
    MOV DS, [MACROSEG]
    CMP BYTE PTR DS:[SI], TK_EOF    ; If EOF, return CF set
    STC
    JZ _gent_ret_
    CALL TOKEN_LENGTH
    ADD SI, CX                      ; Advance SI
    CMP BYTE PTR DS:[SI], TK_EOF    ; If EOF, return CF set
    STC
    JZ _gent_ret_
    CLC
_gent_ret_:
    POP DS
    POP CX
    POP AX
    RET

