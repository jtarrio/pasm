; Procedure PRINT_UINT16_DEC
; Prints out a 16-bit unsigned number in decimal
; Inputs:
;   AX the number to print
PRINT_UINT16_DEC:
    PUSH BX
    MOV BX, 10
    CALL PRINT_UINT16
    POP BX
    RET

; Procedure PRINT_UINT16
; Prints out a 16-bit unsigned number in any base
; Inputs:
;   AX the number to print
;   BX the base
PRINT_UINT16:
    PUSH AX
    PUSH CX
    PUSH DX

    XOR CX, CX  ; Number of digits = 0
_pui16_div_:
    XOR DX, DX
    DIV BX      ; AX = DX:AX / BX ; DX = remainder
    PUSH DX     ; Push digit to stack
    INC CX
    OR AX, AX   ; If divisor is 0, done
    JNZ _pui16_div_

_pui16_out_:
    POP DX      ; Pop digit
    CMP DL, 9
    JBE _pui16_lo_
    ADD DL, 7
_pui16_lo_:
    ADD DL, '0'
    MOV AH, 02h ; Print char
    INT 21h     ; Print digit
    LOOP _pui16_out_

    POP DX
    POP CX
    POP AX
    RET

; Procedure PRINT_STR
; Prints out a length-prefixed string
; Inputs:
;   DI length-prefixed string to print
PRINT_STR:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    XOR CX, CX
    MOV CL, [DI]
    JCXZ _ps_ret_
    MOV DX, DI
    MOV AH, 40h
    MOV BX, 1
    INC DX
    INT 21h
_ps_ret_:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
