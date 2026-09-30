# PASM Grammar

This document describes the grammar used by PASM. I will try to keep it up to date, but it may fall out of sync.

## Tokens

* The characters `[` (left bracket), `]` (right bracket), `(` (left parenthesis), `)` (right parenthesis), `+` (plus
  sign), `-` (minus sign), `,` (comma), and `:` (colon).
* _register_: the name of a register: `AX`, `BX`, `CX`, `DX`, `AL`, `BL`, `CL`, `DL`, `AH`, `BH`, `CH`, `DH`, `SI`,
  `DI`, `BP`,
  and `SP`.
* _segment_: the name of a segment: `CS`, `DS`, `ES`, `SS`.
* The following reserved keywords:
    * `DUP`, `EQU`, `ORG`
    * `BYTE`, `WORD`, `DWORD`, `SHORT`, `NEAR`, `FAR`, `PTR`
    * `DB`, `DW`, `DD`
* _prefix_: any of the following reserved keywords:
    * `LOCK`, `REP`, `REPE`, `REPZ`, `REPNE`, `REPNZ`
* _instruction_: any of the following reserved keywords:
    * `AAA`, `AAD`, `AAM`, `AAS`, `ADC`, `ADD`, `AND`, `CALL`, `CBW`, `CLC`, `CLD`, `CLI`, `CMC`, `CMP`, `CMPSB`,
      `CMPSW`, `CWD`
    * `DAA`, `DAS`, `DEC`, `DIV`, `ESC`, `HLT`, `IDIV`, `IMUL`, `IN`, `INC`, `INT`, `INTO`, `IRET`
    * `JA`, `JAE`, `JB`, `JBE`, `JC`, `JCXZ`, `JE`, `JG`, `JGE`, `JL`, `JLE`, `JMP`, `JO`, `JP`, `JPE`, `JPO`, `JS`,
      `JZ`
    * `JNA`, `JNAE`, `JNB`, `JNBE`, `JNC`, `JNE`, `JNG`, `JNGE`, `JNL`, `JNLE`, `JNO`, `JNP`, `JNS`, `JNZ`
    * `LAHF`, `LDS`, `LEA`, `LES`, `LODSB`, `LODSW`, `LOOP`, `LOOPE`, `LOOPNE`, `LOOPNZ`, `LOOPZ`
    * `MOV`, `MOVSB`, `MOVSW`, `MUL`, `NEG`, `NOP`, `NOT`, `OR`, `OUT`, `POP`, `POPF`, `PUSH`, `PUSHF`
    * `RCL`, `RCR`, `RET`, `RETF`, `RETN`, `ROL`, `ROR`
    * `SAHF`, `SAL`, `SAR`, `SBB`, `SCASB`, `SCASW`, `SHL`, `SHR`, `STC`, `STD`, `STI`, `STOSB`, `STOSW`, `SUB`
    * `TEST`, `WAIT`, `XCHG`, `XLAT`, `XOR`.
* _identifier_: any sequence of characters in the ranges `A`-`Z`, `0`-`9` or `_` (underscore) starting with a character
  in the range `A`-`Z` or `_` that is not a reserved keyword. Examples: `START`, `LOOP_3`, `_CHECK`.
* _number_: any 8 or 16-bit number in one of these forms:
    * a decimal number represented as a sequence of characters in the range `0`-`9`, optionally followed by a `D`.
      Examples: `0`, `172`, `42D`.
    * a hexadecimal number represented as a character in the range `0`-`9` followed by characters in the ranges `0`-`9`
      or `A`-`F`, followed by an `H`. Examples: `7H`, `3AH`, `0FFH`.
    * an octal number represented as a sequence of characters in the range `0`-`7` followed by an `O` (letter O).
      Example: `177O`.
    * a binary number represented as a sequence of `0` and `1` characters followed by a `B`. Examples: `100101B`,
      `01011010B`.
* _string_: a `'` character (single quote) followed by up to 255 printable ASCII characters (except `'`), followed by a
  closing `'`. Examples: `'Hello!'`, `''` (empty string).

All characters in tokens (except strings) are converted to upper case during parsing, so they are case insensitive.
Examples: `byte` is recognized as the keyword `BYTE`, `3Fh` is recognized as the hexadecimal number `3FH`, and the
identifiers `Start` and `START` are the same.

## Source file

A source file contains a sequence of lines. Each line may contain a directive, a labeled statement, or a statement,
or may be empty. A line may also end in a comment. A comment starts with the `;` character and runs to the end of the
line. Comments are ignored by PASM, but they are useful to document the purpose of a line or block of code. Whitespace
at the beginning and end of a line is also ignored.

Example:

```
; COM files start at position 100h
ORG 100h

    JMP start   ; Skip to the program
salutation DB 'Hello, world!$'
start:
    MOV AH, 9   ; Print a string to the screen
    MOV DX, salutation
    INT 21h
    INT 20h     ; Exit
```

* source := [line ...] ;

A line may contain an `ORG` directive, a labeled statement, or a statement.

* line := org_directive | labeled_statement | statement ;

An `ORG` directive consists of the `ORG` keyword followed by a 16-bit number.

* org_directive := `ORG` _number_ ;

A labeled statement consists of an `EQU` definition, a label definition, or a labeled data definition.

* labeled_statement := equ_definition | label_definition | labeled_data_definition ;

An `EQU` definition consists of an identifier followed by the `EQU` keyword and a sequence of tokens.

* equ_definition := identifier `EQU` [token ...] ;

A label definition consists of an identifier followed by a colon, optionally followed by a statement.

* label_definition := identifier `:` [ statement ] ;

A labeled data definition consists of an identifier followed by a data statement (with no colon in between.)

* labeled_data_definition := identifier data_statement ;

A data statement consists of a `DB` keyword followed by a byte sequence, a `DW` keyword followed by a word sequence, or
a `DD` keyword followed by a doubleword sequence.

* data_statement := db_statement | dw_statement | dd_statement ;
* db_statement := `DB` byte_sequence ;
* dw_statement := `DW` word_sequence ;
* dd_statement := `DD` dword_sequence ;

A byte sequence consists of a sequence of byte elements joined with commas. A byte element consists of a string, a
numeric expression that resolves to an 8-bit number, or a duplicated byte element.

* byte_sequence := byte_element [ `,` byte_element ...] ;
* byte_element := _string_ | byte | numeric_expression `DUP` `(` byte_element `)` ;
* byte := numeric_expression ;

A word sequence consists of a sequence of word elements joined with commas. A word element consists of a 2-character
string, a numeric expression, or a duplicated word element.

* word_sequence := word_element [ `,` word_element ...] ;
* word_element := _string_ | word | numeric_expression `DUP` `(` word_element `)` ;
* word := numeric_expression ;

A doubleword sequence consists of a sequence of doubleword elements joined with commas. A doubleword element consists of
a 4-character string, two words joined with a colon (`:`), or a duplicated doubleword element.

* dword_sequence := dword_element [ `,` dword_element ...] ;
* dword_element := _string_ | dword | numeric_expression `DUP` `(` dword_element `)` ;
* dword := word `:` word ;

A statement consists of a prefix, an instruction, or a prefix followed by an instruction.

* statement := _prefix_ | instruction | _prefix_ instruction ;

An instruction is a data statement (described above) or an instruction keyword followed by zero arguments, one qualified argument,
or two arguments joined with a comma (`,`).

* instruction := data_statement | _instruction_ [ qualified_argument ] | _instruction_ argument `,` argument ;

A qualified argument consists of one of the optional distance qualifiers followed by an argument.

* qualified_argument := [ distance_qualifier ] argument ;
* distance_qualifier := `SHORT` | `NEAR` | `FAR` ;

An argument is a register argument, a segment argument, a numeric argument, a string argument, or a qualified pointer argument.

* argument := register_argument | segment_argument | numeric_argument | string_argument | qualified_pointer_argument ;

A register argument consists of the name of one of the registers.

* register_argument := _register_ ;

A segment argument consists of the name of one of the segments.

* segment_argument := _segment_ ;

A numeric argument consists of a numeric expression or two numeric expressions joined by a colon (`:`).

* numeric_argument := numeric_expression | numeric_expression `:` numeric_expression ;

A numeric expression consists of a sequence of single numbers joined with plus (`+`) or minus (`-`) signs.

* numeric_expression := single_number | numeric_expression `+` single_number | numeric_expression `-` single_number ;

A single number consists of an optional minus sign (`-`) or plus sign (`+`) followed by a label name or a number.

* single_number := [ `-` | `+` ] identifier | [ `-` | `+` ] number ;

A string argument consists of a string token. A single-character string is treated as a 8-bit number representing the character's ASCII value.

* string_argument := _string_ ;

A qualified pointer argument consists of an optional size qualifier followed by a pointer argument.

* qualified_pointer_argument := [ size_qualifier ] pointer_argument ;
* size_qualifier := `BYTE` `PTR` | `WORD` `PTR` | `DWORD` `PTR` ;

A pointer argument consists of an optional segment override followed by a bare pointer.

* pointer_argument := [ segment_override ] bare_pointer ;

The segment override is the name of a segment followed by a colon.

* segment_override := _segment_ `:` ;

The bare pointer consists of an effective address between brackets.

* bare_pointer := `[` effective_address `]` ;

The effective address consists of an expression containing a base register, an index register, and an offset; all
optional. The base register and index register must be added; the offset may be added or subtracted.

* effective_address := base_register |
    index_register |
    offset |
    base_register `+` index_register |
    base_register { `+` | `-` } offset |
    index_register { `+` | `-` } offset |
    base_register `+` index_register { `+` | `-` } offset ; /* and all other combinations */
* base_register := `BX` | `BP` ;
* index_register := `SI` | `DI` ;
* offset := numeric_expression ;

