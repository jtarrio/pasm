# PASM's assembly language

# Program structure and content

A program consists of several lines, each line optionally containing one statement, directive, or label definition.

Comments start with a semicolon character (`;`) and run to the end of the line.

## Data types

- Numbers: 8-bit or 16-bit numbers, positive or negative. Expressed in decimal by default, can be expressed in binary,
  octal, or hexadecimal with the `b`, `o`, or `h` suffixes. Hexadecimal numbers starting with a letter must be prefixed
  with a 0. Examples: `123`, `-32`, `1011b`, `0FFFFh`.
    - Bytes: represented as a number between -128 and 255.
    - Words: represented as a number between -32768 and 65535.
    - Double words: represented as a pair of words joined with a colon (`:`).
- Strings: sequences of bytes delimited by single quote characters (`'`). There is no escape character; if you need to
  specify a quote or another nonprintable character, express it as an 8-bit number joined to the string with a comma.
  Single-character strings can also stand for bytes in many places.

## Labels

Labels represent a 16-bit memory address. They are defined by specifying their name, followed by a data definition
directive (`DB`, `DW`, `DD`) or by a colon optionally followed by a statement.

Examples:

```
salutation DB 'Hello, world!'
start: MOV AH, 09h
destination:
```

In program code, the name of a label stands for its address, not for its content. You need to put the label in square
brackets when you want to access the label's content.

Examples:

```
MOV SI, salutation ; puts the address of "salutation" in SI
MOV AL, [SALUTATION] ; puts the first byte of 'Hello, world!' in AL
```

## Directives

### `ORG`

Sets the starting address of the program, or pads the program to the given address.

For example, DOS COM files start with the directive `ORG 100h` so that they are assembled starting at position 100h.

### `DB`, `DW`, `DD`

Data definition directives. They define bytes, words, and doublewords, respectively, that are output directly to the
assembled code. These directives are generally used to reserve space or provide data.

Examples:

```
DB 48, 49, 51, 128  ; outputs 4 bytes
DB 'Hello, world!'  ; outputs the content of the string
DB 'Hello, world!',13,10 ; outputs the content of the string followed by CR-LF
DW 0FFFFh, 1234     ; outputs 2 words
DD 0B800h:0000h     ; outputs a double word
```

### `DUP`

In data definition directives, the `DUP` directive outputs multiple copies of the same byte, word, doubleword, or
string.

Examples:

```
buffer DB 1024 DUP (0)  ; outputs 1024 zero bytes
```

### `EQU`

Defines a substitution. The identifier preceding the `EQU` directive will be replaced with the content following it.

Examples:

```
; whenever "size" appears in the code, it will be replaced with 1024
size EQU 1024
; define a buffer of size "size"
buffer DB size DUP (0)
; whenever "ADD_UP" appears in the code, it will be replaced with ADD AL, BL
ADD_UP EQU ADD AL, BL
    MOV AL, 40
    MOV CL, 50
    ADD_UP
    MOV CL, 127
    ADD_UP
```

## Pointers

Pointers are expressed as a pair of square brackets (`[`, `]`) that contain the addition of a base pointer, an index,
and an offset.

- The base pointer is the `BX` or `BP` register.
- The index is the `SI` or `DI` register.
- The offset is an immediate value, 8 or 16 bits long, or a label.

All three parts of the pointer are optional.

Examples: `[BP]`, `[SI]`, `[1234h]`, `[BX + SI]`, `[BP + DI]`, `[BP + 1234h]`, `[BP + SI + 1234h]`.

Pointers generally refer to the `DS` segment; pointers involving the `BP` register, however, refer to the `SS` segment.
It is possible to override the segment by prefixing the pointer with the segment name.

Examples: `ES:[SI]`, `CS:[1234h]`.

Pointers have a type: byte pointers point to a byte, word pointers point to a word, and dword pointers point to a dword.
Sometimes it's possible to determine the pointer's type from the code that accesses it or from the type of the label.
Other times, however, it is necessary to specify `BYTE PTR`, `WORD PTR`, or `DWORD PTR`.

# List of 8086 instructions

## Registers

* `AX`, `BX`, `CX`, `DX` (data registers)
    - Can be split into `AH`/`AL` (high and low bytes of `AX`), `BH`/`BL`, `CH`/`CL`, `DH`/`DL`.
* `SP`, `BP`, `SI`, `DI` (indices and pointers)
* `CS`, `DS`, `ES`, `SS` (segment registers)
* `IP`, flags (instruction pointer)

### Flags

* `CF` (bit 0): carry — set on carry or borrow; used by arithmetic instructions and rotate-with-carry instructions
* `PF` (bit 2): parity — set if the low byte of the result contains an even number of bits
* `AF` (bit 4): auxiliary — set on carry or borrow to the low 4 bits of `AL`; used by BCD instructions
* `ZF` (bit 6): zero — set if result is zero
* `SF` (bit 7): sign — set to the highest bit of the result (1 is negative)
* `TF` (bit 8): single step — when set, a single step interrupt occurs after the next instruction executes (cleared by
  the interrupt)
* `IF` (bit 9): interrupt enable — when set, interrupts transfer control to a location in the interrupt vector
* `DF` (bit 10): direction — when set, string instructions decrement the index register
* `OF` (bit 11): overflow — set when the signed result exceeds the number of bits in the destination

## Instructions (by type)

### Data transfer

* `MOV` (Move)
* `PUSH` (Push to stack)
* `POP` (Pop from stack)
* `XCHG` (Exchange)
* `IN` (Input from port)
* `OUT` (Output to port)
* `XLAT` (Translate byte in `AL` using lookup table)
* `LEA` (Load effective address)
* `LDS` (Load to `DS`)
* `LES` (Load to `ES`)
* `LAHF` (Load flags to `AH`)
* `SAHF` (Store `AH` into flags)
* `PUSHF` (Push flags)
* `POPF` (Pop flags)

### Arithmetic

* `ADD` (Add)
* `ADC` (Add with carry)
* `INC` (Increment)
* `AAA` (ASCII adjust for add)
* `DAA` (Decimal adjust for add)
* `SUB` (Subtract)
* `SBB` (Subtract with borrow)
* `DEC` (Decrement)
* `NEG` (Change sign)
* `CMP` (Compare)
* `AAS` (ASCII adjust for subtract)
* `DAS` (Decimal adjust for subtract)
* `MUL` (Multiply unsigned)
* `IMUL` (Multiply signed)
* `AAM` (ASCII adjust for multiply)
* `DIV` (Divide unsigned)
* `IDIV` (Divide signed)
* `AAD` (ASCII adjust for divide)
* `CBW` (Convert byte to word)
* `CWD` (Convert word to doubleword)

### Logic

* `NOT` (Bitwise negate)
* `SAL`/`SHL` (Shift arithmetic/logical left)
* `SAR` (Shift arithmetic right)
* `SHR` (Shift logical right)
* `ROL` (Rotate left)
* `ROR` (Rotate right)
* `RCL` (Rotate through carry left)
* `RCR` (Rotate through carry right)
* `AND` (Bitwise and)
* `TEST` (Bitwise and, do not store result, alter flags only)
* `OR` (Bitwise or)
* `XOR` (Bitwise exclusive or)

### String manipulation

* `REP` (Repeat)
* `MOVSB`/`MOVSW` (Move byte/word)
* `CMPSB`/`CMPSW` (Compare byte/word)
* `SCASB`/`SCASW` (Scan byte/word)
* `LODSB`/`LODSW` (Load byte/word to `AL`/`AX`)
* `STOSB`/`STOSW` (Store byte/word from `AL`/`AX`)

### Flow control

* `CALL` (Call subroutine)
* `JMP` (Unconditional jump)
* `RET` (Return from call)
* `JE`/`JZ` (Jump on equal/zero)
* `JNE`/`JNZ` (Jump on not equal/not zero)
* `JL`/`JNGE` (Jump on lower/not greater or equal)
* `JLE`/`JNG` (Jump on lower or equal/not greater)
* `JG`/`JNLE` (Jump on greater/not lower or equal)
* `JGE`/`JNL` (Jump on greater or equal/not lower)
* `JB`/`JNAE`/`JC` (Jump on below/not above or equal/carry)
* `JBE`/`JNA` (Jump on below or equal/not above)
* `JA`/`JNBE` (Jump on above/not below or equal)
* `JAE`/`JNB`/`JNC` (Jump on above or equal/not below/not carry)
* `JO` (Jump on overflow)
* `JNO` (Jump on not overflow)
* `JS` (Jump on sign)
* `JNS` (Jump on not sign)
* `JP`/`JPE` (Jump on parity/parity even)
* `JNP`/`JPO` (Jump on not parityparity odd/not parity)
* `LOOP` (Loop `CX` times)
* `LOOPZ`/`LOOPE` (Loop while zero/equal)
* `LOOPNZ`/`LOOPNE` (Loop while not zero/not equal)
* `JCXZ` (Jump on `CX` is zero)
* `INT` (Interrupt)
* `INTO` (Interrupt on overflow)
* `IRET` (Return from interrupt)

### Processor control

* `CLC` (Clear carry)
* `CMC` (Complement carry)
* `STC` (Set carry)
* `CLD` (Clear direction)
* `STD` (Set direction)
* `CLI` (Clear interrupt)
* `STI` (Set interrupt)
* `HLT` (Halt)
* `WAIT` (Wait)
* `ESC` (Escape to coprocessor)
* `LOCK` (Bus lock prefix)

## Instructions (alphabetical)

### `AAA` (ASCII adjust for add)

Adjusts `AL` after adding two unpacked BCD values (most significant digit in `AH` and least significant digit in `AL`)
so that `AL` contains a valid unpacked BCD digit.

Its higher 4 bits are cleared, and if its lower 4 bits contain a value higher than 9 or `AF` is set, it is rolled over
modulo 10, `AH` is incremented, and `CF` and `AF` are set; otherwise they are cleared.

Flags: `AC`.

### `AAD` (ASCII adjust for divide)

Adjusts `AL` before dividing two unpacked BCD values (most significant digit in `AH` and least significant digit in
`AL`) so that the result is a valid unpacked BCD value.

The instruction multiplies `AH` by 10 and adds it to `AL`, and clears `AH`. After dividing the result by an unpacked BCD
value, the quotient is returned in `AL` and the remainder in `AH`.

Flags: `PSZ`.

### `AAM` (ASCII adjust for multiply)

Adjusts `AX` after multiplying two unpacked BCD values (most significant digit in `AH` and least significant digit in
`AL`) so that the result is a valid unpacked BCD value.

The instruction divides `AL` by 10 and stores the quotient in `AH` and the remainder in `AL`.

### `AAS` (ASCII adjust for subtract)

Adjusts `AL` after subtracting two unpacked BCD values (most significant digit in `AH` and least significant digit in
`AL`) so that `AL` contains a valid unpacked BCD digit.

Its higher 4 bits are cleared, and if its lower 4 bits contain a value higher than 9 or `AF` is set, it is rolled under
modulo 10, `AH` is decremented, and `CF` and `AF` are set; otherwise they are cleared.

Flags: `AC`.

### `ADC` (Add with carry)

Sums the operands, adds 1 to the result if `CF` is set, and stores the result in the destination operand.

Flags: `ACOPSZ`

### `ADD` (Add)

Sums the operands and stores the result in the destination operand.

Flags: `ACOPSZ`

### `AND` (Bitwise and)

Performs a bitwise "and" on the operands and stores the result in the destination operand. Clears `CF` and `OF`.

Flags: `COPSZ`

### `CALL` (Call subroutine)

Jumps into a subroutine, saving a return pointer in the stack so that a `RET` instruction can return the execution to
the caller.

For a "direct in segment" call, it pushes the value of `IP` to the stack, then adds the signed IP offset to `IP` and
stores the result in `IP`.

For an "indirect in segment call", it pushes the value of `IP` to the stack, and then retrieves the content of the
register or memory position and stores it in `IP`.

For a "direct to another segment" call, it pushes the value of `CS` to the stack, stores the value of the segment word
from the instruction in `CS`, then pushes the value of `IP` to the stack and stores the value of the address word in
`IP`.

For an "indirect to another segment" call, it pushes the value of `CS` to the stack, stores the value of the second word
of the doubleword stored in the provided memory position in `CS`, then pushes the value of `IP` to the stack and stores
the value of the first word in `IP`.

Flags: none.

### `CBW` (Convert byte to word)

Extends the sign of `AL` into `AH`. If the highest bit of `AL` is 0, it stores 0 in `AH`; otherwise, it stores 255.

Flags: none.

### `CLC` (Clear carry)

Sets `CF` to zero.

Flags: `C`

### `CLD` (Clear direction)

Sets `DF` to zero. `SI` and `DI` will autoincrement in string operations.

Flags: `D`

### `CLI` (Clear interrupt)

Sets `IF` to zero, disabling maskable hardware interrupts.

Flags: `I`

### `CMC` (Complement carry)

Toggles `CF` to the opposite state.

Flags: `C`

### `CMP` (Compare)

Subtracts the source operand from the destination operand, but does not store the result; it only modifies the flags,
which reflect a comparison from the destination to the source (so `JG` jumps if the destination is greater than the
source.)

Flags: `ACOPSZ`

### `CMPSB` (Compare byte)

Subtracts the destination byte from the source byte without storing the results; it only modifies the flags, which
reflect a comparison from the destination to the source (so `JG` jumps if the destination is greater than the source.)
The destination is addressed by `DI`, while the source is addressed by `SI`.

After the comparison, both registers are incremented or decremented by 1 depending on the value of `DF`.

If the instruction is prefixed by `REPE`/`REPZ`, it is repeated while `CX` is not zero and the strings are equal (`ZF`
is set). If the instruction is prefixed by `REPNE`/`REPNZ`, it is repeated while `CX` is not zero and the strings are
not equal (`ZF` is not set.)

Flags: `ACOPSZ`

### `CMPSW` (Compare word)

Subtracts the destination word from the source word without storing the results; it only modifies the flags, which
reflect a comparison from the destination to the source (so `JG` jumps if the destination is greater than the source.)
The destination is addressed by `DI`, while the source is addressed by `SI`.

After the comparison, both registers are incremented or decremented by 2 depending on the value of `DF`.

If the instruction is prefixed by `REPE`/`REPZ`, it is repeated while `CX` is not zero and the strings are equal (`ZF`
is set). If the instruction is prefixed by `REPNE`/`REPNZ`, it is repeated while `CX` is not zero and the strings are
not equal (`ZF` is not set.)

Flags: `ACOPSZ`

### `CWD` (Convert word to doubleword)

Extends the sign of `AX` into `DX`. If the highest bit of `AX` is 0, it stores 0 in `DX`; otherwise, it stores 65535.

Flags: none.

### `DAA` (Decimal adjust for add)

Adjusts `AL` after adding two packed BCD values (most significant digit in the high 4 bits and least significant digit
in the low 4 bits) so that `AL` contains a valid packed BCD value.

If its lower 4 bits contain a value higher than 9 or `AF` is set, they are rolled over modulo 10, the higher 4 bits are
incremented, and `AF` is set; otherwise it is cleared. Then, if the higher 4 bits contain a value higher than 9 or `CF`
is set, they are rolled over modulo 10 and `CF` is set; otherwise it is cleared.

Flags: `ACPSZ`.

### `DAS` (Decimal adjust for subtract)

Adjusts `AL` after subtracting two packed BCD values (most significant digit in the high 4 bits and least significant
digit in the low 4 bits) so that `AL` contains a valid packed BCD value.

If its lower 4 bits contain a value higher than 9 or `AF` is set, they are rolled under modulo 10 and `AF` is set;
otherwise it is cleared. Then, if the higher 4 bits contain a value higher than 9 or `CF` is set, they are rolled under
modulo 10 and `CF` is set; otherwise it is cleared.

Flags: `ACPSZ`.

### `DEC` (Decrement)

Subtracts 1 from the destination operand, which is treated as an unsigned byte or word.

Flags: `AOPSZ`.

### `DIV` (Divide unsigned)

If the source operand is a byte, divides `AX` by the source operand, placing the quotient in `AL` and the remainder in
`AH`. The maximum quotient is 255.

If the source operand is a word, divides `DX:AX` by the source operand, placing the quotient in `AX` and the remainder
in `DX`. The maximum quotient is 65535.

If the quotient falls outside the valid range or a division by zero is attempted, an `INT 0` is generated.

Non-integral quotients are truncated towards zero.

Flags: none.

### `ESC` (Escape to coprocessor)

This instruction is used for coprocessors. The 8086 loads the memory address specified in it so the coprocessor can use
it, and then does nothing.

### `HLT` (Halt)

Stops the CPU until it is reset, a non-maskable interrupt is received, or a maskable interrupt is received when `IF` is
set.

### `IDIV` (Divide signed)

If the source operand is a byte, does a signed division of `AX` by the source operand, placing the quotient in `AL` and
the remainder in `AH`. The maximum quotient is +127 and the minimum is -127.

If the source operand is a word, does a signed division of `DX:AX` by the source operand, placing the quotient in `AX`
and the remainder in `DX`. The maximum quotient is +32767 and the minimum is -32767.

If the quotient falls outside the valid range or a division by zero is attempted, an `INT 0` is generated.

Non-integral quotients are truncated towards zero. The remainder has the same sign as the quotient.

Flags: none.

### `IMUL` (Multiply signed)

If the source operand is a byte, does a signed multiplication of `AL` and the source operand, placing the result in
`AX`. If `AH` contains significant digits (anything other than the sign extension of `AL`), `CF` and `OF` are set;
otherwise they are cleared.

If the source operand is a word, does a signed multiplication of `AX` and the source operand, placing the result in
`DX:AX`. If `DX` contains significant digits (anything other than the sign extension of `AX`), `CF` and `OF` are set;
otherwise they are cleared.

Flags: `CO`

### `IN` (Input from port)

Transfers a byte or word from an input port to `AL` or `AX`. The port number can be an immediate between 0 and 255, or
the content of `DX` between 0 and 65535.

Flags: none.

### `INC` (Increment)

Adds 1 to the destination operand, which is treated as an unsigned byte or word.

Flags: `AOPSZ`.

### `INT` (Interrupt)

Calls the interrupt procedure specified by the immediate argument.

The addresses of the interrupt procedures are stored in the interrupt vector. Each element of the interrupt vector
contains two words: the first word is the offset, and the second word is the segment. The address of each element is
calculated by multiplying the interrupt type by 4.

The instruction pushes the flags to the stack and clears `TF` and `IF`. Then it pushes `CS` to the stack and stores the
interrupt procedure's segment in `CS`. Then it pushes `IP` to the stack and stores the interrupt procedure's offset in
`IP`.

`INT 3`, used as a breakpoint, can be encoded in a single byte.

Flags: `IT`.

### `INTO` (Interrupt on overflow)

If `OF` is set, it generates an `INT 4`; otherwise, it does nothing.

Flags: `IT`.

### `IRET` (Return from interrupt)

Jumps back from an interrupt procedure by popping `IP`, `CS`, and the flags from the stack.

Flags: all.

### `JA`/`JNBE` (Jump on above/not below or equal)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `CF` and `ZF` are unset.

Flags: none.

### `JAE`/`JNB`/`JNC` (Jump on above or equal/not below)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `CF` is unset.

Flags: none.

### `JB`/`JNAE`/`JC` (Jump on below/not above or equal/carry)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `CF` is set.

Flags: none.

### `JBE`/`JNA` (Jump on below or equal/not above)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `CF` or `ZF` are set.

Flags: none.

### `JCXZ` (Jump if `CX` is zero)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `CX` is zero.

Flags: none.

### `JE`/`JZ` (Jump on equal/zero)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `ZF` is set.

Flags: none.

### `JG`/`JNLE` (Jump on greater/not lower or equal)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `SF` is equal to `OF` or `ZF` is unset.

Flags: none.

### `JGE`/`JNL` (Jump on greater or equal/not lower)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `SF` is equal to `OF`.

Flags: none.

### `JL`/`JNGE` (Jump on lower/not greater or equal)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `SF` is different from `OF`.

Flags: none.

### `JLE`/`JNG` (Jump on lower or equal/not greater)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `SF` is different from `OF` or `ZF` is
set.

Flags: none.

### `JMP` (Unconditional jump)

Jumps to the destination.

For a "short" or "direct in segment" jump, it adds the signed IP offset to `IP` and stores the result in `IP`.

For an "indirect in segment call", retrieves the content of the register or memory position and stores it in `IP`.

For a "direct to another segment" call, it stores the value of the segment word from the instruction in `CS`, then
stores the value of the address word in `IP`.

For an "indirect to another segment" call, it stores the value of the second word of the doubleword stored in the
provided memory position in `CS`, then stores the value of the first word in `IP`.

Flags: none.

### `JNE`/`JNZ` (Jump on not equal/not zero)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `ZF` is unset.

Flags: none.

### `JNO` (Jump on not overflow)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `OF` is unset.

Flags: none.

### `JNP`/`JPO` (Jump on not parity/parity odd)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `PF` is unset.

Flags: none.

### `JNS` (Jump on not sign)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `SF` is unset.

Flags: none.

### `JO` (Jump on overflow)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `OF` is set.

Flags: none.

### `JP`/`JPE` (Jump on parity/parity even)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `PF` is set.

Flags: none.

### `JS` (Jump on sign)

Conditionally jumps to the destination, adding the signed IP offset to `IP` if `SF` is set.

Flags: none.

### `LAHF` (Load flags to `AH`)

Copies flags `SF`, `ZF`, `AF`, `PF`, and `CF` to bits 7, 6, 4, 2, and 0 of `AH`.

Flags: none.

### `LDS` (Load using `DS`)

Stores the effective address pointed to by the source operand. The segment is stored in `DS`, and the offset is stored
in the destination operand.

The source operand must be a memory operand and the destination operand must be a 16-bit register.

Flags: none.

### `LEA` (Load effective address)

Stores the offset of the effective address pointed to by the source operand into the destination operand.

The source operand must be a memory operand and the destination operand must be a 16-bit register.

Flags: none.

### `LES` (Load using `ES`)

Stores the effective address pointed to by the source operand. The segment is stored in `ES`, and the offset is stored
in the destination operand.

The source operand must be a memory operand and the destination operand must be a 16-bit register.

Flags: none.

### `LOCK` (Bus lock prefix)

Makes the 8088 lock the bus while the next instruction executes.

Flags: none.

### `LODSB` (Load byte to `AL`)

Loads the byte addressed by `SI` to register `AL`, and increments or decrements `SI` by 1 depending on the value of
`DF`.

Flags: none.

### `LODSW` (Load word to `AX`)

Loads the word addressed by `SI` to register `AX`, and increments or decrements `SI` by 2 depending on the value of
`DF`.

Flags: none.

### `LOOP` (Loop `CX` times)

Decrements `CX` by 1 and jumps to the destination if `CX` is not zero.

Flags: none.

### `LOOPE`/`LOOPZ` (Loop while equal/zero)

Decrements `CX` by 1 and jumps to the destination if `CX` is not zero and `ZF` is set.

Flags: none.

### `LOOPNE`/`LOOPNZ` (Loop while not equal/not zero)

Decrements `CX` by 1 and jumps to the destination if `CX` is not zero and `ZF` is unset.

Flags: none.

### `MOV` (Move)

Copies a byte or word from the source operand to the destination operand.

Flags: none.

### `MOVSB` (Move byte)

Copies a byte from the source (addressed by `SI`) to the destination (addressed by `DI`).

After copying, both registers are incremented or decremented by 1 depending on the value of `DF`.

If the instruction is prefixed by `REP`, it is repeated while `CX` is not zero.

Flags: none.

### `MOVSW` (Move word)

Copies a word from the source (addressed by `SI`) to the destination (addressed by `DI`).

After copying, both registers are incremented or decremented by 2 depending on the value of `DF`.

If the instruction is prefixed by `REP`, it is repeated while `CX` is not zero.

Flags: none.

### `MUL` (Multiply unsigned)

If the source operand is a byte, does an unsigned multiplication of `AL` and the source operand, placing the result in
`AX`. If `AH` contains significant digits (non-zero), `CF` and `OF` are set; otherwise they are cleared.

If the source operand is a word, does an unsigned multiplication of `AX` and the source operand, placing the result in
`DX:AX`. If `DX` contains significant digits (non-zero), `CF` and `OF` are set; otherwise they are cleared.

Flags: `CO`

### `NEG` (Change sign)

Computes the two's complement of the byte or word operand and stores it back.

Clears `CF` when the operand is zero; otherwise it sets it.

Flags: `ACOPSZ`

### `NOP` (No operation)

Does nothing.

### `NOT` (Bitwise negate)

Inverts all the bits of the byte of word operand and stores it back.

Flags: none.

### `OR` (Bitwise or)

Performs a bitwise "or" on the operands and stores the result in the destination operand. Clears `CF` and `OF`.

Flags: `COPSZ`

### `OUT` (Output to port)

Transfers a byte or word from `AL` or `AX` to an output port. The port number can be an immediate between 0 and 255, or
the content of `DX` between 0 and 65535.

Flags: none.

### `POP` (Pop from stack)

Pops a word from the stack. It copies the word addressed by `SP` to the destination operand and then adds 2 to `SP` so
it will point to the new top of the stack.

Flags: none.

### `POPF` (Pop flags)

Pops the flags from the stack. It copies the word addressed by `SP` to the flags register and then adds 2 to `SP` so it
will point to the new top of the stack.

Flags: none.

### `PUSH` (Push to stack)

Pushes a word to the stack. It subtracts 2 from `SP` so it will point to the new top of the stack, and then stores the
destination operand in the word addressed by `SP`.

Flags: none.

### `PUSHF` (Push flags)

Pushes the flags to the stack. It subtracts 2 from `SP` so it will point to the new top of the stack, and then stores
the flags register in the word addressed by `SP`.

Flags: none.

### `RCL` (Rotate through carry left)

Rotates the bits from the byte or word destination operand by shifting it left by the number of bits specified in the
count operand. `CF` is used as an additional bit in the rotation: its value is shifted onto the low bit, and the high
bit is shifted onto `CF`.

If the count is 1, `OF` is set if the high order bit after rotation and `CF` are different; it is cleared otherwise.

Flags: `CO`

### `RCR` (Rotate through carry right)

Rotates the bits from the byte or word destination operand by shifting it right by the number of bits specified in the
count operand. `CF` is used as an additional bit in the rotation: its value is shifted onto the high bit, and the low
bit is shifted onto `CF`.

If the count is 1, `OF` is set if the two highest order bits after rotation are different; it is cleared otherwise.

Flags: `CO`

### `REP`/`REPE`/`REPZ` (Repeat/repeat while equal/repeat while zero)

If the next instruction is `MOVS` or `STOS`, it repeats the next instruction while `CX` is not zero.

If the next instruction is `CMPS` or `SCAS`, it repeats the next instruction while `CX` is not zero and `ZF` is set.

### `REPNE`/`REPNZ` (Repeat while not equal/while not zero)

If the next instruction is `MOVS` or `STOS`, it repeats the next instruction while `CX` is not zero.

If the next instruction is `CMPS` or `SCAS`, it repeats the next instruction while `CX` is not zero and `ZF` is unset.

### `RET` (Return from call)

Jumps back from subroutine.

For an "in segment" return, it pops `IP` from the stack.

For a return to another segment, it pops `IP` and then `CS`.

For the "add immediate" variants, it additionally adds the specified immediate to `SP`, as if it were popping additional
values.

Flags: all.

### `ROL` (Rotate left)

Rotates the bits from the byte or word destination operand by shifting it left by the number of bits specified in the
count operand. `CF` is affected by the rotation: it contains the value of the bit that was rotated from the high bit to
the low bit.

If the count is 1, `OF` is set if the high order bit after rotation and `CF` are different; it is cleared otherwise.

Flags: `CO`

### `ROR` (Rotate right)

Rotates the bits from the byte or word destination operand by shifting it right by the number of bits specified in the
count operand. `CF` is affected by the rotation: it contains the value of the bit that was rotated from the low bit to
the high bit.

If the count is 1, `OF` is set if the two highest order bits after rotation are different; it is cleared otherwise.

Flags: `CO`

### `SAHF` (Store `AH` into flags)

Copies bits 7, 6, 4, 2, and 0 of `AH` to flags `SF`, `ZF`, `AF`, `PF`, and `CF`.

Flags: `ACPSZ`.

### `SAL`/`SHL` (Shift arithmetic/logical left)

Shifts left the bits from the byte or word destination by the number of bits specified in the count operand. `CF` is
affected by the shift: it contains the value of the high bit before the shift.

If the count is 1, `OF` is set if the high order bit after rotation and `CF` are different; it is cleared otherwise.

Flags: `COPSZ`

### `SAR` (Shift arithmetic right)

Shifts right the bits from the byte or word destination by the number of bits specified in the count operand, retaining
the high bit to preserve its sign. `CF` is affected by the shift: it contains the value of the low bit before the shift.

If the count is 1, `OF` is set if the two highest order bits after rotation are different; it is cleared otherwise.

Flags: `COPSZ`

### `SBB` (Subtract with borrow)

Subtracts the source operand from the destination operand, subtracts 1 from the result if `CF` is set, and stores the
result in the destination operand.

Flags: `ACOPSZ`

### `SCASB` (Scan byte)

Subtracts the destination byte (addressed by `DI`) from `AL` without storing the results; it only modifies the flags.

After the comparison, `DI` is incremented or decremented by 1 depending on the value of `DF`.

If the instruction is prefixed by `REPE`/`REPZ`, it is repeated while `CX` is not zero and the strings are equal (`ZF`
is set). If the instruction is prefixed by `REPNE`/`REPNZ`, it is repeated while `CX` is not zero and the strings are
not equal (`ZF` is not set.)

Flags: `ACOPSZ`

### `SCASW` (Scan word)

Subtracts the destination word (addressed by `DI`) from `AX` without storing the results; it only modifies the flags.

After the comparison, `DI` is incremented or decremented by 2 depending on the value of `DF`.

If the instruction is prefixed by `REPE`/`REPZ`, it is repeated while `CX` is not zero and the strings are equal (`ZF`
is set). If the instruction is prefixed by `REPNE`/`REPNZ`, it is repeated while `CX` is not zero and the strings are
not equal (`ZF` is not set.)

Flags: `ACOPSZ`

### `SHR` (Shift logical right)

Shifts right the bits from the byte or word destination by the number of bits specified in the count operand, shifting
zeros onto the high bit. `CF` is affected by the shift: it contains the value of the low bit before the shift.

If the count is 1, `OF` is set if the two highest order bits after rotation are different; it is cleared otherwise.

Flags: `COPSZ`

### `STC` (Set carry)

Sets `CF` to one.

Flags: `C`

### `STD` (Set direction)

Sets `DF` to one. `SI` and `DI` will autodecrement in string operations.

Flags: `D`

### `STI` (Set interrupt)

Sets `IF` to one, enabling maskable hardware interrupts.

Flags: `I`

### `STOSB` (Store byte from `AL`)

Stores a byte or word in register `AL` in the address specified by `DI`, and increments or decrements `DI` by 1
depending on the value of `DF`.

Flags: none.

### `STOSW` (Store word from `AX`)

Stores a byte or word in register `AX` in the address specified by `DI`, and increments or decrements `DI` by 2
depending on the value of `DF`.

Flags: none.

### `SUB` (Subtract)

Subtracts the source operand from the destination operand and stores the result in the destination operand.

Flags: `ACOPSZ`

### `TEST` (Bitwise and, do not store result, alter flags only)

Performs a bitwise "and" on the operands, but does not store the result; it only modifies the flags. Clears `CF` and
`OF`.

Flags: `COPSZ`

### `WAIT` (Wait)

Waits until the CPU's TEST line becomes active. Generally used to wait for floating-point operations.

### `XCHG` (Exchange)

Switches the content of the byte or word operands. Used with `LOCK`, it can be used as a semaphore in multiprocessor
environments.

### `XLAT` (Translate byte in `AL` using lookup table)

Indexes `AL` into a 256-byte look-up table addressed by `BX` and stores the result in `AL`.

### `XOR` (Bitwise exclusive or)

Performs a bitwise "exclusive or" on the operands and stores the result in the destination operand. Clears `CF` and
`OF`.

Flags: `COPSZ`

