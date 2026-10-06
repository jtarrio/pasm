; Token definition
TOKEN_TYPE      EQU 0 ; Byte
TOKEN_LINE      EQU 1 ; Word
TOKEN_VALUE     EQU 3 ; Byte
TOKEN_REGISTER  EQU 3 ; Byte
TOKEN_SEGMENT   EQU 3 ; Byte
TOKEN_KEYWORD   EQU 3 ; Byte
TOKEN_NUMBER    EQU 3 ; Word
TOKEN_STRLEN    EQU 3 ; Byte
TOKEN_STR       EQU 4 ; Byte string
TOKEN_STRMAXLEN EQU 255
TOKEN_IDLEN     EQU 3 ; Byte
TOKEN_ID        EQU 4 ; Byte string
TOKEN_IDMAXLEN  EQU 64
TOKEN_MAXSIZE   EQU TOKEN_STR + TOKEN_STRMAXLEN

; Token types
TK_EOF	        EQU 0
TK_EOL	        EQU 1
TK_LBRACKET	    EQU 2
TK_RBRACKET	    EQU 3
TK_LPAREN	    EQU 4
TK_RPAREN	    EQU 5
TK_PLUS	        EQU 6
TK_MINUS	    EQU 7
TK_COMMA	    EQU 8
TK_COLON	    EQU 9
TK_QUESTION     EQU 10
TK_REGISTER	    EQU 11
TK_SEGMENT	    EQU 12
TK_KEYWORD	    EQU 13
TK_NUMBER	    EQU 14
TK_IDENTIFIER	EQU 15
TK_STRING	    EQU 16

; Registers
REG_AX  EQU 0
REG_CX  EQU 1
REG_DX  EQU 2
REG_BX  EQU 3
REG_SP  EQU 4
REG_BP  EQU 5
REG_SI  EQU 6
REG_DI  EQU 7
REG_AL  EQU 8
REG_CL  EQU 9
REG_DL  EQU 10
REG_BL  EQU 11
REG_AH  EQU 12
REG_CH  EQU 13
REG_DH  EQU 14
REG_BH  EQU 15

; Procedure GET_REGISTER
; Returns the index of the identifier as a register.
; Inputs:
;   DS:SI the symbol (length-prefixed)
; Returns:
;   AX the index, if found
;   CF set if not found, unset otherwise
; Destroys:
;   BX, flags
GET_REGISTER:
    MOV AL, [SI]
    CMP AL, 2
    JNZ _greg_none_
    MOV AX, [SI + 1]
    MOV BL, REG_AX
    CMP AH, 'X'
    JZ _greg_g_
    MOV BL, REG_AL
    CMP AH, 'L'
    JZ _greg_g_
    CMP AH, 'I'
    JZ _greg_i_
    MOV BL, REG_AH
    CMP AH, 'H'
    JZ _greg_g_
    CMP AH, 'P'
    JNZ _greg_none_
    MOV BL, REG_BP
    CMP AL, 'B'
    JZ _greg_ret_
    MOV BL, REG_SP
    CMP AL, 'S'
    JZ _greg_ret_
    JMP SHORT _greg_none_
_greg_i_:
    MOV BL, REG_SI
    CMP AL, 'S'
    JZ _greg_ret_
    MOV BL, REG_DI
    CMP AL, 'D'
    JZ _greg_ret_
    JMP SHORT _greg_none_
_greg_g_:
    MOV BH, REG_AX
    CMP AL, 'A'
    JZ _greg_gret_
    MOV BH, REG_BX
    CMP AL, 'B'
    JZ _greg_gret_
    MOV BH, REG_CX
    CMP AL, 'C'
    JZ _greg_gret_
    MOV BH, REG_DX
    CMP AL, 'D'
    JZ _greg_gret_
_greg_none_:
    STC
    RET
_greg_gret_:
    ADD BL, BH
_greg_ret_:
    XOR AH, AH
    MOV AL, BL
    RET

; Segments
SEG_ES  EQU 0
SEG_CS  EQU 1
SEG_SS  EQU 2
SEG_DS  EQU 3

; Procedure GET_SEGMENT
; Returns the index of the identifier as a segment.
; Inputs:
;   DS:SI the symbol (length-prefixed)
; Returns:
;   AX the index, if found
;   CF set if not found, unset otherwise
; Destroys:
;   BX, flags
GET_SEGMENT:
    MOV BL, [SI]
    CMP BL, 2
    JNZ _gseg_none_
    MOV BX, [SI + 1]
    CMP BH, 'S'
    JNZ _gseg_none_
    XOR AH, AH
    MOV AL, SEG_ES
    CMP BL, 'E'
    JZ _gseg_ret_
    MOV AL, SEG_DS
    CMP BL, 'D'
    JZ _gseg_ret_
    MOV AL, SEG_CS
    CMP BL, 'C'
    JZ _gseg_ret_
    MOV AL, SEG_SS
    CMP BL, 'S'
    JZ _gseg_ret_
_gseg_none_:
    STC
_gseg_ret_:
    RET

; Directives
KW_DUP		EQU 0
KW_EQU		EQU 1
KW_ORG		EQU 2
; Size and distance
KW_BYTE		EQU 3
KW_DWORD	EQU 4
KW_FAR		EQU 5
KW_NEAR		EQU 6
KW_PTR		EQU 7
KW_SHORT	EQU 8
KW_WORD		EQU 9
; Data
KW_DB		EQU 10
KW_DD		EQU 11
KW_DW		EQU 12
; Prefixes
KW_LOCK		EQU 13
KW_REP		EQU 14
KW_REPE		EQU 15
KW_REPNE	EQU 16
KW_REPNZ	EQU 17
KW_REPZ		EQU 18
; Instructions
KW_AAA		EQU 19
KW_AAD		EQU 20
KW_AAM		EQU 21
KW_AAS		EQU 22
KW_ADC		EQU 23
KW_ADD		EQU 24
KW_AND		EQU 25
KW_CALL		EQU 26
KW_CBW		EQU 27
KW_CLC		EQU 28
KW_CLD		EQU 29
KW_CLI		EQU 30
KW_CMC		EQU 31
KW_CMP		EQU 32
KW_CMPSB	EQU 33
KW_CMPSW	EQU 34
KW_CWD		EQU 35
KW_DAA		EQU 36
KW_DAS		EQU 37
KW_DEC		EQU 38
KW_DIV		EQU 39
KW_ESC		EQU 40
KW_HLT		EQU 41
KW_IDIV		EQU 42
KW_IMUL		EQU 43
KW_IN		EQU 44
KW_INC		EQU 45
KW_INT		EQU 46
KW_INTO		EQU 47
KW_IRET		EQU 48
KW_JA		EQU 49
KW_JAE		EQU 50
KW_JB		EQU 51
KW_JBE		EQU 52
KW_JC		EQU 53
KW_JCXZ		EQU 54
KW_JE		EQU 55
KW_JG		EQU 56
KW_JGE		EQU 57
KW_JL		EQU 58
KW_JLE		EQU 59
KW_JMP		EQU 60
KW_JNA		EQU 61
KW_JNAE		EQU 62
KW_JNB		EQU 63
KW_JNBE		EQU 64
KW_JNC		EQU 65
KW_JNE		EQU 66
KW_JNG		EQU 67
KW_JNGE		EQU 68
KW_JNL		EQU 69
KW_JNLE		EQU 70
KW_JNO		EQU 71
KW_JNP		EQU 72
KW_JNS		EQU 73
KW_JNZ		EQU 74
KW_JO		EQU 75
KW_JP		EQU 76
KW_JPE		EQU 77
KW_JPO		EQU 78
KW_JS		EQU 79
KW_JZ		EQU 80
KW_LAHF		EQU 81
KW_LDS		EQU 82
KW_LEA		EQU 83
KW_LES		EQU 84
KW_LODSB	EQU 85
KW_LODSW	EQU 86
KW_LOOP		EQU 87
KW_LOOPE	EQU 88
KW_LOOPNE	EQU 89
KW_LOOPNZ	EQU 90
KW_LOOPZ	EQU 91
KW_MOV		EQU 92
KW_MOVSB	EQU 93
KW_MOVSW	EQU 94
KW_MUL		EQU 95
KW_NEG		EQU 96
KW_NOP		EQU 97
KW_NOT		EQU 98
KW_OR		EQU 99
KW_OUT		EQU 100
KW_POP		EQU 101
KW_POPF		EQU 102
KW_PUSH		EQU 103
KW_PUSHF	EQU 104
KW_RCL		EQU 105
KW_RCR		EQU 106
KW_RET		EQU 107
KW_RETF		EQU 108
KW_RETN		EQU 109
KW_ROL		EQU 110
KW_ROR		EQU 111
KW_SAHF		EQU 112
KW_SAL		EQU 113
KW_SAR		EQU 114
KW_SBB		EQU 115
KW_SCASB	EQU 116
KW_SCASW	EQU 117
KW_SHL		EQU 118
KW_SHR		EQU 119
KW_STC		EQU 120
KW_STD		EQU 121
KW_STI		EQU 122
KW_STOSB	EQU 123
KW_STOSW	EQU 124
KW_SUB		EQU 125
KW_TEST		EQU 126
KW_WAIT		EQU 127
KW_XCHG		EQU 128
KW_XLAT	    EQU 129
KW_XOR		EQU 130

KEYWORDS    DB 3, 'DUP', 3, 'EQU', 3, 'ORG'
            DB 4, 'BYTE', 5, 'DWORD', 3, 'FAR', 4, 'NEAR', 3, 'PTR', 5, 'SHORT', 4, 'WORD'
            DB 2, 'DB', 2, 'DD', 2, 'DW'
            DB 4, 'LOCK', 3, 'REP', 4, 'REPE', 5, 'REPNE', 5, 'REPNZ', 4, 'REPZ'
            DB 3, 'AAA', 3, 'AAD', 3, 'AAM', 3, 'AAS', 3, 'ADC', 3, 'ADD', 3, 'AND'
            DB 4, 'CALL', 3, 'CBW', 3, 'CLC', 3, 'CLD', 3, 'CLI', 3, 'CMC', 3, 'CMP', 5, 'CMPSB', 5, 'CMPSW', 3, 'CWD', 3, 'DAA', 3, 'DAS', 3, 'DEC', 3, 'DIV'
            DB 3, 'ESC'
            DB 3, 'HLT'
            DB 4, 'IDIV', 4, 'IMUL', 2, 'IN', 3, 'INC', 3, 'INT', 4, 'INTO', 4, 'IRET'
            DB 2, 'JA', 3, 'JAE', 2, 'JB', 3, 'JBE', 2, 'JC', 4, 'JCXZ', 2, 'JE', 2, 'JG', 3, 'JGE', 2, 'JL', 3, 'JLE', 3, 'JMP', 3, 'JNA', 4, 'JNAE', 3, 'JNB', 4, 'JNBE', 3, 'JNC', 3, 'JNE', 3, 'JNG', 4, 'JNGE', 3, 'JNL', 4, 'JNLE', 3, 'JNO', 3, 'JNP', 3, 'JNS', 3, 'JNZ', 2, 'JO', 2, 'JP', 3, 'JPE', 3, 'JPO', 2, 'JS', 2, 'JZ'
            DB 4, 'LAHF', 3, 'LDS', 3, 'LEA', 3, 'LES', 5, 'LODSB', 5, 'LODSW', 4, 'LOOP', 5, 'LOOPE', 6, 'LOOPNE', 6, 'LOOPNZ', 5, 'LOOPZ'
            DB 3, 'MOV', 5, 'MOVSB', 5, 'MOVSW', 3, 'MUL'
            DB 3, 'NEG', 3, 'NOP', 3, 'NOT'
            DB 2, 'OR', 3, 'OUT'
            DB 3, 'POP', 4, 'POPF', 4, 'PUSH', 5, 'PUSHF'
            DB 3, 'RCL', 3, 'RCR', 3, 'RET', 4, 'RETF', 4, 'RETN', 3, 'ROL', 3, 'ROR'
            DB 4, 'SAHF', 3, 'SAL', 3, 'SAR', 3, 'SBB', 5, 'SCASB', 5, 'SCASW', 3, 'SHL', 3, 'SHR', 3, 'STC', 3, 'STD', 3, 'STI', 5, 'STOSB', 5, 'STOSW', 3, 'SUB'
            DB 4, 'TEST'
            DB 4, 'WAIT'
            DB 4, 'XCHG', 4, 'XLAT', 3, 'XOR', 0

; Procedure GET_KEYWORD
; Returns the index of the identifier as a keyword.
; Inputs:
;   DS:SI the symbol (length-prefixed)
; Returns:
;   AX the index, if found
;   CF set if not found, unset otherwise
; Destroys:
;   BX, CX, DX, DI, flags
GET_KEYWORD:
    XOR AX, AX  ; Zero the index
    MOV BX, [SI]    ; Length and first character of the symbol
    MOV DX, SI  ; Save the symbol's original position
    MOV DI, KEYWORDS
    CLD
_gk_start_:
    MOV CX, [DI]    ; Load the next symbol's length and first character
    OR CL, CL       ; If the length is zero, we've reached the end of the table
    JZ _gk_not_found_
    INC DI
    CMP CX, BX      ; Does it match the length and first character?
    MOV CH, 0
    JZ _gk_check_rest_
_gk_next_:
    ADD DI, CX      ; Advance to the next symbol in the table
    INC AX          ; Increment the index
    JMP _gk_start_
_gk_check_rest_:
    DEC CX          ; We have compared the first char
    INC DI
    INC SI
    INC SI
    REPE CMPSB      ; Compare until different or CX=0
    MOV SI, DX      ; Restore the symbol's position
    JZ _gk_found_
    JMP SHORT _gk_next_
_gk_not_found_:
    STC
_gk_found_:
    RET

; Procedure TOKEN_LENGTH
; Returns the length of a token
; Inputs:
;   DS:SI the token's location
; Outputs:
;   CX the token's length
; Destroys:
;   AX, flags
TOKEN_LENGTH:
    MOV CX, TOKEN_VALUE - TOKEN_TYPE
    MOV AL, [SI + TOKEN_TYPE]
    CMP AL, TK_REGISTER
    JB _tl_havesize_
    INC CX
    CMP AL, TK_NUMBER
    JB _tl_havesize_
    INC CX
    CMP AL, TK_IDENTIFIER
    JB _tl_havesize_
    MOV CL, [SI + TOKEN_STRLEN]
    ADD CX, TOKEN_STR
_tl_havesize_:
    RET
