; Stubs

; Procedure EMIT_ORG
; Inputs:
;   AX the new program pointer
EMIT_ORG:

; Procedure EMIT_BYTE
; Inputs:
;   AL the byte to emit
EMIT_BYTE:

; Procedure EMIT_WORD
; Inputs:
;   AX the word to emit
EMIT_WORD:

; Procedure EMIT_DWORD
; Inputs:
;   DX:AX the dword to emit
EMIT_DWORD:

; Procedure EMIT_STRING
; Inputs:
;   SI the length-prefixed string to emit
EMIT_STRING:

; Procedure EMIT_PREFIX
; Inputs:
;   AL the keyword of the prefix instruction to emit
EMIT_PREFIX:

; Procedure EMIT_INSTRUCTION
; Inputs:
;   AL the keyword of the instruction to emit
;   [ARG1] the first argument
;   [ARG2] the second argument
EMIT_INSTRUCTION:

    RET
