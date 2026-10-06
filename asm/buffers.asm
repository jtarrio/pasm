; Buffers

INFILE  DB 80h DUP (?)  ; Input file name
OUTFILE DB 80h DUP (?)  ; Output file name

TOKEN   DB TOKEN_MAXSIZE DUP (?)    ; Current token
LABEL   DB LABEL_MAXSIZE DUP (?)    ; The "current" label

ARG1    DB ARG_MAXSIZE DUP (?)  ; First argument
ARG2    DB ARG_MAXSIZE DUP (?)  ; Second argument

LX_BUFFER   DB LX_BUFSIZE DUP (?)   ; Lexer's input buffer
OUT_BUFFER  DB OUT_BUFSIZE DUP (?)  ; Assembler's output buffer

