; Hash tables!
; A hash table consists of 256 pointers to linked lists.
; Hash tables occupy one segment.
; The first free memory position is stored in offset 0.
; The following 256 words contain the positions of the first element
; of each list (or 0 if empty.)
; Each element is preceded by a word pointing to the next element, or
; 0 if none.

; Procedure HASH_PREPARE
; Prepares a segment for a hash table.
; Inputs:
;   ES the hash table segment
HASH_PREPARE:
    PUSH AX
    PUSH CX
    PUSH DI
    CLD
    MOV WORD PTR ES:[0], 514    ; Point to the first word after the pointers
    MOV DI, 2
    MOV CX, 256
    XOR AX, AX
    REP STOSW           ; Set the 256 pointers to 0
    POP DI
    POP CX
    POP AX
    RET

; Procedure HASH_GET
; Looks up an element by identifier
; Inputs:
;   DS:SI the length-prefix identifier
;   DL the offset of the identifier within each element
;   ES the hash table's segment
; Outputs:
;   DI the offset of the element if found,
;      or the offset of the last next-pointer if not found
;   CF set if not found; unset otherwise
HASH_GET:
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    PUSH BP
    MOV BP, SI
    CALL HASHKEY_       ; Compute the hash key
    XOR DH, DH
    INC DX
    INC DX
    XOR AH, AH
    INC AX
    SHL AX, 1
    MOV DI, AX          ; Now DI has the pointer to the first element
    CLD
_hg_loop_:
    MOV BX, ES:[DI]
    OR BX, BX           ; Is the pointer 0?
    JZ _hg_notfound_    ; Yes, return 'not found'
    MOV DI, BX
    ADD DI, DX          ; DI points to the element's identifier
    XOR CX, CX
    MOV CL, [SI]        ; CX contains the identifier's length
    INC CX
    REPZ CMPSB          ; Compare
    JZ _hg_found_       ; Equal? Then found
    MOV DI, BX          ; Otherwise, set DI to the next element's pointer
    MOV SI, BP          ; and restore the value of SI
    JMP _hg_loop_       ; before trying the next element
_hg_found_:
    MOV DI, BX          ; Point DI to the next element
    INC DI
    INC DI
    JMP _hg_ret_
_hg_notfound_:
    STC
_hg_ret_:
    POP BP
    POP SI
    POP DX
    POP BX
    POP AX
    RET

; Procedure HASH_ADD
; Creates space for a new element in a hash table.
; You must call this after HASH_GET returns "not found".
; Caller must update ES:[0] after adding the element.
; Inputs:
;   ES:DI the hash bucket's last "next element" pointer
; Outputs:
;   DI the position to write the new element in
HASH_ADD:
    PUSH AX
    MOV AX, ES:[0]      ; Get the next empty position in AX
    MOV ES:[DI], AX     ; Update the next-element pointer
    MOV DI, AX
    MOV WORD PTR ES:[DI], 0 ; This is the new last element
    INC DI
    INC DI              ; Point to the new element's space
    POP AX
    RET

; Procedure HASHKEY_
; Computes a Pearson hash key for an identifier.
; Inputs:
;   DS:SI the length-prefixed identifier
; Outputs:
;   AL the hash key, a number between 0 and FFh
HASHKEY_:
    PUSH BX
    PUSH CX
    PUSH SI
    XOR AL, AL
    XOR CX, CX
    MOV CL, [SI]
    JCXZ _hash_done_
    MOV BX, _hash_tbl_
    INC SI
_hash_loop_:
    XOR AL, [SI]
    INC SI
    XLAT
    LOOP _hash_loop_
_hash_done_:
    POP SI
    POP CX
    POP BX
    RET

; A random permutation of numbers between 0 and FFh
_hash_tbl_  DB 0EAh, 9h, 67h, 3Ch, 5h, 4Fh, 0E8h, 0E5h, 2Dh, 33h, 83h, 3h, 0A8h, 1Dh, 0AAh, 0D8h
            DB 63h, 0A1h, 6Fh, 0CCh, 0DCh, 0D1h, 4Eh, 59h, 48h, 0BFh, 9Dh, 77h, 0E2h, 0B8h, 0F4h, 86h
            DB 15h, 3Dh, 0AFh, 0Fh, 0DFh, 64h, 0E6h, 1Ch, 80h, 0B9h, 54h, 0D0h, 0A4h, 2Ch, 71h, 69h
            DB 1Bh, 55h, 0CBh, 92h, 99h, 82h, 42h, 2Ah, 0FAh, 8Ch, 0AEh, 85h, 73h, 4h, 34h, 49h
            DB 41h, 0Ah, 68h, 0EEh, 1Eh, 0D3h, 2Eh, 79h, 2h, 0BEh, 9Fh, 0ACh, 70h, 9Ch, 5Fh, 2Fh
            DB 7Ch, 0B1h, 4Dh, 0CAh, 51h, 26h, 7Bh, 0Dh, 0B6h, 0F2h, 40h, 21h, 0E1h, 0h, 0F1h, 7Ah
            DB 0D2h, 25h, 6Ah, 0A3h, 52h, 62h, 22h, 0DAh, 0BBh, 0D6h, 7Dh, 84h, 78h, 0DBh, 0FCh, 20h
            DB 87h, 0D7h, 0F5h, 30h, 0C6h, 0DEh, 4Ch, 0E7h, 0D5h, 0C0h, 0E3h, 90h, 13h, 98h, 6Eh, 0Ch
            DB 0D9h, 7Eh, 0C4h, 0C9h, 0F8h, 94h, 6Dh, 8Ah, 3Fh, 0F9h, 0C8h, 24h, 0C5h, 65h, 7Fh, 91h
            DB 95h, 36h, 10h, 0A7h, 66h, 50h, 0EFh, 0B5h, 0Eh, 53h, 0E0h, 8Eh, 45h, 0B0h, 76h, 0ABh
            DB 0FBh, 88h, 2Bh, 0F6h, 9Bh, 12h, 0A5h, 44h, 35h, 5Ah, 5Eh, 29h, 5Dh, 0A2h, 74h, 0D4h
            DB 0CDh, 19h, 0EBh, 0C1h, 4Ah, 3Ah, 0A9h, 0C7h, 11h, 0B4h, 31h, 93h, 5Ch, 9Eh, 0A0h, 4Bh
            DB 8Dh, 14h, 60h, 1Fh, 89h, 75h, 0BAh, 0Bh, 43h, 0E9h, 58h, 5Bh, 18h, 61h, 0EDh, 0F7h
            DB 56h, 0C3h, 0ECh, 27h, 0DDh, 57h, 0F0h, 0B2h, 28h, 0CEh, 0C2h, 1h, 0CFh, 47h, 96h, 72h
            DB 38h, 6Bh, 0F3h, 0B3h, 0A6h, 0B7h, 32h, 8Fh, 0FEh, 9Ah, 81h, 3Bh, 37h, 17h, 7h, 8h
            DB 6Ch, 97h, 16h, 8Bh, 0E4h, 0FDh, 0ADh, 1Ah, 0BCh, 23h, 0FFh, 3Eh, 46h, 0BDh, 6h, 39h
