; Indirect pointers to each instruction's definition
INSTR_TABLE DW _etbl_aaa_, _etbl_aad_, _etbl_aam_, _etbl_aas_
            DW _etbl_adc_, _etbl_add_, _etbl_and_, _etbl_call_
            DW _etbl_cbw_, _etbl_clc_, _etbl_cld_, _etbl_cli_
            DW _etbl_cmc_, _etbl_cmp_, _etbl_cmpsb_, _etbl_cmpsw_
            DW _etbl_cwd_, _etbl_daa_, _etbl_das_, _etbl_dec_
            DW _etbl_div_, _etbl_esc_, _etbl_hlt_, _etbl_idiv_
            DW _etbl_imul_, _etbl_in_, _etbl_inc_, _etbl_int_
            DW _etbl_into_, _etbl_iret_, _etbl_ja_, _etbl_jae_
            DW _etbl_jb_, _etbl_jbe_, _etbl_jc_, _etbl_jcxz_
            DW _etbl_je_, _etbl_jg_, _etbl_jge_, _etbl_jl_
            DW _etbl_jle_, _etbl_jmp_, _etbl_jna_, _etbl_jnae_
            DW _etbl_jnb_, _etbl_jnbe_, _etbl_jnc_, _etbl_jne_
            DW _etbl_jng_, _etbl_jnge_, _etbl_jnl_, _etbl_jnle_
            DW _etbl_jno_, _etbl_jnp_, _etbl_jns_, _etbl_jnz_
            DW _etbl_jo_, _etbl_jp_, _etbl_jpe_, _etbl_jpo_
            DW _etbl_js_, _etbl_jz_, _etbl_lahf_, _etbl_lds_
            DW _etbl_lea_, _etbl_les_, _etbl_lodsb_, _etbl_lodsw_
            DW _etbl_loop_, _etbl_loope_, _etbl_loopne_, _etbl_loopnz_
            DW _etbl_loopz_, _etbl_mov_, _etbl_movsb_, _etbl_movsw_
            DW _etbl_mul_, _etbl_neg_, _etbl_nop_, _etbl_not_
            DW _etbl_or_, _etbl_out_, _etbl_pop_, _etbl_popf_
            DW _etbl_push_, _etbl_pushf_, _etbl_rcl_, _etbl_rcr_
            DW _etbl_ret_, _etbl_retf_, _etbl_retn_, _etbl_rol_
            DW _etbl_ror_, _etbl_sahf_, _etbl_sal_, _etbl_sar_
            DW _etbl_sbb_, _etbl_scasb_, _etbl_scasw_, _etbl_shl_
            DW _etbl_shr_, _etbl_stc_, _etbl_std_, _etbl_sti_
            DW _etbl_stosb_, _etbl_stosw_, _etbl_sub_, _etbl_test_
            DW _etbl_wait_, _etbl_xchg_, _etbl_xlat_, _etbl_xor_

_etbl_aaa_      DW i_noargs_
                DB 00110111b
_etbl_aad_      DW i_aamaad_
                DB 11010101b
_etbl_aam_      DW i_aamaad_
                DB 11010100b
_etbl_aas_      DW i_noargs_
                DB 00111111b
_etbl_adc_      DW i_arith_
                DB 00010100b, 00010000b, 10000000b, 010b, 1, 0
_etbl_add_      DW i_arith_
                DB 00000100b, 00000000b, 10000000b, 000b, 1, 0
_etbl_and_      DW i_arith_
                DB 00100100b, 00100000b, 10000000b, 100b, 0, 0
_etbl_call_     DW i_jmpcall_
                DB 0fh, 11101000b, 10011010b, 11111111b, 010b, 011b
_etbl_cbw_      DW i_noargs_
                DB 10011000b
_etbl_clc_      DW i_noargs_
                DB 11111000b
_etbl_cld_      DW i_noargs_
                DB 11111100b
_etbl_cli_      DW i_noargs_
                DB 11111010b
_etbl_cmc_      DW i_noargs_
                DB 11110101b
_etbl_cmp_      DW i_arith_
                DB 00111100b, 00111000b, 10000000b, 111b, 1, 0
_etbl_cmpsb_    DW i_noargs_
                DB 10100110b
_etbl_cmpsw_    DW i_noargs_
                DB 10100111b
_etbl_cwd_      DW i_noargs_
                DB 10011001b
_etbl_daa_      DW i_noargs_
                DB 00100111b
_etbl_das_      DW i_noargs_
                DB 00101111b
_etbl_dec_      DW i_unary_
                DB 01001000b, 11111110b, 001b
_etbl_div_      DW i_unary_
                DB 0Fh, 11110110b, 110b
_etbl_esc_      DW i_esc_
_etbl_hlt_      DW i_noargs_
                DB 11110100b
_etbl_idiv_     DW i_unary_
                DB 0Fh, 11110110b, 111b
_etbl_imul_     DW i_unary_
                DB 0Fh, 11110110b, 101b
_etbl_in_       DW i_inout_
                DB 11100100b, 11101100b, 0
_etbl_inc_      DW i_unary_
                DB 01000000b, 11111110b, 000b
_etbl_int_      DW i_interrupt_
                DB 11001100b, 11001101b
_etbl_into_     DW i_noargs_
                DB 11001110b
_etbl_iret_     DW i_noargs_
                DB 11001111b
_etbl_ja_       DW i_jmpshort_
                DB 01110111b
_etbl_jae_      DW i_jmpshort_
                DB 01110011b
_etbl_jb_       DW i_jmpshort_
                DB 01110010b
_etbl_jbe_      DW i_jmpshort_
                DB 01110110b
_etbl_jc_       DW i_jmpshort_
                DB 01110010b
_etbl_jcxz_     DW i_jmpshort_
                DB 11100011b
_etbl_je_       DW i_jmpshort_
                DB 01110100b
_etbl_jg_       DW i_jmpshort_
                DB 01111111b
_etbl_jge_      DW i_jmpshort_
                DB 01111101b
_etbl_jl_       DW i_jmpshort_
                DB 01111100b
_etbl_jle_      DW i_jmpshort_
                DB 01111110b
_etbl_jmp_      DW i_jmpcall_
                DB 11101011b, 11101001b, 11101010b, 11111111b, 100b, 101b
_etbl_jna_      DW i_jmpshort_
                DB 01110110b
_etbl_jnae_     DW i_jmpshort_
                DB 01110010b
_etbl_jnb_      DW i_jmpshort_
                DB 01110011b
_etbl_jnbe_     DW i_jmpshort_
                DB 01110111b
_etbl_jnc_      DW i_jmpshort_
                DB 01110011b
_etbl_jne_      DW i_jmpshort_
                DB 01110101b
_etbl_jng_      DW i_jmpshort_
                DB 01111110b
_etbl_jnge_     DW i_jmpshort_
                DB 01111100b
_etbl_jnl_      DW i_jmpshort_
                DB 01111101b
_etbl_jnle_     DW i_jmpshort_
                DB 01111111b
_etbl_jno_      DW i_jmpshort_
                DB 01110001b
_etbl_jnp_      DW i_jmpshort_
                DB 01111011b
_etbl_jns_      DW i_jmpshort_
                DB 01111001b
_etbl_jnz_      DW i_jmpshort_
                DB 01110101b
_etbl_jo_       DW i_jmpshort_
                DB 01110000b
_etbl_jp_       DW i_jmpshort_
                DB 01111010b
_etbl_jpe_      DW i_jmpshort_
                DB 01111010b
_etbl_jpo_      DW i_jmpshort_
                DB 01111011b
_etbl_js_       DW i_jmpshort_
                DB 01111000b
_etbl_jz_       DW i_jmpshort_
                DB 01110100b
_etbl_lahf_     DW i_noargs_
                DB 10011111b
_etbl_lds_      DW i_loadaddr_
                DB 11000101b
_etbl_lea_      DW i_loadaddr_
                DB 10001101b
_etbl_les_      DW i_loadaddr_
                DB 11000100b
_etbl_lodsb_    DW i_noargs_
                DB 10101100b
_etbl_lodsw_    DW i_noargs_
                DB 10101101b
_etbl_loop_     DW i_jmpshort_
                DB 11100010b
_etbl_loope_    DW i_jmpshort_
                DB 11100001b
_etbl_loopne_   DW i_jmpshort_
                DB 11100000b
_etbl_loopnz_   DW i_jmpshort_
                DB 11100000b
_etbl_loopz_    DW i_jmpshort_
                DB 11100001b
_etbl_mov_      DW i_mov_
                DB 10100000b, 10110000b, 10001000b, 11000110b, 000b, 10001100b
_etbl_movsb_    DW i_noargs_
                DB 10100100b
_etbl_movsw_    DW i_noargs_
                DB 10100101b
_etbl_mul_      DW i_unary_
                DB 0Fh, 11110110b, 100b
_etbl_neg_      DW i_unary_
                DB 0Fh, 11110110b, 011b
_etbl_nop_      DW i_noargs_
                DB 10010000b
_etbl_not_      DW i_unary_
                DB 0Fh, 11110110b, 010b
_etbl_or_       DW i_arith_
                DB 00001100b, 00001000b, 10000000b, 001b, 0, 0
_etbl_out_      DW i_inout_
                DB 11100110b, 11101110b, 1
_etbl_pop_      DW i_stack_
                DB 01011000b, 10001111b, 000b, 00000111b
_etbl_popf_     DW i_noargs_
                DB 10011101b
_etbl_push_     DW i_stack_
                DB 01010000b, 11111111b, 110b, 00000110b
_etbl_pushf_    DW i_noargs_
                DB 10011100b
_etbl_rcl_      DW i_rotate_
                DB 11010000b, 010b
_etbl_rcr_      DW i_rotate_
                DB 11010000b, 011b
_etbl_ret_      DW i_ret_
                DB 11000011b, 11000010b
_etbl_retf_     DW i_ret_
                DB 11001011b, 11001010b
_etbl_retn_     DW i_ret_
                DB 11000011b, 11000010b
_etbl_rol_      DW i_rotate_
                DB 11010000b, 000b
_etbl_ror_      DW i_rotate_
                DB 11010000b, 001b
_etbl_sahf_     DW i_noargs_
                DB 10011110b
_etbl_sal_      DW i_rotate_
                DB 11010000b, 100b
_etbl_sar_      DW i_rotate_
                DB 11010000b, 111b
_etbl_sbb_      DW i_arith_
                DB 00011100b, 00011000b, 10000000b, 011b, 1, 0
_etbl_scasb_    DW i_noargs_
                DB 10101110b
_etbl_scasw_    DW i_noargs_
                DB 10101111b
_etbl_shl_      DW i_rotate_
                DB 11010000b, 100b
_etbl_shr_      DW i_rotate_
                DB 11010000b, 101b
_etbl_stc_      DW i_noargs_
                DB 11111001b
_etbl_std_      DW i_noargs_
                DB 11111101b
_etbl_sti_      DW i_noargs_
                DB 11111011b
_etbl_stosb_    DW i_noargs_
                DB 10101010b
_etbl_stosw_    DW i_noargs_
                DB 10101011b
_etbl_sub_      DW i_arith_
                DB 00101100b, 00101000b, 10000000b, 101b, 1, 0
_etbl_test_     DW i_arith_
                DB 10101000b, 10000100b, 11110110b, 000b, 0, 1
_etbl_wait_     DW i_noargs_
                DB 10011011b
_etbl_xchg_     DW i_xchg_
                DB 10010000b, 10000110b
_etbl_xlat_     DW i_noargs_
                DB 11010111b
_etbl_xor_      DW i_arith_
                DB 00110100b, 00110000b, 10000000b, 110b, 0, 0

; Accumulator register (AL and AX have the same value)
AREG_ACC EQU AREG_AX
; An invalid opcode sentinel
INVALID_OP  EQU 0Fh

; Instruction pattern for a no-args single-byte instruction
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_noargs_:
    CMP AL, ARGT_NONE
    JNZ _i_noargs_err_
    MOV AL, BYTE PTR [BP]
    JMP EMIT_BYTE_
_i_noargs_err_:
    JMP ERROR_UNEXPECTED_ARGUMENT

; Instruction pattern for a 2-byte instruction with an optional argument
; whose value is 10 by default (AAD/AAM)
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_aamaad_:
    MOV BL, BYTE PTR [BP]
    MOV BH, 10
    CMP AL, ARGT_NONE
    JZ _i_aamaad_emit_
    CMP AH, ARGT_NONE
    JZ _i_aamaad_1arg_
    JMP ERROR_EXPECTED_1_ARGUMENT
_i_aamaad_1arg_:
    CMP AL, ARGT_NUM + ARGS_BYTE
    JNZ _i_aamaad_err_
    MOV BH, BYTE PTR [ARG1 + ARG_BYTE]
_i_aamaad_emit_:
    MOV AX, BX
    JMP EMIT_WORD_
_i_aamaad_err_:
    JMP ERROR_INVALID_ARG

; Instruction pattern for an arithmetic or logical instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_arith_:
    CMP AH, ARGT_NONE
    JZ _i_arith_badargs_
    CALL EQUATE_SIZES_
    ; acc <- imm ?
    TEST AH, ARGT_NUM               ; arg2 num?
    JZ _i_arith_regsrc_             ; no, try arg2 reg
    TEST AL, ARGT_REG               ; arg1 reg?
    JZ _i_arith_numsrc_             ; no, try arg2 num (no acc)
    CMP BYTE PTR [ARG1 + ARG_REGISTER], AREG_ACC    ; arg1 acc?
    JNZ _i_arith_numsrc_            ; no, try arg2 num (no acc)
    MOV BL, BYTE PTR [BP]
    JMP IP_OP_A2VALUE_
_i_arith_numsrc_:
    ; (reg|ptr) <- imm ?
    ; we already know arg2 is num
    TEST AL, ARGT_REG + ARGT_PTR    ; arg1 reg|ptr?
    JZ _i_arith_err1_               ; no, error arg1
    MOV BX, WORD PTR [BP + 2]
    MOV DL, BYTE PTR [BP + 4]
    MOV BP, ARG1
    JMP IP_RM_IMM_
_i_arith_regsrc_:
    ; (reg|ptr) <- reg ?
    TEST AH, ARGT_REG               ; arg2 reg?
    JZ _i_arith_rmsrc_              ; no, try arg2 reg|ptr
    TEST AL, ARGT_REG + ARGT_PTR    ; arg1 reg|ptr?
    JZ _i_arith_err1_               ; no, error arg1
    MOV BL, BYTE PTR [BP + 1]
    MOV BH, [ARG2 + ARG_REGISTER]
    MOV BP, ARG1
    JMP IP_RM_WIDTH2_
_i_arith_rmsrc_:
    ; reg <- (reg|ptr) ?
    TEST AH, ARGT_REG + ARGT_PTR    ; arg2 reg|ptr?
    JZ _i_arith_err2_               ; no, error arg2
    TEST AL, ARGT_REG               ; arg1 register?
    JZ _i_arith_err1_               ; no, error arg1
    MOV BL, BYTE PTR [BP + 1]
    CMP BYTE PTR [BP + 5], 0
    JNZ _i_arith_norev_
    OR BL, 2            ; Set direction if not TEST
_i_arith_norev_:
    MOV BH, [ARG1 + ARG_REGISTER]
    MOV BP, ARG2
    JMP IP_RM_WIDTH2_
_i_arith_badargs_:
    JMP ERROR_EXPECTED_2_ARGUMENTS
_i_arith_err1_:
    JMP ERROR_INVALID_ARG1
_i_arith_err2_:
    JMP ERROR_INVALID_ARG2

; Instruction pattern for a JMP or CALL instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_jmpcall_:
    CMP AL, ARGT_NONE
    JZ _i_jmpcall_badargs_
    CMP AH, ARGT_NONE
    JZ _i_jmpcall_adjust_
_i_jmpcall_badargs_:
    JMP ERROR_EXPECTED_1_ARGUMENT

_i_jmpcall_adjust_:
    MOV CX, WORD PTR [ARG1 + ARG_OFFSET]
    SUB CX, WORD PTR [PC]
    SUB CX, 2                       ; Compute displacement
    ; Adjust the argument's distance and size
    TEST AL, ARGS_MASK              ; No size?
    JZ _i_jmpcall_seta1size_
    CMP AL, ARGT_NUM + ARGS_BYTE    ; Immediate byte?
    JZ _i_jmpcall_seta1size_
    JMP SHORT _i_jmpcall_witha1size_
_i_jmpcall_seta1size_:
    AND AL, ARGT_MASK               ; Both, so set the size to word
    OR AL, ARGS_WORD
    MOV BYTE PTR [ARG1 + ARG_TYPE], AL
_i_jmpcall_witha1size_:
    MOV BL, BYTE PTR [ARG1 + ARG_DISTANCE]
    CMP BL, 0                       ; No distance?
    JNZ _i_jmpcall_do_
_i_jmpcall_withnodistance_:
    CMP AL, ARGT_NUM + ARGS_WORD    ; Word immediate?
    JZ _i_jmpcall_wnd_imm_
    MOV BL, DST_NEAR
    TEST AL, ARGS_WORD              ; Word non-immediate?
    JNZ _i_jmpcall_wnd_set_         ; Set to NEAR
    MOV BL, DST_FAR
    TEST AL, ARGS_DWORD             ; Dword?
    JNZ _i_jmpcall_wnd_set_         ; Set to FAR
    JMP SHORT _i_jmpcall_do_
_i_jmpcall_wnd_imm_:
    MOV CX, WORD PTR [ARG1 + ARG_OFFSET]
    SUB CX, WORD PTR [PC]
    SUB CX, 2                       ; Compute displacement
    MOV BL, DST_NEAR
    CMP BYTE PTR [BP], INVALID_OP   ; No short direct opcode?
    JZ _i_jmpcall_wnd_set_          ; Set to NEAR
    CMP CX, -128                    ; < -128?
    JL _i_jmpcall_wnd_set_          ; Set to NEAR
    CMP CX, 0                       ; >= 0?
    JGE _i_jmpcall_wnd_set_         ; Set to NEAR
    MOV BL, DST_SHORT               ; Otherwise, set to SHORT
_i_jmpcall_wnd_set_:
    MOV BYTE PTR [ARG1 + ARG_DISTANCE], BL

_i_jmpcall_do_:
    TEST AL, ARGT_NUM               ; arg num?
    JZ _i_jmpcall_regptr_           ; no, try arg reg|ptr
    TEST AL, ARGS_WORD              ; arg word?
    JZ _i_jmpcall_num_far_          ; no, try far jump
    CMP BL, DST_SHORT               ; short jump?
    JNZ _i_jmpcall_num_near_        ; no, try near jump
    CMP BYTE PTR [BP], INVALID_OP   ; is there a short opcode?
    JZ _i_jmpcall_num_near_         ; no, try near jump
    ; SHORT imm
    MOV CX, WORD PTR [ARG1 + ARG_OFFSET]
    SUB CX, WORD PTR [PC]
    SUB CX, 2                       ; Compute displacement
    MOV BL, [BP]
    JMP IP_SHORTJMP_
_i_jmpcall_num_near_:
    ; NEAR imm
    CMP BL, DST_NEAR                ; near jump?
    JNZ _i_jmpcall_num_far_         ; no, try far jump
    MOV AL, [BP + 1]                ;
    CALL EMIT_BYTE_
    MOV AX, WORD PTR [ARG1 + ARG_OFFSET]
    SUB AX, WORD PTR [PC]
    SUB AX, 2                       ; Compute displacement
    JMP EMIT_WORD_
_i_jmpcall_num_far_:
    ; FAR imm
    CMP BL, DST_FAR                 ; far jump?
    JNZ _i_jmpcall_err1_            ; no, error
    TEST AL, ARGS_DWORD             ; arg dword?
    JZ _i_jmpcall_err1_             ; no, error
    MOV AL, [BP + 2]
    CALL EMIT_BYTE_
    MOV AX, WORD PTR [ARG1 + ARG_DWORD]
    MOV DX, WORD PTR [ARG1 + ARG_DWORD + 2]
    JMP EMIT_DWORD_
_i_jmpcall_regptr_:
    ; NEAR r/m
    CMP BL, DST_NEAR                ; near jump?
    JNZ _i_jmpcall_rm_far_          ; no, try far jump
    TEST AL, ARGS_WORD              ; arg word?
    JZ _i_jmpcall_err1_             ; no, error
    MOV BX, [BP + 3]
    MOV BP, ARG1
    JMP IP_RM_
_i_jmpcall_rm_far_:
    ; FAR r/m
    CMP BL, DST_FAR                 ; far jump?
    JNZ _i_jmpcall_err1_            ; no, error
    TEST AL, ARGS_DWORD             ; arg dword?
    JZ _i_jmpcall_err1_             ; no, error
    MOV BL, [BP + 3]
    MOV BH, [BP + 5]
    MOV BP, ARG1
    JMP IP_RM_
_i_jmpcall_err1_:
    JMP ERROR_INVALID_ARG


; Instruction pattern for a unary instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_unary_:
    CMP AL, ARGT_NONE
    JZ _i_unary_badargs_
    CMP AH, ARGT_NONE
    JNZ _i_unary_badargs_

    ; reg
    CMP BYTE PTR [BP], INVALID_OP   ; Is there a reg opcode?
    JZ _i_unary_rm_                 ; No, try r/m
    CMP AL, ARGT_REG + ARGS_WORD    ; arg word register?
    JNZ _i_unary_rm_                ; No, try r/m
    MOV AL, BYTE PTR [BP]
    OR AL, BYTE PTR [ARG1 + ARG_REGISTER]
    JMP EMIT_BYTE_
_i_unary_rm_:
    ; r/m
    TEST AL, ARGT_REG + ARGT_PTR    ; arg reg|ptr?
    JZ _i_unary_err_                ; no, error
    MOV BX, [BP + 1]
    MOV BP, ARG1
    JMP IP_RM_WIDTH_

_i_unary_badargs_:
    JMP ERROR_EXPECTED_1_ARGUMENT
_i_unary_err_:
    JMP ERROR_INVALID_ARG

; Instruction pattern for an escape instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_esc_:
    CMP AH, ARGT_NONE
    JZ _i_esc_badargs_

    TEST AL, ARGT_NUM               ; arg1 num?
    JZ _i_esc_err1_                 ; no, error arg1
    TEST AH, ARGT_REG + ARGT_PTR    ; arg2 reg|ptr?
    JZ _i_esc_err2_                 ; no, error arg2
    MOV DX, WORD PTR [ARG1 + ARG_WORD]
    CMP DX, 40h                     ; value of arg1 < 40h?
    JAE _i_esc_err1_                ; no, error arg1
    MOV BL, DL
    AND BL, 111000b
    SHR BL, 1
    SHR BL, 1
    SHR BL, 1                       ; BL = (DL & 111000b) >> 3
    OR BL, 11011000b                ; BL = BL | opcode
    MOV BH, DL
    AND BH, 111b                    ; BH = DL & 111b
    MOV BP, ARG2
    JMP IP_RM_
_i_esc_badargs_:
    JMP ERROR_EXPECTED_2_ARGUMENTS
_i_esc_err1_:
    JMP ERROR_INVALID_ARG1
_i_esc_err2_:
    JMP ERROR_INVALID_ARG2

; Instruction pattern for an IN or OUT instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_inout_:
    CMP AH, ARGT_NONE
    JZ _i_inout_badargs_

    MOV SI, ARG1                    ; SI contains the accumulator
    MOV DI, ARG2                    ; DI contains the port number
    CMP BYTE PTR [BP + 2], 0
    JZ _i_inout_in_
    MOV SI, ARG2
    MOV DI, ARG1
_i_inout_in_:
    MOV AL, BYTE PTR [SI + ARG_TYPE]    ; AL has the accumulator's type
    MOV AH, BYTE PTR [DI + ARG_TYPE]    ; AH has the port's type

    TEST AL, ARGT_REG               ; acc reg?
    JZ _i_inout_err1_               ; no; error acc
    CMP BYTE PTR [SI + ARG_REGISTER], AREG_ACC  ; acc?
    JNZ _i_inout_err1_              ; no; error acc
    CMP AH, ARGT_NUM + ARGS_BYTE    ; port imm byte?
    JNZ _i_inout_prtdx_             ; no; try DX
    ; acc <-> imm
    MOV BL, [BP]
    TEST AL, ARGS_WORD
    JZ _i_inout_prtimm_byte_
    OR BL, 1
_i_inout_prtimm_byte_:
    MOV AL, BL
    MOV AH, BYTE PTR [DI + ARG_BYTE]
    JMP EMIT_WORD_
_i_inout_prtdx_:
    CMP AH, ARGT_REG + ARGS_WORD    ; port reg word?
    JNZ _i_inout_err2_              ; no; error port
    CMP BYTE PTR [DI + ARG_REGISTER], AREG_DX   ; port DX?
    JNZ _i_inout_err2_              ; no; error port
    MOV BL, [BP + 1]
    TEST AL, ARGS_WORD
    JZ _i_inout_prtdx_byte_
    OR BL, 1
_i_inout_prtdx_byte_:
    MOV AL, BL
    JMP EMIT_BYTE_
_i_inout_badargs_:
    JMP ERROR_EXPECTED_2_ARGUMENTS
_i_inout_err1_:
    MOV BP, SI
    JMP ERROR_INVALID_ARG_BP
_i_inout_err2_:
    MOV BP, DI
    JMP ERROR_INVALID_ARG_BP

; Instruction pattern for a software interrupt instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_interrupt_:
    CMP AL, ARGT_NONE
    JZ _i_interrupt_badargs_
    CMP AH, ARGT_NONE
    JNZ _i_interrupt_badargs_

    CMP AL, ARGT_NUM + ARGS_BYTE            ; arg1 byte imm?
    JNZ _i_interrupt_err_                   ; no, error
    MOV BL, BYTE PTR [ARG1 + ARG_BYTE]
    CMP BL, 3                               ; arg1 == 3?
    JNZ _i_interrupt_any_                   ; no, any interrupt
    MOV AL, [BP]
    JMP EMIT_BYTE_                           ; int3
_i_interrupt_any_:
    MOV AL, [BP + 1]
    MOV AH, BL
    JMP EMIT_WORD_
_i_interrupt_badargs_:
    JMP ERROR_EXPECTED_1_ARGUMENT
_i_interrupt_err_:
    JMP ERROR_INVALID_ARG

; Instruction pattern for a short jump instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_jmpshort_:
    CMP AL, ARGT_NONE
    JZ _i_jmpshort_badargs_
    CMP AH, ARGT_NONE
    JNZ _i_jmpshort_badargs_

    TEST AL, ARGT_NUM               ; arg1 imm?
    JZ _i_jmpshort_err_             ; no, error
    TEST AL, ARGS_DWORD             ; arg1 dword?
    JNZ _i_jmpshort_err_            ; no, error
    MOV CX, WORD PTR [ARG1 + ARG_OFFSET]
    SUB CX, WORD PTR [PC]
    SUB CX, 2                       ; Compute displacement
    MOV BL, [BP]
    JMP IP_SHORTJMP_
_i_jmpshort_badargs_:
    JMP ERROR_EXPECTED_1_ARGUMENT
_i_jmpshort_err_:
    JMP ERROR_INVALID_ARG

; Instruction pattern for a load address instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_loadaddr_:
    CMP AH, ARGT_NONE
    JZ _i_loadaddr_badargs_

    CMP AL, ARGT_REG + ARGS_WORD            ; arg1 reg word?
    JNZ _i_loadaddr_err1_                   ; no, error arg1
    TEST AH, ARGT_PTR                       ; arg2 ptr?
    JZ _i_loadaddr_err2_                    ; no, error arg2
    MOV BL, [BP]
    MOV BH, BYTE PTR [ARG1 + ARG_REGISTER]
    MOV BP, ARG2
    JMP IP_RM_
_i_loadaddr_badargs_:
    JMP ERROR_EXPECTED_2_ARGUMENTS
_i_loadaddr_err1_:
    JMP ERROR_INVALID_ARG1
_i_loadaddr_err2_:
    JMP ERROR_INVALID_ARG2

; Instruction pattern for a MOV instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_mov_:
    CMP AH, ARGT_NONE
    JNZ _i_mov_argsok_
    JMP ERROR_EXPECTED_2_ARGUMENTS
_i_mov_argsok_:
    CALL EQUATE_SIZES_
    ; reg|ptr word <- seg
    TEST AH, ARGT_SEG               ; arg2 seg?
    JZ _i_mov_segrm_                ; no, try seg <- reg|ptr
    TEST AL, ARGT_REG + ARGT_PTR    ; arg1 reg|ptr?
    JZ _i_mov_err1_                 ; no, error arg1
    TEST AL, ARGS_WORD              ; arg1 word?
    JZ _i_mov_err1_                 ; no, error arg1
    MOV BL, BYTE PTR [BP + 5]
    MOV BH, BYTE PTR [ARG2 + ARG_SEGMENT]
    MOV BP, ARG1
    JMP IP_RM_
_i_mov_segrm_:
    ; seg <- reg|ptr word
    TEST AL, ARGT_SEG               ; arg1 seg?
    JZ _i_mov_accptr_               ; no, try acc <- ptr
    CMP BYTE PTR [ARG1 + ARG_SEGMENT], ASEG_CS  ; arg1 CS?
    JZ _i_mov_err1_                 ; yes, error arg1
    TEST AH, ARGT_REG + ARGT_PTR    ; arg2 reg|ptr?
    JZ _i_mov_err2_                 ; no, error arg2
    TEST AH, ARGS_WORD              ; arg2 word?
    JZ _i_mov_err2_                 ; no, error arg2
    MOV BL, BYTE PTR [BP + 5]
    OR BL, 2
    MOV BH, BYTE PTR [ARG1 + ARG_SEGMENT]
    MOV BP, ARG2
    JMP IP_RM_
_i_mov_accptr_:
    ; acc <- ptr (direct)
    TEST AL, ARGT_REG               ; arg1 reg?
    JZ _i_mov_ptracc_               ; no, try ptr <- acc
    CMP BYTE PTR [ARG1 + ARG_REGISTER], AREG_ACC    ; arg1 acc?
    JNZ _i_mov_regimm_              ; no, try reg <- imm
    TEST AH, ARGT_PTR               ; arg2 ptr?
    JZ _i_mov_regimm_               ; no, try reg <- imm
    CMP BYTE PTR [ARG2 + ARG_EAMODE], EA_DIRECT     ; arg2 ea direct?
    JNZ _i_mov_regimm_              ; no, try reg <- imm
    MOV BL, BYTE PTR [BP]
    MOV DX, WORD PTR [ARG2 + ARG_OFFSET]
    JMP IP_OP_A2PTR_
_i_mov_ptracc_:
    ; ptr (direct) <- acc
    TEST AL, ARGT_PTR               ; arg1 ptr?
    JZ _i_mov_err1_                 ; no, error arg1
    CMP BYTE PTR [ARG1 + ARG_EAMODE], EA_DIRECT     ; arg1 ea direct?
    JNZ _i_mov_rmimm_               ; no, try reg|ptr <- imm
    TEST AH, ARGT_REG               ; arg2 reg?
    JZ _i_mov_rmimm_                ; no, try reg|ptr <- imm
    CMP BYTE PTR [ARG2 + ARG_REGISTER], AREG_ACC    ; arg2 acc?
    JNZ _i_mov_rmreg_               ; no, try reg|ptr <- reg
    MOV BL, BYTE PTR [BP]
    OR BL, 2
    MOV DX, WORD PTR [ARG1 + ARG_OFFSET]
    JMP IP_OP_A2PTR_
    ; These errors are in the middle of the block for the
    ; short jumps
_i_mov_err1_:
    JMP ERROR_INVALID_ARG1
_i_mov_err2_:
    JMP ERROR_INVALID_ARG2
_i_mov_regimm_:
    ; reg <- imm
    ; (we already know arg1 reg)
    TEST AH, ARGT_NUM               ; arg2 num?
    JZ _i_mov_regptr_               ; no, try reg <- ptr
    TEST AL, ARGS_BYTE              ; arg1 byte?
    JZ _i_mov_regimm_word_          ; no, try arg1 word
    TEST AH, ARGS_BYTE              ; arg2 byte?
    JZ _i_mov_rmimm_                ; no, try reg|ptr <- imm
    MOV AL, [BP + 1]
    OR AL, [ARG1 + ARG_REGISTER]
    MOV AH, [ARG2 + ARG_BYTE]
    JMP EMIT_WORD_
_i_mov_regimm_word_:
    TEST AH, ARGS_DWORD             ; arg2 dword?
    JNZ _i_mov_err2_                ; yes, error arg2
    MOV AL, [BP + 1]
    OR AL, 8
    OR AL, [ARG1 + ARG_REGISTER]
    CALL EMIT_BYTE_
    MOV AX, WORD PTR [ARG2 + ARG_WORD]
    JMP EMIT_WORD_
_i_mov_regptr_:
    ; reg <- ptr
    ; (we already know arg1 reg)
    TEST AH, ARGT_PTR               ; arg2 ptr?
    JZ _i_mov_rmimm_                ; no, try reg|ptr <- imm
    MOV BL, BYTE PTR [BP + 2]
    OR BL, 2
    MOV BH, BYTE PTR [ARG1 + ARG_REGISTER]
    MOV BP, ARG2
    JMP IP_RM_WIDTH2_
_i_mov_rmimm_:
    ; reg|ptr <- imm
    ; (we already know arg1 reg|ptr)
    TEST AH, ARGT_NUM               ; arg2 num?
    JZ _i_mov_rmreg_                ; no, try reg|ptr <- reg
    MOV BX, WORD PTR [BP + 3]
    XOR DX, DX
    MOV BP, ARG1
    JMP IP_RM_IMM_
_i_mov_rmreg_:
    ; reg|ptr <- reg
    ; (we already know arg1 reg|ptr)
    TEST AH, ARGT_REG               ; arg2 reg?
    JZ _i_mov_err2_                 ; no, error arg2
    MOV BL, BYTE PTR [BP + 2]
    MOV BH, BYTE PTR [ARG2 + ARG_REGISTER]
    MOV BP, ARG1
    JMP IP_RM_WIDTH2_

; Instruction pattern for a PUSH or POP instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_stack_:
    CMP AL, ARGT_NONE
    JZ _i_stack_badargs_
    CMP AH, ARGT_NONE
    JNZ _i_stack_badargs_

    TEST AL, ARGS_MASK
    JNZ _i_stack_reg_
    OR AL, ARGS_WORD

_i_stack_reg_:
    TEST AL, ARGS_WORD      ; arg1 word?
    JZ _i_stack_err_        ; no, error arg
    TEST AL, ARGT_REG       ; arg1 reg?
    JZ _i_stack_ptr_        ; no, try ptr
    MOV AL, BYTE PTR [BP]
    OR AL, BYTE PTR [ARG1 + ARG_REGISTER]
    JMP EMIT_BYTE_
_i_stack_ptr_:
    TEST AL, ARGT_PTR       ; arg1 ptr?
    JZ _i_stack_seg_        ; no, try seg
    MOV BX, WORD PTR [BP + 1]
    MOV BP, ARG1
    JMP IP_RM_
_i_stack_seg_:
    TEST AL, ARGT_SEG       ; arg1 seg?
    JZ _i_stack_err_        ; no, error arg
    MOV AL, BYTE PTR [BP + 3]
    MOV BL, BYTE PTR [ARG1 + ARG_SEGMENT]
    CMP AL, 7               ; opcode is 7?
    JNZ _i_stack_seg_emit_  ; no, emit
    CMP BL, ASEG_CS         ; arg1 CS?
    JZ _i_stack_err_        ; yes, error arg1
_i_stack_seg_emit_:
    SHL BL, 1
    SHL BL, 1
    SHL BL, 1
    OR AL, BL
    JMP EMIT_BYTE_
_i_stack_badargs_:
    JMP ERROR_EXPECTED_1_ARGUMENT
_i_stack_err_:
    JMP ERROR_INVALID_ARG

; Instruction pattern for a shift or rotate instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_rotate_:
    CMP AH, ARGT_NONE
    JZ _i_rotate_badargs_
    ; reg|ptr <- 1
    TEST AL, ARGT_REG + ARGT_PTR    ; arg1 reg|ptr?
    JZ _i_rotate_err1_              ; no, error arg1
    TEST AH, ARGT_NUM               ; arg2 num?
    JZ _i_rotate_cl_                ; no, try CL
    TEST AH, ARGS_DWORD             ; arg2 dword?
    JNZ _i_rotate_err2_             ; yes, error arg2
    CMP WORD PTR [ARG2 + ARG_WORD], 1   ; arg2 == 1?
    JNZ _i_rotate_err2_             ; no, error arg2
    MOV BX, WORD PTR [BP]
    MOV BP, ARG1
    JMP IP_RM_WIDTH_
_i_rotate_cl_:
    ; reg|ptr <- CL
    ; (we know arg1 reg|ptr)
    TEST AH, ARGT_REG               ; arg2 register?
    JZ _i_rotate_err2_              ; no, error arg2
    TEST AH, ARGS_BYTE              ; arg2 byte?
    JZ _i_rotate_err2_              ; no, error arg2
    CMP BYTE PTR [ARG2 + ARG_REGISTER], AREG_CL ; arg2 CL?
    JNZ _i_rotate_err2_             ; no, error arg2
    MOV BX, WORD PTR [BP]
    OR BL, 2
    MOV BP, ARG1
    JMP IP_RM_WIDTH_
_i_rotate_badargs_:
    JMP ERROR_EXPECTED_2_ARGUMENTS
_i_rotate_err1_:
    JMP ERROR_INVALID_ARG1
_i_rotate_err2_:
    JMP ERROR_INVALID_ARG2

; Instruction pattern for a return instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_ret_:
    CMP AL, ARGT_NONE       ; any arguments?
    JNZ _i_ret_1arg_        ; yes, try 1 argument
    MOV AL, [BP]
    JMP EMIT_BYTE_
_i_ret_1arg_:
    CMP AH, ARGT_NONE       ; second argument?
    JNZ _i_ret_badargs_     ; yes, error
    TEST AL, ARGT_NUM       ; arg1 num?
    JZ _i_ret_err_          ; no, error
    TEST AL, ARGS_DWORD     ; arg1 dword?
    JNZ _i_ret_err_         ; yes, error
    MOV AL, [BP + 1]
    CALL EMIT_BYTE_
    MOV AX, WORD PTR [ARG1 + ARG_WORD]
    JMP EMIT_WORD_
_i_ret_badargs_:
    JMP ERROR_EXPECTED_1_ARGUMENT
_i_ret_err_:
    JMP ERROR_INVALID_ARG

; Instruction pattern for an XCHG instruction.
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BP = address of arguments for the instruction emitter
i_xchg_:
    CMP AH, ARGT_NONE
    JZ _i_xchg_badargs_
    CALL EQUATE_SIZES_
    ; AX <- reg
    TEST AH, ARGT_REG       ; arg2 reg?
    JZ _i_xchg_regrm_       ; no, try reg <- reg|ptr
    TEST AL, ARGT_REG       ; arg1 reg?
    JZ _i_xchg_rmreg_       ; no, try reg|ptr <- reg
    TEST AL, ARGS_WORD      ; arg1 word?
    JZ _i_xchg_rmreg_       ; no, try reg|ptr <- reg
    TEST AH, ARGS_WORD      ; arg2 word?
    JZ _i_xchg_rmreg_       ; no, try reg|ptr <- reg
    CMP BYTE PTR [ARG1 + ARG_REGISTER], AREG_AX ; arg1 AX?
    JNZ _i_xchg_regax_      ; no, try reg <- AX
    MOV AL, BYTE PTR [BP]
    OR AL, BYTE PTR [ARG2 + ARG_REGISTER]
    JMP EMIT_BYTE_
_i_xchg_regax_:
    ; reg <- AX
    ; (we know arg1 and arg2 reg word)
    CMP BYTE PTR [ARG2 + ARG_REGISTER], AREG_AX ; arg2 AX?
    JNZ _i_xchg_rmreg_      ; no, try reg|ptr <- reg
    MOV AL, BYTE PTR [BP]
    OR AL, BYTE PTR [ARG1 + ARG_REGISTER]
    JMP EMIT_BYTE_
_i_xchg_rmreg_:
    ; reg|ptr <- reg
    ; (we know arg2 reg)
    TEST AL, ARGT_REG + ARGT_PTR    ; arg1 reg|ptr?
    JZ _i_xchg_err1_                ; no, error arg1
    MOV BL, BYTE PTR [BP + 1]
    MOV BH, BYTE PTR [ARG2 + ARG_REGISTER]
    MOV BP, ARG1
    JMP IP_RM_WIDTH2_
_i_xchg_regrm_:
    ; reg <- reg|ptr
    TEST AL, ARGT_REG               ; arg1 reg?
    JZ _i_xchg_err1_                ; no, error arg1
    TEST AH, ARGT_REG + ARGT_PTR    ; arg2 reg|ptr?
    JZ _i_xchg_err2_                ; no, error arg2
    MOV BL, BYTE PTR [BP + 1]
    MOV BH, BYTE PTR [ARG1 + ARG_REGISTER]
    MOV BP, ARG2
    JMP IP_RM_WIDTH2_
_i_xchg_badargs_:
    JMP ERROR_EXPECTED_2_ARGUMENTS
_i_xchg_err1_:
    JMP ERROR_INVALID_ARG1
_i_xchg_err2_:
    JMP ERROR_INVALID_ARG2



; Instruction pattern IP_OP_A2VALUE_
; One opcode followed by the value of arg2.
; Arg1 is the accumulator (caller must check);
; arg2 is a number the same size
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BL the opcode
IP_OP_A2VALUE_:
    TEST AL, ARGS_BYTE      ; arg1 byte?
    JZ _ipoa2v_word_        ; no, try arg1 word
    TEST AH, ARGS_BYTE      ; arg2 byte?
    JZ _ipoa2v_err2_        ; no, error arg2
    MOV AL, BL
    MOV AH, BYTE PTR [ARG2 + ARG_BYTE]
    JMP EMIT_WORD_
_ipoa2v_word_:
    TEST AL, ARGS_WORD      ; arg1 word?
    JZ _ipoa2v_err1_        ; no, error arg1
    TEST AH, ARGS_DWORD     ; arg2 dword?
    JNZ _ipoa2v_err2_       ; yes, error arg2
    MOV AL, BL
    OR AL, 1
    CALL EMIT_BYTE_
    MOV AX, WORD PTR [ARG2 + ARG_WORD]
    JMP EMIT_WORD_
_ipoa2v_err1_:
    JMP ERROR_INVALID_ARG1
_ipoa2v_err2_:
    JMP ERROR_INVALID_ARG2

; Instruction pattern IP_OP_A2PTR_
; One opcode followed by the pointer in arg2.
; Arg1 is the accumulator (caller must check);
; arg2 is a direct pointer (caller must check)
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
;   BL the opcode
;   DX the address
IP_OP_A2PTR_:
    TEST AL, ARGS_BYTE      ; arg1 byte?
    JZ _ipoa2p_word_        ; no, try word
    TEST AH, ARGS_BYTE      ; arg2 byte?
    JZ _ipoa2p_err2_        ; no, error arg2
    JMP SHORT _ipoa2p_emit_
_ipoa2p_word_:
    TEST AL, ARGS_WORD      ; arg1 word?
    JZ _ipoa2p_err1_        ; no, error arg1
    TEST AH, ARGS_WORD      ; arg2 word?
    JZ _ipoa2p_err2_        ; no, error arg2
    OR BL, 1
_ipoa2p_emit_:
    MOV AL, BL
    CALL EMIT_BYTE_
    MOV AX, DX
    JMP EMIT_WORD_
_ipoa2p_err1_:
    JMP ERROR_INVALID_ARG1
_ipoa2p_err2_:
    JMP ERROR_INVALID_ARG2

; Instruction pattern IP_RM_
; An opcode followed by the ModR/M byte and an offset.
; Inputs:
;   BL the opcode
;   BH the extension code
;   BP the address of the argument to be encoded
IP_RM_:
    AND BH, 111b            ; Pre-shift the extension code
    SHL BH, 1
    SHL BH, 1
    SHL BH, 1
    MOV AL, BYTE PTR [BP + ARG_TYPE]
    TEST AL, ARGT_REG   ; Register?
    JNZ _iprm_reg_
    TEST AL, ARGT_PTR   ; Pointer?
    JNZ _iprm_ptr_
    JMP ERROR_INVALID_ARG_BP
_iprm_reg_:                 ; Register
    MOV DH, BYTE PTR [BP + ARG_REGISTER]
    OR DH, 11000000b        ; Compute mod and r/m
    JMP SHORT _iprm_emit_
_iprm_ptr_:                 ; Pointer
    MOV SI, WORD PTR [BP + ARG_OFFSET]
    MOV DH, BYTE PTR [BP + ARG_EAMODE]
    TEST DH, EA_OFFSET      ; An offset has been specified?
    JZ _iprm_emit_          ; No; emit 00xxxyyy
    TEST DH, EA_OFFSET16    ; A 16-bit offset?
    JNZ _iprm_ptr_offset16_ ; Yes; emit 16-bit offset
    CMP SI, -128            ; Offset < -128?
    JL _iprm_ptr_offset16_  ; Yes; emit 16-bit offset
    CMP SI, 127             ; Offset > 127?
    JG _iprm_ptr_offset16_  ; Yes; emit 16-bit offset
    OR DH, 01000000b        ; Emit 01xxxyyy (8-bit offset)
    JMP SHORT _iprm_emit_
_iprm_ptr_offset16_:
    OR DH, 10000000b        ; Emit 10xxxyyy (16-bit offset)
_iprm_emit_:
    AND DH, 11000111b       ; Clear the middle bits
    OR BH, DH               ; Add the extension code
    MOV AX, BX
    CALL EMIT_WORD_          ; Emit the opcode and mod/rm bytes

    AND BH, 11000000b       ; Now we emit the offset based on mod
    CMP BH, 11000000b       ; 11 is a register, so no offset
    JZ _iprm_ret_
    MOV AX, SI
    CMP BH, 01000000b       ; 01, as we remember, is an 8-bit offset
    JZ _iprm_8bitoff_
    CMP BH, 10000000b       ; 10 is a 16-bit offset
    JZ _iprm_16bitoff_
    CMP BYTE PTR [BP + ARG_EAMODE], EA_DIRECT
    JNZ _iprm_ret_          ; If EA mode is not DIRECT, no offset

_iprm_16bitoff_:
    JMP EMIT_WORD_
_iprm_8bitoff_:
    JMP EMIT_BYTE_
_iprm_ret_:
    RET

; Instruction pattern IP_RM_WIDTH_
; An opcode that depends on the argument's width, followed by ModR/M and
; offset.
; Inputs:
;   BL the opcode
;   BH the extension code
;   BP the address of the argument to be encoded
IP_RM_WIDTH_:
    MOV AL, BYTE PTR [BP + ARG_TYPE]
    TEST AL, ARGS_BYTE
    JNZ _iprmw_byte_
    TEST AL, ARGS_WORD
    JNZ _iprmw_word_
    JMP ERROR_INVALID_ARG_BP
_iprmw_word_:
    OR BL, 1
_iprmw_byte_:
    JMP IP_RM_

; Instruction pattern IP_RM_WIDTH2_
; An opcode that depends on the width of arg1 and arg2 (both the same)
; followed by ModR/M and offset.
; Inputs:
;   BL the opcode
;   BH the extension code
;   BP the address of the argument to be encoded
IP_RM_WIDTH2_:
    MOV AL, BYTE PTR [ARG1 + ARG_TYPE]
    MOV AH, BYTE PTR [ARG2 + ARG_TYPE]
    TEST AL, ARGS_BYTE
    JNZ _iprmw2_byte_
    TEST AL, ARGS_WORD
    JNZ _iprmw2_word_
    JMP ERROR_INVALID_ARG1
_iprmw2_byte_:
    TEST AH, ARGS_BYTE
    JZ _iprmw2_err2_
    JMP IP_RM_
_iprmw2_word_:
    TEST AH, ARGS_WORD
    JZ _iprmw2_err2_
    OR BL, 1
    JMP IP_RM_
_iprmw2_err2_:
    JMP ERROR_INVALID_ARG2

; Instruction pattern IP_RM_IMM_
; An opcode that depends on the width of arg1 and arg2
; followed by ModR/M, an offset, and the value of arg2.
; Inputs:
;   BL the opcode
;   BH the extension code
;   DL whether to do sign extension of a byte onto a word destination
;       (0 = false)
;   BP the address of the argument to be encoded
IP_RM_IMM_:
    MOV AL, BYTE PTR [ARG1 + ARG_TYPE]
    MOV AH, BYTE PTR [ARG2 + ARG_TYPE]
    TEST AL, ARGS_BYTE
    JNZ _iprmi_byte1_
    TEST AL, ARGS_WORD
    JNZ _iprmi_word1_
    JMP ERROR_INVALID_ARG1
_iprmi_byte1_:
    TEST AH, ARGS_BYTE
    JZ _iprmi_err2_
    CALL IP_RM_
    MOV AL, BYTE PTR [ARG2 + ARG_BYTE]
    JMP EMIT_BYTE_
_iprmi_word1_:
    TEST AH, ARGS_BYTE
    JZ _iprmi_word2_
    CMP DL, 0
    JZ _iprmi_emit_word_
    MOV DX, WORD PTR [ARG2 + ARG_WORD]
    CMP DX, 127
    JG _iprmi_emit_word_
    OR BL, 3
    CALL IP_RM_
    MOV AL, DL
    JMP EMIT_BYTE_
_iprmi_word2_:
    TEST AH, ARGS_WORD
    JZ _iprmi_err2_
_iprmi_emit_word_:
    OR BL, 1
    CALL IP_RM_
    MOV AX, WORD PTR [ARG2 + ARG_WORD]
    JMP EMIT_WORD_
_iprmi_err2_:
    JMP ERROR_INVALID_ARG2

; Instruction pattern IP_SHORTJMP_
; A short jump.
; Inputs:
;   BL the opcode
;   CX the displacement
IP_SHORTJMP_:
    CMP [PASS], 2
    JNZ _ipsj_emit_
    CMP CX, -128
    JL _ipsj_err_
    CMP CX, 127
    JG _ipsj_err_
_ipsj_emit_:
    MOV AH, CL
    MOV AL, BL
    JMP EMIT_WORD_
_ipsj_err_:
    JMP ERROR_TOO_FAR

; Procedure EQUATE_SIZES_
; If one of the arguments is of indeterminate size and the other
; isn't, sets the size of the first
; Inputs:
;   AL = arg1's type
;   AH = arg2's type
; Returns:
;   AL = arg1's type
;   AH = arg2's type
EQUATE_SIZES_:
    TEST AL, ARGS_MASK + ARGT_SEG
    JZ _eqs_arg2_check_
    TEST AH, ARGS_MASK + ARGT_SEG
    JZ _eqs_arg1_check_
    RET
_eqs_arg1_check_:
    TEST AL, ARGS_BYTE
    JNZ _eqs_arg2_setbyte_
    TEST AL, ARGS_WORD + ARGT_SEG
    JNZ _eqs_arg2_setword_
    RET
_eqs_arg2_check_:
    TEST AH, ARGT_NUM
    JNZ _eqs_arg2_check_ret_
    TEST AH, ARGS_BYTE
    JNZ _eqs_arg1_setbyte_
    TEST AH, ARGS_WORD + ARGT_SEG
    JNZ _eqs_arg1_setword_
_eqs_arg2_check_ret_:
    RET
_eqs_arg2_setbyte_:
    AND AH, ARGT_MASK
    OR AH, ARGS_BYTE
    JMP SHORT _eqs_arg2_set_
_eqs_arg2_setword_:
    AND AH, ARGT_MASK
    OR AH, ARGS_WORD
_eqs_arg2_set_:
    MOV BYTE PTR [ARG2 + ARG_TYPE], AH
    RET
_eqs_arg1_setbyte_:
    AND AL, ARGT_MASK
    OR AL, ARGS_BYTE
    JMP SHORT _eqs_arg1_set_
_eqs_arg1_setword_:
    AND AL, ARGT_MASK
    OR AL, ARGS_WORD
_eqs_arg1_set_:
    MOV BYTE PTR [ARG1 + ARG_TYPE], AL
    RET
