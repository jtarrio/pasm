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
    MOV BYTE PTR ES:[0 + MACRO_TYPE], MAC_NONE
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

    PUSH DS
    PUSH SI
    MOV ES, [MACROSEG]  ; Search in the macro segment
    CALL FIND_EQU_
    JC _se_add_         ; Add the macro if not found
    JMP ERROR_DUPLICATE_LABEL
_se_add_:
    POP SI
    POP DS
    MOV BYTE PTR ES:[DI + MACRO_TYPE], MAC_EQU   ; Set the macro type
    XOR CX, CX                  ; How many chars in the name?
    MOV CL, DS:[SI]
    INC CX
    ADD DI, MACRO_NAMELEN       ; Copy the name
    CLD
    REP MOVSB
    MOV BYTE PTR ES:[DI], TK_EOF        ; Add an EOF token marker
    MOV BYTE PTR ES:[DI + 1], MAC_NONE  ; Add a no-macro marker
    POPF
    POP ES
    POP SI
    POP DS
    POP CX
    POP AX
    RET

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
    MOV BYTE PTR ES:[DI + 1], MAC_NONE  ; Add a no-macro marker
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
;   DS:SI the position of the first token, if found
;   CF unset if found, set if not found
; Destroys:
;   Flags
GET_EQU_FIRST_TOKEN:
    PUSH AX
    PUSH CX
    PUSH ES
    PUSH DI

    MOV ES, [MACROSEG]  ; Search in the macro segment
    CALL FIND_EQU_
    JC _geft_notfound_
    PUSH ES             ; Copy ES:DI to DS:SI
    PUSH DI
    POP SI
    POP DS
_geft_notfound_:
    POP DI
    POP ES
    POP CX
    POP AX
    RET

; Procedure GET_EQU_NEXT_TOKEN
; Returns the address to the next token in the EQU
; Inputs:
;   DS:SI the current token
; Outputs:
;   DS:SI the next token, if found
;   CF unset if found, set if not found
; Destroys:
;   Flags
GET_EQU_NEXT_TOKEN:
    PUSH AX
    PUSH CX
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
    POP CX
    POP AX
    RET


; Procedure FIND_EQU_
; Finds the macro whose name is given in DS:SI
; Inputs:
;   DS:SI the position of the length-prefixed macro name
;   ES the macro segment [MACROSEG]
; Outputs:
;   ES:DI the position of the macro's first token, if found
;   CF unset if found, set if not found
; Destroys:
;   AX, CX, ES, DI flags
FIND_EQU_:
    XOR DI, DI          ; Start at the first position
    CLD
_fe_loop_:
    CMP BYTE PTR ES:[DI + MACRO_TYPE], MAC_NONE
    JZ _fe_notfound_
    XOR CX, CX
    MOV CL, ES:[DI + MACRO_NAMELEN]
    INC CX              ; CX has the length of the name and prefix
    INC DI              ; Pointing DI to the macro's name and prefix
    PUSH SI
    REPZ CMPSB          ; Compare
    JZ _fe_found_
    ADD DI, CX          ; Now we are pointing at the first token
    PUSH DS
    PUSH ES
    POP DS
    MOV SI, DI          ; Switch ES:DI and SI:DI so we can measure tokens
_fe_find_next_token_:
    CMP BYTE PTR DS:[SI], TK_EOF
    JZ _fe_found_last_token_
    CALL TOKEN_LENGTH
    ADD SI, CX
    JMP _fe_find_next_token_
_fe_found_last_token_:
    INC SI
    MOV DI, SI
    POP DS
    POP SI
    JMP _fe_loop_
_fe_found_:
    POP SI
    CLC
    RET
_fe_notfound_:
    STC
    RET

