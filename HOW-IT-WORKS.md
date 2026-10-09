# How PASM works

PASM is an assembler for the Intel 8086/8088 microprocessor that runs on DOS. It is written in assembly, and in fact
it can assemble itself.

This document explains how PASM was built and how it works. Hopefully it will help someone learn how to build their
own assemblers and language compilers.

## Bootstrapping

PASM was written in the assembly language; specifically, in the assembly language recognized by PASM, which is similar
but not entirely compatible with MASM, TASM, NASM, and other assemblers.

So how do I manage to build PASM? The answer is, "bootstrapping".

I also built a version of PASM in the Go programming language (the "bootstrap assembler"). For PASM, this bootstrap
assembler is a complete reimplementation of PASM. (But this is not strictly necessary: quite often, the bootstrap
compiler/assembler is just sufficient to compile the real compiler.)

When I want to build PASM from scratch, first I assemble it with the bootstrap assembler, and the result is the
"self-hosted assembler": a version of PASM that was built from the correct source code. However, it was built with the
"wrong" compiler, so PASM needs to be built once more, using the self-hosted assembler. The result is the "native
assembler".

In practical terms, you bootstrap PASM by first executing this:

```shell
go run ./go/cmd/pasm asm/pasm.asm pasmboot.com
```

This uses the bootstrap assembler and yields `pasmboot.com`, the self-hosted assembler.

Then you can copy `pasmboot.com` and all the source code to a DOS machine (or use an emulator) and execute this:

```shell
PASMBOOT ASM\PASM.ASM PASM.COM
```

This uses the self-hosted assembler to build `PASM.COM`, the native assembler.

## The lexical analyzer

PASM has three major parts: the lexical analyzer, the parser, and the code generator.

The lexical analyzer reads the assembly file and outputs "tokens" that represent the different symbols and words
that compose a program in assembly language.

There are tokens for symbols such as the colon (`:`) or left bracket (`[`), for reserved words such as `ORG` or `MOV`,
for identifiers such as `start` or `BUFFER`, for numbers such as `42` or `100h`, and for strings such as
`'Hello, world!'`. The [GRAMMAR.md](GRAMMAR.md) file contains a full list of tokens.

Whenever PASM needs to read a new token, it calls the procedure called `LEXER_NEXT`, which reads the source code and
emits a token by storing it in `[TOKEN]` (the memory buffer addressed by the label `TOKEN`). Tokens have the following
layout in memory:

* Byte 0: `TOKEN_TYPE` (1 byte) — the token's type
* Byte 1: `TOKEN_LINE` (2 bytes) — the line where the token appears
* Byte 3: `TOKEN_VALUE` — depends on the token type:
    * For register tokens: `TOKEN_REGISTER` (1 byte) — the index of the register.
    * For segment tokens: `TOKEN_SEGMENT` (1 byte) — the index of the segment.
    * For keyword tokens: `TOKEN_KEYWORD` (1 byte) — the index of the keyword.
    * For number tokens: `TOKEN_NUMBER` (2 bytes) — the number's value.
    * For identifier tokens: `TOKEN_IDLEN` (1 byte) — the identifier's length (up to 64).
    * For string tokens: `TOKEN_STRLEN` (1 byte) — the string's length (up to 255).
* Bytes 4-: depend on the token type:
    * For identifier tokens: `TOKEN_ID` — the identifier's name.
    * For string tokens: `TOKEN_STR` — the content of the string.

There are token types for the end of the file, the end of a line, symbols such as brackets or parentheses, register
names, segment names, directives, instructions, numbers, and strings.

`LEXER_NEXT` works by reading from the input file one character at a time. (In reality it uses a 1024-byte buffer to
avoid having to call into DOS for every single character.) First, it skips any whitespace and comments it finds. When
it reaches the first non-whitespace character, it checks if it encountered any newline characters and emits an "end of
line" token if so. Otherwise, it checks if it reached the end of the file and emits an "end of file" token if so.

Next, it looks at the non-whitespace character.

* If it's one of the recognized symbols, such as a bracket, colon, or plus sign, it emits a token of the appropriate
  type.
* If it's an alphabetic character (`A`-`Z`) or an underscore (`_`), it starts reading an identifier.
* If it's a decimal digit (`0`-`9`) it starts reading a number.
* If it's a single quote (`'`), it starts reading a string.
* If it's none of these, it outputs an error message and PASM exits.

To read an identifier, the lexical analyzer keeps reading characters and adding them to the identifier as long as they
are alphabetic characters, decimal digits, or underscores. When it finds any character that doesn't fit, it stops
reading
and emits the token.

To read a number, the lexical analyzer reads decimal digits and letters from `A` to `F`, stopping after encountering
an `H` or an `O`, or when it finds any other character. Then it parses the number (outputting an error and exiting if
the number cannot be parsed) and emits the token.

To read a string, the lexical analyzer reads characters until it finds another single quote, exiting with an error if
there is a newline character or the string is too long, and then it emits the token

## The parser

You can see PASM's grammar in the [GRAMMAR.md](GRAMMAR.md) file.

PASM uses a recursive descent parser. It contains several procedures, and each one of them implements one of the grammar
rules, calling into other procedures as needed. For example, the procedure that implements the rule
`statement := prefix instruction ;` calls the procedure for the prefix first, and then the procedure for the
instruction.

The "root" procedure in the parser is `PARSE_SOURCE_`, which calls `PARSE_LINE_` repeatedly until it encounters an "end
of file" token.

In some compilers, the parser generates a "syntax tree" that can be then transformed for optimizations and then used to
execute the code generator. Not in PASM: since it needs to run in slow computers with little memory, the parser drives
the code generator directly.

As an example, the `PARSE_STATEMENT_` procedure parses a keyword followed by two arguments, and when it has all that
information, it calls the `EMIT_INSTRUCTION` procedure.

## The code generator

There are several `EMIT_*` subroutines: `EMIT_BYTE`, `EMIT_WORD`, `EMIT_DWORD` (used for `DB`, `DW`, and `DD`,
respectively), `EMIT_PREFIX`, `EMIT_ORG`, `EMIT_ALIGN`, several more that I've forgotten, and `EMIT_INSTRUCTION`.

The code generator keeps track of the memory address where the next bytes will go (the "program counter"). This
information is used to populate labels and compute jump displacements. Separately, it also keeps track of the memory
address for which the last bytes were output (the "output counter"). This lets the code generator emit "undefined bytes"
that don't occupy space in the program file.

The `EMIT_BYTE`/`_WORD`/`_DWORD`/`_STRING`, etc., procedures are very simple: output the given byte/word/dword/string
and advance the program counter and output counter.

The `EMIT_INSTRUCTION` procedure is more complicated, since it has to encode an instruction with up to two arguments.
There are many ways to do it: some instructions take no arguments and are encoded as a single byte, other instructions
take one argument but are also encoded in one byte, and some instructions can be encoded in 1, 2, 3, 4, 5, or 6 bytes.

Fortunately, all the different ways in which an instruction can be encoded can be classified into 15 patterns, so there
is a table (`INSTR_TABLE`) that associates each instruction (`MOV`, `PUSH`, `XCHG`, `STOSB`, etc.) to one of the
patterns, along with the opcode numbers and other data specific to the instruction.

Each pattern has an associated procedure that implements it. Most of those procedures start by checking the number of
arguments, making adjustments in them as needed, and then checking the types of the arguments to see how to encode the
instruction.

The arguments are stored in `[ARG1]` and `[ARG2]`, and they have the following layout in memory:

* Byte 0: `ARG_TYPE` (1 byte) — the type and size of the argument. The following bytes depend on this.
* For byte-sized numbers:
    * Byte 1: `ARG_BYTE` (1 byte) — the value.
    * Byte 2: sign extension of `ARG_BYTE`.
* For word-sized numbers:
    * Byte 1: `ARG_WORD` (2 bytes) — the value.
    * Byte 5: `ARG_DISTANCE` (1 byte) — the optional distance.
* For dword-sized numbers:
    * Byte 1: `ARG_DWORD` (4 bytes) — the value, low word first.
    * Byte 5: `ARG_DISTANCE` (1 byte) — the optional distance.
* For registers:
    * Byte 1: `ARG_REGISTER` (1 byte) — the register.
* For segments:
    * Byte 3: `ARG_SEGMENT` (1 byte) — the segment.
* For pointers:
    * Byte 1: `ARG_OFFSET` (2 bytes) — the offset.
    * Byte 3: `ARG_SEGMENT` (1 byte) — the segment override.
    * Byte 4: `ARG_EAMODE` (1 byte) — the effective-address mode.
    * Byte 5: `ARG_DISTANCE` (1 byte) — the optional distance.
* For strings:
    * Byte 1: `ARG_STRLEN` (1 byte) — the string's length.
    * Bytes 2-: `ARG_STR` — the content of the string.

The argument type is a bit mask where the 5 low bits indicate the argument type and the 3 high bits its size. If no bits
are set, the argument is not present.

## Two passes

PASM is a two-pass assembler. This means that it does the whole lexical analysis - parsing - code generation process
twice. On the first pass, it computes the locations of all the labels without generating code; on the second pass, it
outputs the generated code using all the information it got in the first pass.

Some assemblers can work on a single pass: they can leave "markers" when they find references to a label they have not
seen yet, and then they can fill in those markers when they find where the label is. However, it is a more complicated
algorithm that needs more memory than doing it in two passes.

## Labels

The source code can declare labels for code locations or data statements.

When the PASM parser finds a label declaration, it takes the current value stored in `[PC]` and adds it to the labels
table in pass 1; in pass 2, it compares the value of `[PC]` to the value in the labels table (this detects internal
"phase" errors where a label changes addresses between passes.)

When the PASM parser finds a reference to a label (for example, in a `MOV AX, my_data` instruction), it looks up the
label name in the labels table. If it can't find the label during pass 1, it makes up a "dummy" value; if it happens
during pass 2, PASM displays a "label not found" error message.

To make this work, the labels table is not cleared between passes: pass 1 populates the table, and pass 2 uses it.

Labels have the following structure:

* Byte 0: `LABEL_TYPE` (1 byte) — the label's type.
* Byte 1: `LABEL_ADDR` (2 bytes) — the address stored in the label.
* Byte 3: `LABEL_LINE` (2 bytes) — the line number where the label was defined.
* Byte 5: `LABEL_NAMELEN` (1 byte) — the length of the label's name.
* Bytes 6-: `LABEL_NAME` — the label's name.

The valid label types are `LBL_NONE` (used in the parser to distinguish between numbers and labels), `LBL_ADDR` (an
address of any size), `LBL_BYTEADDR`, `LBL_WORDADDR`, and `LBL_DWORDADDR`.

Labels are stored in a hash table, which is described later.

## Macro expansion

PASM has support for macros in the form of `EQU`.

Macro expansion happens in the lexer. Normally, the lexer reads bytes from the input file and outputs tokens. However,
when it finds an identifier that has been defined as a macro, it switches to macro expansion mode by storing in
`[LX_EQUTOKEN]` a pointer to the first token of the macro.

When the lexer is in macro expansion mode, it copies the token pointed to by `[LX_EQUTOKEN]` into `[TOKEN]` and advances
`[LX_EQUTOKEN]` to the next token. When it runs out of tokens, it sets `[LX_EQUTOKEN]` to zero, taking the lexer out of
macro expansion mode.

Macro definitions have the following structure:

* Byte 0: `MACRO_TYPE` (1 byte) — the macro's type.
* Byte 1: `MACRO_NAMELEN` (1 byte) — the length of the macro's name.
* Bytes 2-: `MACRO_NAME` — the macro's name.
* Right after `MACRO_NAME`, zero or more tokens followed by a `0` byte.

There is one macro type: `MAC_EQU`.

## Hash tables

Label and macro definitions are stored in hash tables. Those tables are implemented as 256 buckets containing linked
lists. The bucket number is calculated from the element's name using a Pearson hash function that returns a number
between 0 and 255.

Each hash table is stored in one 8086 segment, 64 kB in length. The first word in the segment contains the address of
the first free byte in the segment. The next 256 words contain pointers to the first element in each hash bucket, or 0
if the bucket is empty. Each element is also preceded by a pointer to the next element, or 0 if it is the last element.

There are three functions to manipulate hash tables: `HASH_PREPARE` (which sets up the segment with an empty hash
table), `HASH_GET` (which returns a pointer to the element with the given name), and `HASH_ADD` (which adds a position
for a new element in the hash table and returns a pointer to write the element to).

`HASH_PREPARE` takes the hash table segment in register `ES`.

`HASH_GET` takes the hash table segment in `ES`, the name to look up in `DS:SI`, and the offset of the identifier within
the elements in `DL`. If the element was not found, it sets the carry flag and returns a pointer to the last "next
element" pointer in `DI`; otherwise, it returns a pointer to the element itself in `DI`.

`HASH_ADD` takes the position of the last "next element" pointer in `ES:DI` and returns the position to write the new
element in.

Therefore, to store a label, the code first needs to use `HASH_GET` to check if the label already exists and get the
"next element" pointer. Then it needs to call `HASH_ADD`, save the label to the position it returns, and finally update
the "first free byte" word:

```
MOV ES, [LABELSEG]            ; Put the label segment in ES
MOV SI, LABEL + LABEL_NAMELEN ; Name's address in SI
MOV DL, LABEL_NAMELEN         ; Name's offset within LABEL in DL 
CALL HASH_GET                 ; Find the label
JNC _exists_                  ; Label already exists!
CALL HASH_ADD                 ; Prepare the new hash element
MOV SI, LABEL
CALL COPY_LABEL_              ; Copy the label
MOV ES:[0], DI                ; Update the first free byte position
```
