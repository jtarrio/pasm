; Procedure PRINT_UINT16_DEC
; Prints out a 16-bit unsigned number in decimal
; Inputs:
;   AX the number to print
PRINT_UINT16_DEC:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    XOR CX, CX  ; Number of digits = 0
    MOV BX, 10  ; Base 10

_pui16d_div_:
    XOR DX, DX
    DIV BX      ; AX = DX:AX / BX ; DX = remainder
    PUSH DX     ; Push digit to stack
    INC CX
    OR AX, AX   ; If divisor is 0, done
    JNZ _pui16d_div_

    MOV AH, 02h ; Print char
_pui16d_out_:
    POP DX      ; Pop digit
    ADD DL, '0'
    INT 21h     ; Print digit
    LOOP _pui16d_out_

    POP DX
    POP CX
    POP BX
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
