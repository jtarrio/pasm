# How PASM works

PASM is an assembler for the Intel 8086/8088 microprocessor that runs on DOS. It is written in assembly, and in fact
it can assemble itself.

This document explains how PASM was built and how it works. Hopefully it will help someone learn how to build their
own assemblers and language compilers.

## The parts of PASM

PASM is divided in three parts: lexical analysis, parsing, and code generation.

### Lexical analysis

During lexical analysis, PASM reads your assembly file and divides it into the different symbols and words that the
assembly language recognizes. Each one of those symbols and words is called a "token". The lexical analyzer (or "lexer"
for short) generates tokens for symbols such as the colon (`:`) or left bracket (`[`), for reserved words such as `ORG`
or `MOV`, for user-defined identifiers such as `start` or `SALUTATION`, for numbers such as `100h` or `9`, strings such
as `'Hello, world!'`, etc.

You can see PASM's full list of tokens in the [GRAMMAR.md](GRAMMAR.md) file.

The lexer has a 1024-byte buffer. When PASM starts, it opens your source file and reads the first 1024 bytes from it.
Then the lexer reads from the buffer, advancing its position within. When it reaches the end, it reads the next 1024
bytes into the buffer and moves the current position to the beginning. By using the buffer, PASM avoids calling into
DOS for every single byte.

The procedure `LEXER_NEXT` causes the next token to be read from the source file and stored in `[TOKEN]` (the memory
addressed by the label `TOKEN`). This memory has the following layout:

* Byte 0: `TOKEN_TYPE` (1 byte) — the token's type
* Byte 1: `TOKEN_LINE` (2 bytes) — the line where the token appears
* Byte 3: `TOKEN_VALUE` — depends on the token type:
    * For register tokens: `TOKEN_REGISTER` (1 byte) — the index of the register.
    * For segment tokens: `TOKEN_SEGMENT` (1 byte) — the index of the segment.
    * For keyword tokens: `TOKEN_KEYWORD` (1 byte) — the index of the keyword.
    * For number tokens: `TOKEN_NUMBER` (2 bytes) — the number's value.
    * For identifier tokens: `TOKEN_IDLEN` (1 byte) — the identifier's length.
    * For string tokens: `TOKEN_STRLEN` (1 byte) — the string's length.
* Bytes 4-: depend on the token type:
    * For identifier tokens: `TOKEN_ID` — the identifier's name.
    * For string tokens: `TOKEN_STR` — the content of the string.

A string's maximum length is 255; the maximum length of an identifier has been arbitrarily set to 64. Therefore, the
maximum length of a token is 259 bytes.

The token types are `TK_EOF` (end of file), `TK_EOL` (end of line), `TK_LBRACKET`, `TK_RBRACKET`, `TK_LPAREN`,
`TK_RPAREN`, `TK_PLUS`, `TK_MINUS`, `TK_COMMA`, `TK_COLON`, `TK_REGISTER`, `TK_SEGMENT`, `TK_KEYWORD`, `TK_NUMBER`,
`TK_IDENTIFIER`, and `TK_STRING`.

`LEXER_NEXT` starts by skipping all whitespace and comments. If, while it's skipping whitespace, it finds a newline
character, it sets an "eol" flag. When it's reached the end of the whitespace, if the "eol" flag is set, it sets the
token's type to `TK_EOL` and returns immediately.

Then, it checks whether it has reached the end of the input file. If so, it checks whether the previous token was an EOL
token. If not, it sets the type to `TK_EOL` and returns. Otherwise, it sets the type to `TK_EOF` and returns. This
ensures that `LEXER_NEXT` always returns an EOL before an EOF, which makes parsing much easier.

Then, it reads the first non-whitespace character.

* If it's a special character (`[`, `]`, `(`, `)`, `+`, `-`, `,`, `:`), it stores a token of the appropriate type.
* If it's a digit (`0`-`9`), it starts reading a number.
* If it's a character in the `A`-`Z` range or an underscore (`_`), it starts reading an identifier.
* If it's a single quote (`'`), it starts reading a string.
* If it's none of these, it outputs an error message and exits.

To read a number, the lexer first skips all leading zeros, then reads all decimal digits (`0`-`9`) and hexadecimal
digits (`A`-`F`), stopping after an `H` or `O` or when it finds any other character. Then it checks the last
character it read to determine the number's base, and finally it decodes the number into a 16-bit value, storing it in
the token's `TOKEN_NUMBER` field and giving the token the type `TK_NUMBER`.

To read an identifier, the lexer reads all characters in the ranges `A`-`Z`, `0`-`9` and underscores (`_`) until it
finds any other character. Then it checks if it's one of the register names (if so, it stores its index in
`TOKEN_REGISTER` and sets the token's type to `TK_REGISTER`), one of the segment names (index in `TOKEN_SEGMENT` and
type `TK_SEGMENT`), one of the keywords (index in `TOKEN_KEYWORD` and type `TK_KEYWORD`), or a macro's name (see "macro
expansion" below). If it's none of those, it stores the identifier's length in `TOKEN_IDLEN`, the identifier itself in
`TOKEN_ID`, and sets the token's type to `TK_IDENTIFIER`.

### Parsing

PASM uses a recursive descent parser. It is composed of several procedures, each one of which implements a grammar rule.

You can see a description of PASM's grammar rules in the [GRAMMAR.md](GRAMMAR.md) file.

PASM's parser drives the code generator directly. Other assemblers might use the parser to build a parse tree, and then
drive the code generator from the parse tree, but PASM is designed to be very simple and run in slow machines with
little memory.

The first procedure in the parser is `PARSE_SOURCE_`. It calls `LEXER_NEXT` and checks if the token is a `TK_EOF` token.
If so, parsing is done. Otherwise, it will call `PARSE_LINE_` and, when this procedure returns, it will go to the top
and keep going until it receives a `TK_EOF` token.

`PARSE_LINE_` expects to have its first token already available in `[TOKEN]`. If it's an identifier, it calls
`PARSE_LABELED_STMT_` to execute the "labeled_statement" grammar rule; if it's an `ORG` keyword, it calls
`PARSE_ORG_DIRECTIVE_` to execute the "org_directive" grammar rule; if it's a keyword, it calls `PARSE_STATEMENT_`. If
it's none, it displays an error message and causes PASM to exit.

Parsing continues in this way, calling into other procedures and loading the next token until each parsing procedure
reaches its end or finds a token that does not fit the grammar.

As a more complex example, consider the `PARSE_STATEMENT_` procedure, which parses instructions.

It checks if the current token is a keyword token for one of the instruction prefixes; if so, it calls into the code
generator to emit that prefix, and then it loads the next token and keeps checking for prefixes. When it reaches a
non-prefix keyword token, it checks if it's `DB`, `DW`, or `DD`, and calls `PARSE_DATA_STMT_` if so. Otherwise, it loads
the next token and then checks if it's `TK_EOL`. If so, it means that the instruction has no arguments, so it calls into
the code generator to emit the instruction.

Otherwise, it calls `PARSE_ARGUMENT_` to parse the first argument. When this procedure returns, it leaves the next token
after the argument in `[TOKEN]`, so `PARSE_STATEMENT_` can check if it's `TK_EOL` (which means a single-argument
instruction, so it calls into the code generator) or `TK_COMMA`, which means that another argument follows. So it gets
the next token and then calls `PARSE_ARGUMENT_` again to read the second argument. When it returns, the next token
should be `TK_EOL`.

I will avoid describing `PARSE_ARGUMENT_` in detail (you can look at the source code and the [GRAMMAR.md](GRAMMAR.md)
file), but I will describe its output, since arguments are very important for the code generator.

This procedure parses the argument and stores its parsed value in `[DI]` (the memory position addressed by the `DI`
register.) The argument has the following layout:

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

The argument type is a bit mask, where the low bits indicate if the argument is a number, register, segment, pointer, or
string, and the high bits indicate if the argument has byte size, word size, or dword size. If zero bits are set, the
argument is empty.

The register and segment representations are the same used in the 8086's instruction encoding. Same goes for the
effective address, except that it has some additional bits to indicate if there is an offset and its size.

### Code generation

PASM generates code in two passes: it reads and parses the input file twice, and on each pass, the parser calls into the
code generator. On the first pass, the code generator computes the addresses of all the labels; on the second pass, the
code generator writes machine code to the output file.

It is possible, and it would be faster, to generate code in one pass: write machine code, writing zeroes where the value
of a label is not known, and then come back and overwrite them when all labels are known. However, it is more
complicated and requires more memory, so PASM uses a two-pass design.

The code generator consists of several procedures with names that start with `EMIT_`: `EMIT_ORG`, `EMIT_BYTE`,
`EMIT_WORD`, `EMIT_DWORD`, `EMIT_STRING`, `EMIT_PREFIX`, and `EMIT_INSTRUCTION`. These procedures, in turn, call into
other procedures to help them do their jobs.

The most basic procedures are `WRITE_BYTE_`, `WRITE_STRING_`, `WRITE_BYTES_`, etc. These procedures write to an internal
buffer and, when that buffer is full, they save it to the output file ("flush") and empty the buffer. The `EMIT_BYTE`/
`WORD`/`DWORD`/`PREFIX`/`ORG` procedures are implemented directly in terms of calls to `WRITE_BYTE_`.

The `EMIT_INSTRUCTION` procedure, however, is more complicated. PASM recognizes 112 instructions, all of them with their
own combinations of parameters that they'll accept, and their own scheme for encoding into machine code. For example,
some instructions take no arguments and can be encoded directly as a single byte (`POPF`, `IRET`, `XLAT`, etc.), others
take one argument but can also be encoded as one byte (`PUSH AX`, `INT 3`), and others take one or more arguments and
are encoded in a variable number of bytes (for example, `MOV AX, 3` takes 2 bytes, while `MOV BX, 3` takes 3.)

Thankfully, the instruction encodings can be classified into several patterns. For example, `AND`, `CMP`, `SUB`, and
`XOR` are all encoded in the same way, but with different opcodes, so we can use the same procedure to encode them; we
only need to provide parameters that indicate what opcodes to use. This is achieved through a two-level dispatch table.

When `EMIT_INSTRUCTION` is called, it receives the instruction's index in register `AL`, and the values of the two
arguments (if provided) in `[ARG1]` and `[ARG2]`. Then it looks up the instruction in the first table, `INSTR_TABLE`,
which yields a pointer to an entry of the second table. Those entries contain the address of the encoding procedure for
the pattern, followed by the parameters it requires to encode the particular instruction. Then, `EMIT_INSTRUCTION` loads
the types of arguments 1 and 2 in `AL` and `AH`, and the address of the instruction's encoding parameters in `BP`, and
then calls into the encoding procedure.

Most encoding procedures start by checking that the instruction has the appropriate number of arguments (by checking if
`AL` and `AH` contain all-zeros).

Next, many of them do distance and size adjustments. For example, for `MOV AX, [BP]`, the first argument contains a
word-sized register and the second argument contains an unknown-size pointer, but the function can modify the type of
the second argument to have word size too.

Next, the encoding procedure checks the types of the arguments and writes the appropriate bytes. For some instructions,
it calls `EMIT_BYTE` or `EMIT_WORD` as appropriate; for more complex instructions, there are specialized procedures such
as `IP_RM_WIDTH2_` (emits a Mod-R/M instruction whose opcode depends on the width of the two arguments) or
`IP_SHORTJMP_` (emits a short-jump instruction).

The code emitter keeps track of the current position within the output file in the `[PC]` variable, which advances as
more bytes and instructions are emitted. This lets the parser obtain the address for a label, or the code emitter
compute displacement values.

### Labels

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

### Macro expansion

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

### Hash tables

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
"next element" pointer, and then call `HASH_ADD`, save the label to the position it returns, and finally update the "first free byte" word:

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
