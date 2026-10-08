ORG 100h

version EQU '0.3'

JMP MAIN

INCLUDE 'token.asm'
INCLUDE 'lexer.asm'
INCLUDE 'hashtabl.asm'
INCLUDE 'labels.asm'
INCLUDE 'macros.asm'
INCLUDE 'argument.asm'
INCLUDE 'assemble.asm'
INCLUDE 'instrs.asm'
INCLUDE 'emit.asm'
INCLUDE 'util.asm'

MAIN:
    MOV AH, 09h             ; Display the copyright notice
    MOV DX, COPYRIGHT
    INT 21h

    CALL RESERVE_MEMORY

    CALL PARSE_ARGS

    ; Open the input file
    MOV AX, 3D00h
    MOV DX, INFILE
    INT 21h
    JNC _main_start
    JMP ERROR_FILE_OPEN_READ

_main_start:
    CALL LEXER_START        ; Initialize the lexer
    CALL ASSEMBLE           ; First pass

    ; Open the output file
    MOV AH, 3Ch
    XOR CX, CX
    MOV DX, OUTFILE
    INT 21h
    JC _main_output_error
    MOV [OUTPUT], AX
    CALL ASSEMBLE           ; Second pass (writing to the output)

    CALL WRITE_FLUSH        ; Flush the output buffer

    MOV AH, 3Eh
    MOV BX, [LX_FILE_HANDLE]
    INT 21h                 ; Close both files
    MOV AH, 3Eh
    MOV BX, [OUTPUT]
    INT 21h

    MOV AX, 4C00h
    INT 21h                 ; Exit

_main_output_error:
    JMP ERROR_FILE_OPEN_WRITE

COPYRIGHT   DB 'PASM version ', version
            DB' Copyright 2026 Jacobo Tarrio.',13,10,'$'


; Procedure RESERVE_MEMORY
; Prepares the storage space for labels and macros
; Output:
;   [LABELSEG] the segment where the labels are stored
;   [MACROSEG] the segment where the macros are stored
RESERVE_MEMORY:
    PUSH AX
    PUSH BX
    PUSH ES
    PUSHF
    ; Check if there is enough memory
    MOV AX, [0002h]     ; Last segment allocated to the program
    MOV BX, CS
    SUB AX, BX          ; See how much memory has been allocated
    CMP AX, 3000h       ; We need at least 3 segments (1000h paras each)
    JAE _rm_ok_
    JMP ERROR_MEMORY
_rm_ok_:
    MOV AX, CS          ; Get the segment right after CS
    ADD AX, 1000h
    MOV [LABELSEG], AX  ; and store it in LABELSEG
    MOV ES, AX
    CALL HASH_PREPARE   ; Initialize the hash table
    ADD AX, 1000h       ; Next segment
    MOV [MACROSEG], AX  ; store it in MACROSEG
    CALL RESET_MACROS
    POPF
    POP ES
    POP BX
    POP AX
    RET

; Procedure PARSE_ARGS
; Parses the command line
; Output:
;   [INFILE] the ASCIIZ input file
;   [OUTFILE] the ASCIIZ output file
PARSE_ARGS:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    CLD
    MOV SI, 80h     ; Point SI at the command line
    XOR CX, CX
    MOV CL, [SI]    ; Load the length in CX
    INC SI
    MOV DI, INFILE
    CALL COPY_ARG_  ; Parse the first arg into INFILE
    JC _pa_unspec_  ; Not found? Error
    MOV DI, OUTFILE
    CALL COPY_ARG_  ; Parse the second arg into OUTFILE
    JNC _pa_accept_ ; Found? Done
    ; Otherwise, make the output file name from the input file name
    MOV SI, INFILE
    MOV DI, OUTFILE
    XOR BX, BX      ; BX will have the position of the last dot
_pa_copy_:
    LODSB
    CMP AL, '.'
    JNZ _pa_nodot_
    MOV BX, DI
_pa_nodot_:
    CMP AL, '\'
    JNZ _pa_noslash_
    XOR BX, BX
_pa_noslash_:
    STOSB
    CMP AL, 0
    JNZ _pa_copy_
    CMP BX, 0       ; No dot?
    JNZ _pa_setext_
    MOV BX, DI      ; If so, pretend the dot is after the end
    DEC BX
_pa_setext_:
    MOV CX, 5       ; Overwrite with '.COM'
    MOV SI, _pa_dotcom_
    MOV DI, BX
    REP MOVSB
_pa_accept_:
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
_pa_unspec_:
    JMP ERROR_NO_SOURCE
_pa_dotcom_ DB '.COM',0



; Procedure COPY_ARG
; Copies the next argument from SI to DI
; Inputs:
;   CX the maximum length of the argument
;   SI the address of the input argument (with possible leading whitespace)
;   DI the address where to write it
; Outputs:
;   CX the remaining length
;   SI the position after the argument
;   DI the address where the output argument was written (as ASCIIZ)
;   CF set if there was no input argument, unset otherwise
COPY_ARG_:
    PUSH AX
    PUSH DI
_ca_skipws_:
    JCXZ _ca_none_          ; Exit immediately if there are no chars left
    LODSB                   ; Load the next character
    DEC CX
    CMP AL, ' '             ; Space?
    JZ _ca_skipws_          ; Yes, loop again
    CMP AL, 9               ; Tab?
    JZ _ca_skipws_          ; Yes, loop again
    CMP AL, 13              ; CR?
    JZ _ca_none_            ; Yes, exit
    CMP AL, 0               ; NUL?
    JZ _ca_none_            ; Yes, exit
    JMP SHORT _ca_copy_

_ca_copy_:
    STOSB                   ; Store the char
    JCXZ _ca_done_          ; Exit if we ran out of characters
    LODSB                   ; Load the next character
    DEC CX
    CMP AL, ' '             ; Space?
    JZ _ca_done_            ; Yes, exit loop
    CMP AL, 9               ; Tab?
    JZ _ca_done_            ; Yes, exit loop
    CMP AL, 13              ; CR?
    JZ _ca_done_            ; Yes, exit loop
    CMP AL, 0               ; NUL?
    JZ _ca_done_            ; Yes, exit loop
    JMP _ca_copy_

_ca_none_:
    STC                     ; If we reached the end, there is no argument
    JMP SHORT _ca_ret_
_ca_done_:
    XOR AL, AL
    STOSB                   ; Save a 0 at the end
    CLC
_ca_ret_:
    POP DI
    POP AX
    RET

INCLUDE 'errors.asm'

; Buffers

INFILE  DB 80h DUP (?)  ; Input file name
OUTFILE DB 80h DUP (?)  ; Output file name

LXIC_START:             ; Start of the include context
LX_FILE_HANDLE  DW ?            ; File handle for the lexer
FILENAME_LEN    DB ?
FILENAME        DB 256 DUP (?)  ; Current file's name
LINE            DW ?            ; Current line number
LXC_START:                  ; Start of the zeroable lexer context
LX_C            DB ?            ; Last read character (uppercase)
LX_RAWC         DB ?            ; Last read character (raw)
LX_EOF          DB ?            ; Reached end of file
LXIC_END:               ; End of the include context
LX_EOL          DB ?            ; Reached end of line
LX_BUFLEN       DW ?            ; Length of the read buffer
LX_BUFPOS       DW ?            ; Position in the read buffer
LX_EQUTOKEN     DW ?            ; Current token in EQU expansion
LXC_END:                    ; End of the zeroable lexer context
INCLUDE_TOP     DW ?            ; The top of the include stack

TOKEN   DB TOKEN_MAXSIZE DUP (?)    ; Current token
LABEL   DB LABEL_MAXSIZE DUP (?)    ; The "current" label

ARG1    DB ARG_MAXSIZE DUP (?)  ; First argument
ARG2    DB ARG_MAXSIZE DUP (?)  ; Second argument

LX_BUFFER   DB LX_BUFSIZE DUP (?)   ; Lexer's input buffer
OUT_BUFFER  DB OUT_BUFSIZE DUP (?)  ; Assembler's output buffer

INCLUDE_STACK:          ; The include stack starts here
