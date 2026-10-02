# PASM — Jacobo's Poor Assembler

A homemade DOS assembler for the Intel 8086/8088 processor.

## Features

- Outputs COM files directly. No need to link object files!
- Only 10 kilobytes! You can fit it and all your programs in a single floppy disk.
- Blazing fast! 75 lines per second on an IBM PC-XT!
- Written in assembly! You can assemble it with itself, or you can bootstrap it using a computer from the future that
  can run the Go programming language.
- A not completely terrible assembly language reference is available in [ASSEMBLY.md](ASSEMBLY.md).

## Interested in learning how it works?

The [HOW-IT-WORKS.md](HOW-IT-WORKS.md) file describes all the parts of PASM: lexical analyzer, parser, code generator,
macro expansion, etc. There is also a [detailed grammar description](GRAMMAR.md).

Let me know if you found them useful!

## Bootstrapping

On your computer with a Unix-like operating system with the Go programming language installed, execute:

```shell
./build.sh
```

You will get a `pasm.asm` file and a `pasm.com` file in the project's root directory. Copy both to your DOS machine and
then execute:

```shell
PASM PASM.ASM PASM2.COM
```

This will generate a `PASM2.COM` file. Finally, build a new version of the assembler:

```shell
PASM2 PASM.ASM PASM3.COM
```

You can verify that `PASM2.COM` and `PASM3.COM` are identical using the following command:

```shell
FC /B PASM2.COM PASM3.COM
```

The program should return with:

```
fc: no differences encountered
```

Now you can get rid of the intermediate steps and keep only the final, built-by-itself assembler:

```shell
DEL PASM.COM
DEL PASM2.COM
REN PASM3.COM PASM.COM
```

Alternatively, if you live in the year 1986 and you don't have access to a computer from 2026, you can request a
ready-built copy of `PASM.COM`. Send a SASE with two 3½" floppy disks (one to return, one to keep) to the following
address:

> Jacobo Tarrio Barreiro\
> PO Box 43732\
> Montclair NJ, 07043

## AI usage disclosure and policy

The purpose of writing this assembler was to learn how to write an assembler, so I wrote it by hand. However, I used
LLMs for code reviews and to generate unit tests.

You are welcome to study the source code and submit improvements. AI-authored contributions will be rejected.
AI-assisted contributions will be considered, as long as the main code has been written by hand.

## License

PASM is distributed under the terms of the MIT license, as specified in [LICENSE.md](LICENSE.md).
