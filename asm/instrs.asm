; Indirect pointers to each instruction's definition
INSTR_TABLE DW _etbl_aaa_, _etbl_aad_, _etbl_aam_, _etbl_aas_
            DW _etbl_adc_, _etbl_add_, _etbl_and_, _etbl_call_
            DW _etbl_cbw_, _etbl_clc_, _etbl_cld_, _etbl_cli_
            DW _etbl_cmc_, _etbl_cmpsb_, _etbl_cmpsw_, _etbl_cmp_
            DW _etbl_cwd_, _etbl_daa_, _etbl_das_, _etbl_dec_
            DW _etbl_div_, _etbl_hlt_, _etbl_esc_, _etbl_idiv_
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
            DW _etbl_mul_, _etbl_neg_, _etbl_not_, _etbl_nop_
            DW _etbl_or_, _etbl_out_, _etbl_pop_, _etbl_popf_
            DW _etbl_push_, _etbl_pushf_, _etbl_rcl_, _etbl_rcr_
            DW _etbl_ret_, _etbl_retf_, _etbl_retn_, _etbl_rol_
            DW _etbl_ror_, _etbl_sahf_, _etbl_sal_, _etbl_sar_
            DW _etbl_sbb_, _etbl_scasb_, _etbl_scasw_, _etbl_shl_
            DW _etbl_shr_, _etbl_stc_, _etbl_std_, _etbl_stosb_
            DW _etbl_stosw_, _etbl_sti_, _etbl_sub_, _etbl_test_
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
_etbl_cmpsb_    DW i_noargs_
                DB 10100110b
_etbl_cmpsw_    DW i_noargs_
                DB 10100111b
_etbl_cmp_      DW i_arith_
                DB 00111100b, 00111000b, 10000000b, 111b, 1, 0
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
_etbl_hlt_      DW i_noargs_
                DB 11110100b
_etbl_esc_      DW i_esc_
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
_etbl_not_      DW i_unary_
                DB 0Fh, 11110110b, 010b
_etbl_nop_      DW i_noargs_
                DB 10010000b
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
_etbl_stosb_    DW i_noargs_
                DB 10101010b
_etbl_stosw_    DW i_noargs_
                DB 10101011b
_etbl_sti_      DW i_noargs_
                DB 11111011b
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

i_noargs_:
i_aamaad_:
i_arith_:
i_jmpcall_:
i_unary_:
i_esc_:
i_inout_:
i_interrupt_:
i_jmpshort_:
i_loadaddr_:
i_mov_:
i_stack_:
i_rotate_:
i_ret_:
i_xchg_:
