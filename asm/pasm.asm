ORG 100h

version EQU '0.1'

; Locations of the input and output buffers.
; We do this because we don't have the ? value for DB.
bufsize EQU 1024
input_buffer EQU END_OF_CODE
output_buffer EQU input_buffer + bufsize

JMP main
