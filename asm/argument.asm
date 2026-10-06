; Argument definition
ARG_TYPE        EQU 0   ; Byte
ARG_BYTE        EQU 1   ; Word (used for num|byte)
ARG_WORD        EQU 1   ; Word (used for num)
ARG_DWORD       EQU 1   ; Dword (used for num|dword)
ARG_OFFSET      EQU 1   ; Word (used for ptr)
ARG_REGISTER    EQU 1   ; Byte (used for reg)
ARG_SEGMENT     EQU 3   ; Byte (used for seg and ptr)
ARG_EAMODE      EQU 4   ; Byte (used for ptr)
ARG_DISTANCE    EQU 5   ; Byte (used for word, dword, and ptr)
ARG_STRLEN      EQU 1   ; Byte (used for str)
ARG_STR         EQU 2   ; String (used for str)
ARG_STRMAXLEN   EQU 255
ARG_MAXSIZE     EQU ARG_STR + ARG_STRMAXLEN

; Argument types
ARGT_NONE   EQU 00000000b   ; No argument
ARGT_NUM    EQU 00000001b   ; Number (byte, word, dword)
ARGT_UNDEF  EQU 00000110b   ; Undefined value
ARGT_REG    EQU 00000010b   ; Register
ARGT_SEG    EQU 00000100b   ; Segment
ARGT_PTR    EQU 00001000b   ; Pointer
ARGT_STR    EQU 00010000b   ; String
ARGT_MASK   EQU 00011111b
; Argument sizes
ARGS_BYTE   EQU 00100000b   ; Byte
ARGS_WORD   EQU 01000000b   ; Word
ARGS_DWORD  EQU 10000000b   ; Dword
ARGS_MASK   EQU 11100000b

; Argument types (for high byte)
ARGTH_NONE  EQU 0000000000000000b   ; No argument
ARGTH_NUM   EQU 0000000100000000b   ; Number (byte, word, dword)
ARGTH_STR   EQU 0000001000000000b   ; String
ARGTH_REG   EQU 0000010000000000b   ; Register
ARGTH_SEG   EQU 0000100000000000b   ; Segment
ARGTH_PTR   EQU 0001000000000000b   ; Pointer
ARGTH_MASK  EQU 0001111100000000b
; Argument sizes
ARGSH_BYTE  EQU 0010000000000000b   ; Byte
ARGSH_WORD  EQU 0100000000000000b   ; Word
ARGSH_DWORD EQU 1000000000000000b   ; Dword
ARGSH_MASK  EQU 1110000000000000b

; Registers
AREG_AX  EQU 0
AREG_CX  EQU 1
AREG_DX  EQU 2
AREG_BX  EQU 3
AREG_SP  EQU 4
AREG_BP  EQU 5
AREG_SI  EQU 6
AREG_DI  EQU 7
AREG_AL  EQU 0
AREG_CL  EQU 1
AREG_DL  EQU 2
AREG_BL  EQU 3
AREG_AH  EQU 4
AREG_CH  EQU 5
AREG_DH  EQU 6
AREG_BH  EQU 7

; Segments
ASEG_ES  EQU 0
ASEG_CS  EQU 1
ASEG_SS  EQU 2
ASEG_DS  EQU 3

; Effective Address modes
EA_BXSI     EQU 0
EA_BXDI     EQU 1
EA_BPSI     EQU 2
EA_BPDI     EQU 3
EA_SI       EQU 4
EA_DI       EQU 5
EA_BP       EQU 6
EA_DIRECT   EQU 6
EA_BX       EQU 7
EA_OFFSET   EQU 08h
EA_OFFSET16 EQU 10h
EA_SEGMENT  EQU 20h
EA_NOSEGMENT    EQU 11011111b

; Distances
DST_SHORT   EQU 1
DST_NEAR    EQU 2
DST_FAR     EQU 3
