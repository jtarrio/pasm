LX_FILE_HANDLE  DW -1           ; File handle for the lexer
LXC_START:                      ; Start of the lexer context
LINE            DW 0            ; Current line number
LX_C            DB -1           ; Last read character (uppercase)
LX_RAWC         DB -1           ; Last read character (raw)
LX_EOF          DB 0            ; Reached end of file
LX_EOL          DB 0            ; Reached end of line
LX_BUFSIZE      EQU 1024        ; Size of the read buffer
LX_BUFLEN       DW 0            ; Length of the read buffer
LX_BUFPOS       DW 0            ; Position in the read buffer
LX_EQUTOKEN     DW 0            ; Current token in EQU expansion
LXC_END:                        ; End of the lexer context

; Procedure LEXER_START.
; Initializes the lexer context.
; Input:
;   AX the file handle
LEXER_START:
    MOV [LX_FILE_HANDLE], AX
    JMP LEXER_RESTART

; Procedure LEXER_RESTART.
; Reinitializes the lexer context.
; Destroys:
;   AX, BX, CX, DX, DI, ES, flags
LEXER_RESTART:
    ; Seek from start
    MOV AX, 4200h
    MOV BX, [LX_FILE_HANDLE]
    XOR CX, CX
    XOR DX, DX
    INT 21h
    JC _lr_error_seek_

    ; Zero the lexer context
    PUSH DS
    POP ES
    MOV DI, LXC_START
    MOV CX, LXC_END - LXC_START
    CLD
    XOR AX, AX
    REP STOSB
    MOV [LINE], 1

    CALL LEXER_READNEXT_
    CALL LEXER_SKIPWHITESPACE_
    MOV [LX_EOL], 0
    RET
_lr_error_seek_:
    JMP ERROR_SEEK


; Procedure LEXER_NEXT
; Reads the next token from EQU or the input
; Outputs:
;   [TOKEN] the next token
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
LEXER_NEXT:
    MOV SI, [LX_EQUTOKEN]
    CMP SI, 0               ; Is there an EQU token?
    JNZ _ln_equ_            ; Yes, jump
_ln_from_input_:
    CMP [LX_EOF], 0         ; EOF?
    JNZ _ln_eof_            ; Yes, jump
    CALL LEXER_SKIPWHITESPACE_
    CMP [LX_EOL], 0         ; End of line?
    JNZ _ln_eol_            ; yes, jump
    MOV AX, [LINE]          ; no; set the current position
    MOV WORD PTR [TOKEN + TOKEN_LINE], AX
    MOV WORD PTR [TOKEN + TOKEN_NUMBER], 0
    JMP LEXER_READTOKEN_   ; read the next token
_ln_eol_:
    MOV BYTE PTR [TOKEN + TOKEN_TYPE], TK_EOL
    RET
_ln_eof_:
    MOV AX, [LINE]          ; set the current position
    MOV WORD PTR [TOKEN + TOKEN_LINE], AX
    MOV AL, [TOKEN + TOKEN_TYPE]
    CMP AL, TK_EOL          ; Output EOF if the previous
    JZ _ln_reteof_             ; token was EOL or EOF;
    CMP AL, TK_EOF          ; EOL otherwise
    JZ _ln_reteof_
    MOV BYTE PTR [TOKEN + TOKEN_TYPE], TK_EOL
    RET
_ln_reteof_:
    MOV BYTE PTR [TOKEN + TOKEN_TYPE], TK_EOF
    RET
_ln_equ_:
    PUSH DS                 ; We are expanding an EQU
    PUSH ES
    PUSH DS
    POP ES
    MOV DI, TOKEN           ; Set ES:DI to the address of TOKEN
    MOV DS, [MACROSEG]      ; Set DS:SI to the EQU token's address
    CMP BYTE PTR DS:[SI + TOKEN_TYPE], TK_EOF
    JZ _ln_endequ_          ; If EOF token, stop reading EQU tokens
    CALL TOKEN_LENGTH
    CLD
    REP MOVSB               ; Copy the EQUTOKEN to TOKEN
    CMP BYTE PTR DS:[SI], TK_EOF
    JNZ _ln_moreequ_        ; If EOF, clear the next token's position
    XOR SI, SI
_ln_moreequ_:
    POP ES
    POP DS
    MOV [LX_EQUTOKEN], SI   ; And now save the next token's position
    RET
_ln_endequ_:
    MOV WORD PTR ES:[LX_EQUTOKEN], 0    ; Blank the EQU token address
    POP ES
    POP DS
    JMP _ln_from_input_     ; continue reading from the input

; Procedure LEXER_READTOKEN_
; Reads the next token from the input
; Outputs:
;   [TOKEN] the next token
; Destroys:
;   AX, BX, CX, DX, flags.
LEXER_READTOKEN_:
    MOV BX, _lrt_table_
    MOV AL, [LX_C]
    XLAT                ; Find the character in the token table
    OR AL, AL           ; Invalid character!
    JZ _lrt_invalid_char_
    CMP AL, TK_IDENTIFIER   ; Special function for identifiers
    JZ _lrt_id_
    CMP AL, TK_NUMBER   ; Special function for numbers
    JZ _lrt_num_
    CMP AL, TK_STRING   ; Special function for strings
    JZ _lrt_str_
    MOV [TOKEN + TOKEN_TYPE], AL    ; Set type and get next character
    JMP LEXER_READNEXT_
_lrt_str_:
    JMP LEXER_READSTRING_
_lrt_num_:
    JMP LEXER_READNUMBER_
_lrt_id_:
    JMP LEXER_READIDENTIFIER_
_lrt_invalid_char_:
    JMP ERROR_INVALID_CHAR

; The token type that each character starts
_lrt_table_ DB 39 DUP (0)
            DB TK_STRING, TK_LPAREN, TK_RPAREN, 0
            DB TK_PLUS, TK_COMMA, TK_MINUS, 0, 0
            DB 10 DUP (TK_NUMBER), TK_COLON, 4 DUP(0), TK_QUESTION, 0
            DB 26 DUP (TK_IDENTIFIER)
            DB TK_LBRACKET, 0, TK_RBRACKET, 0, TK_IDENTIFIER, 0
            DB 26 DUP (TK_IDENTIFIER), 133 DUP(0)

; Procedure LEXER_READSTRING_
; Reads a string token.
; Outputs:
;   [TOKEN] the token
; Destroys:
;   AX, BX, CX, DX, DI, flags
LEXER_READSTRING_:
    MOV BYTE PTR [TOKEN + TOKEN_TYPE], TK_STRING
    MOV DI, TOKEN + TOKEN_STR
    CLD
_lrs_next_:
    CALL LEXER_READNEXT_    ; Get the next character
    CMP [LX_EOF], 0         ; If EOF, error
    JNZ _lrs_eof_
    MOV AL, [LX_RAWC]
    CMP AL, 39              ; If ', end of string
    JZ _lrs_done_
    CMP AL, 13              ; If CR or LF, error
    JZ _lrs_eol_
    CMP AL, 10  ; LF
    JZ _lrs_eol_
    CMP DI, TOKEN + TOKEN_STR + TOKEN_STRMAXLEN
    JAE _lrs_toolong_       ; Gone past the end of the string
    STOSB                   ; Save the current character
    JMP _lrs_next_
_lrs_done_:
    MOV AX, DI
    SUB AX, TOKEN + TOKEN_STR       ; Compute the length
    MOV [TOKEN + TOKEN_STRLEN], AL  ; Save the length
    JMP LEXER_READNEXT_             ; Read the next character and return
_lrs_eof_:
    JMP ERROR_UNEXPECTED_EOF
_lrs_eol_:
    JMP ERROR_UNEXPECTED_EOL
_lrs_toolong_:
    JMP ERROR_STRING_TOO_LONG

; Procedure LEXER_READNUMBER_
; Reads a number token.
; Outputs:
;   [TOKEN] the token
; Destroys:
;   AX, BX, CX, DX, DI, flags
LEXER_READNUMBER_:
    MOV AL, [LX_C]
_lrnum_skipzeros_:      ; Skip leading zeros
    CMP AL, '0'     ; If nonzero, start reading digits
    JNZ _lrnum_start_digits_
    CALL LEXER_READNEXT_
    JMP _lrnum_skipzeros_

; Byte-to-digit conversions
_lrnum_digit_table_ DB 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 7 DUP (-1), 10, 11, 12, 13, 14, 15, -1, 'H', 6 DUP (-1), 'O'

_lrnum_start_digits_:
    XOR DI, DI          ; DI contains the number of digits
_lrnum_digit_:
    SUB AL, '0'
    JB _lrnum_done_
    CMP AL, 31
    JA _lrnum_done_
    MOV BX, _lrnum_digit_table_
    XLAT
    CMP AL, -1
    JE _lrnum_done_
_lrnum_maxdigits_ EQU 17
    CMP DI, _lrnum_maxdigits_
    JZ _lrnum_toolarge_
    MOV [_lrnum_digits_ + DI], AL   ; Store the digit
    INC DI

    CMP AL, 'H'         ; If H or O, done
    JZ _lrnum_suffix_done_
    CMP AL, 'O'
    JZ _lrnum_suffix_done_
    CALL LEXER_READNEXT_
    JMP _lrnum_digit_
_lrnum_toolarge_:
    JMP ERROR_NUMBER_TOO_LARGE

_lrnum_suffix_done_:
    CALL LEXER_READNEXT_
_lrnum_done_:
    MOV BYTE PTR [TOKEN + TOKEN_TYPE], TK_NUMBER
    OR DI, DI           ; If zero digits, return zero
    JZ _lrnum_ret_

    DEC DI
    MOV AL, [_lrnum_digits_ + DI]
    MOV BP, 10
    CMP AL, 10          ; If the number ends with a decimal digit, base 10
    JB _lrnum_decimal_
    MOV BP, 2
    CMP AL, 11          ; If the number ends with 'B', base 2
    JZ _lrnum_decode_
    MOV BP, 8
    CMP AL, 'O'         ; If 'O', base 8
    JZ _lrnum_decode_
    MOV BP, 16
    CMP AL, 'H'         ; If 'H', base 16
    JZ _lrnum_decode_
    MOV BP, 10
    CMP AL, 13          ; If 'D', base 10
    JZ _lrnum_decode_
_lrnum_decimal_:
    INC DI              ; Otherwise, the last digit *is* a digit
_lrnum_decode_:
    OR DI, DI           ; If no digits, return
    JZ _lrnum_ret_
    MOV CX, DI
    MOV SI, _lrnum_digits_
    XOR BX, BX          ; BX contains the decoded number
    CLD
_lrnum_decode_loop_:
    MOV AX, BX
    MUL BP              ; Multiply by the base
    OR DX, DX
    JNZ _lrnum_toolarge_    ; If >0FFFFh, error
    MOV BX, AX
    LODSB
    XOR AH, AH
    CMP AX, BP          ; If the result is >= base, error
    JAE _lrnum_invalid_
    XOR AH, AH
    ADD BX, AX          ; Add the digit to BX
    JC _lrnum_toolarge_ ; if overflow, error
    LOOP _lrnum_decode_loop_

    MOV WORD PTR [TOKEN + TOKEN_NUMBER], BX
_lrnum_ret_:
    RET
_lrnum_invalid_:
    JMP ERROR_INVALID_DIGIT
_lrnum_digits_    DB _lrnum_maxdigits_ DUP(?)
_lrnum_maxvalue_  EQU 0FFFFh

; Procedure LEXER_READIDENTIFIER_
; Reads and resolves an identifier token.
; Outputs:
;   [TOKEN] the token
; Destroys:
;   AX, BX, CX, DX, SI, DI, flags
LEXER_READIDENTIFIER_:
    MOV DI, TOKEN + TOKEN_ID
    CLD
    MOV AL, [LX_C]
_lri_letter_:
    CMP AL, 'A'         ; A to Z?
    JB _lri_check_digit_
    CMP AL, 'Z'
    JA _lri_check_underscore_
_lri_append_:
    CMP DI, TOKEN + TOKEN_ID + TOKEN_IDMAXLEN
    JAE _lri_toolong_       ; Identifier too long
    STOSB                   ; Save the current character
    CALL LEXER_READNEXT_    ; Process the next character
    JMP _lri_letter_
_lri_check_underscore_:
    CMP AL, '_'         ; Underscore?
    JZ _lri_append_
    JMP SHORT _lri_done_
_lri_check_digit_:
    CMP AL, '0'         ; 0 to 9?
    JB _lri_done_
    CMP AL, '9'
    JBE _lri_append_

_lri_done_:
    MOV SI, TOKEN + TOKEN_IDLEN     ; Point SI to length prefix

    MOV AX, DI
    SUB AX, TOKEN + TOKEN_ID        ; Compute the length
    MOV [SI], AL                    ; and save it

    CMP AL, 6                       ; Identifiers longer than 6
    JA _lri_maybe_equ_              ; can only be EQU or identifiers
    CMP AL, 2                       ; Also shorter than 2
    JB _lri_maybe_equ_
    JA _lri_maybe_keyword_          ; Between 3 and 6, maybe keywords
    CALL GET_REGISTER               ; Is this a register?
    MOV AH, TK_REGISTER
    JNC _lri_set_type_
    CALL GET_SEGMENT                ; Is this a segment?
    MOV AH, TK_SEGMENT
    JNC _lri_set_type_
_lri_maybe_keyword_:
    CALL GET_KEYWORD                ; Is this a keyword?
    MOV AH, TK_KEYWORD
    JNC _lri_set_type_
_lri_maybe_equ_:
    CALL GET_EQU_FIRST_TOKEN        ; Is this an EQU?
    JC _lri_no_equ_
    MOV [LX_EQUTOKEN], SI           ; Yes; set the first EQU token
    JMP LEXER_NEXT                  ; and go back to LEXER_NEXT
_lri_no_equ_:
                                    ; It is a regular identifier
    MOV BYTE PTR [TOKEN + TOKEN_TYPE], TK_IDENTIFIER
    RET
_lri_set_type_:
    MOV [TOKEN + TOKEN_TYPE], AH
    MOV [TOKEN + TOKEN_VALUE], AL
    RET

_lri_toolong_:
    JMP ERROR_IDENTIFIER_TOO_LONG

; Procedure LEXER_READNEXT_
; Reads the next character from the input.
; Outputs:
;   [LX_RAWC] the raw character
;   [LX_C] the uppercase character
;   [LX_EOF] 1 on EOF, 0 otherwise
;   AL the uppercase character if not EOF
; Destroys:
;   AH, BX, CX, DX, flags.
LEXER_READNEXT_:
    CMP [LX_EOF], 0         ; Exit if EOF
    JNZ _lrn_ret_
    CMP [LX_C], 0Ah         ; If LF, increment LINE and reset COL
    JZ _lrn_eol_
_lrn_read_:
    MOV BX, [LX_BUFPOS]     ; Buffer position in BX
    CMP BX, [LX_BUFLEN]     ; If same as length, we need to read a new buffer
    JZ _lrn_readbuffer_
_lrn_getbyte_:
    MOV AL, [LX_BUFFER+BX]  ; Get the next character
    MOV [LX_RAWC], AL       ; Store the next character in LX_RAWC
    INC BX
    MOV [LX_BUFPOS], BX     ; And update LX_BUFPOS
    CMP AL, 'a'
    JB _lrn_setc_
    CMP AL, 'z'
    JA _lrn_setc_
    SUB AL, 32              ; Character is lowercase, so make it uppercase
_lrn_setc_:
    MOV [LX_C], AL
_lrn_ret_:
    RET
_lrn_eol_:
    INC [LINE]
    JMP SHORT _lrn_read_
_lrn_readbuffer_:
    MOV AH, 3Fh             ; Read from file
    MOV BX, [LX_FILE_HANDLE]
    MOV CX, LX_BUFSIZE
    MOV DX, LX_BUFFER
    INT 21h
    JC _lrn_error_read_
    XOR BX, BX              ; Store the length of the read buffer
    MOV [LX_BUFLEN], AX
    MOV [LX_BUFPOS], BX
    OR AX, AX               ; If length is zero, we have EOF
    JNZ _lrn_getbyte_
    MOV [LX_RAWC], AL       ; Clear LX_RAWC and LX_C, set LX_EOF to 1, then return
    MOV [LX_C], AL
    INC AL
    MOV [LX_EOF], AL
    RET
_lrn_error_read_:
    JMP ERROR_READ


; Procedure LEXER_SKIPWHITESPACE_
; Skips over whitespace characters.
; Outputs:
;   [LX_EOL] on end-of-line
;   Outputs from LEXER_READNEXT_
; Destroys:
;   AX, BX, CX, DX, SI, flags
LEXER_SKIPWHITESPACE_:
    XOR SI, SI          ; We'll use SI to carry EOL and is_comment
    MOV [LX_EOL], 0
    MOV AL, [LX_C]
_lsws_start_:
    CMP [LX_EOF], 0     ; On EOF we first return an EOL
    JNZ _lsws_ret_with_eol_
    TEST SI, 2          ; Are we in a comment?
    JNZ _lsws_in_comment_
    CMP AL, ' '         ; Space?
    JA _lsws_character_ ; Above space, so check for semicolon
    JZ _lsws_next_      ; It is a space, so skip

    CMP AL, 10          ; Is newline?
    JZ _lsws_newline_   ; yes, do end of line stuff
    CMP AL, 9           ; Skip tab
    JZ _lsws_next_
    CMP AL, 13          ; Skip carriage return
    JZ _lsws_next_
    JMP SHORT _lsws_other_
_lsws_in_comment_:
    CMP AL, 10          ; Newline?
    JZ _lsws_newline_   ; do end of line stuff
_lsws_next_:
    CALL LEXER_READNEXT_    ; next character
    JMP _lsws_start_
_lsws_character_:
    CMP AL, ';'         ; Is semicolon?
    JZ _lsws_comment_   ; yes, mark as comment
_lsws_other_:
    TEST SI, 1
    JNZ _lsws_ret_with_eol_
    RET
_lsws_ret_with_eol_:
    MOV [LX_EOL], 1
    RET
_lsws_newline_:
    TEST SI, 1          ; Are we in EOL already?
    JNZ _lsws_alreadyeol_
    MOV AX, [LINE]      ; Set the token's position before we signal EOL
    MOV WORD PTR [TOKEN + TOKEN_LINE], AX
_lsws_alreadyeol_:
    MOV SI, 1           ; Mark SI as EOL, remove is_comment
    JMP SHORT _lsws_next_
_lsws_comment_:
    OR SI, 2            ; Mark SI as is_comment
    JMP SHORT _lsws_next_
