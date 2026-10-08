# PASM — Jacobo's Poor Assembler

A homemade DOS assembler for the Intel 8086/8088 processor.

## Features

- Outputs COM files directly. No need to link object files!
- Less than 10 kilobytes! You can fit it and all your programs in a single floppy disk.
- All 8086 and 8088 instructions!
- Some macro functionality in the form of EQUs!
- Blazing fast! 75 lines per second on an IBM PC-XT!
- Written in assembly! You can assemble it with itself, or you can bootstrap it using a computer from the future that
  can run the Go programming language.
- A not completely terrible assembly language reference is available in [ASSEMBLY.md](ASSEMBLY.md).

## Interested in learning how it works?

The [HOW-IT-WORKS.md](HOW-IT-WORKS.md) file describes all the parts of PASM: lexical analyzer, parser, code generator,
macro expansion, etc. There is also a [detailed grammar description](GRAMMAR.md).

Let me know if you found them useful!

## Bootstrapping

You will need a computer with a Unix-like operating system and the Go programming language.

Execute the following script:

```shell
./build.sh
```

You will get a `pasm.asm` file and a `pasmboot.com` file. This is your first native assembler, built using the bootstrap
assembler. Now you need to use it to build your native assembler.

Copy `pasmboot.com`, `bootstrp.bat`, and all the files in the `asm/` directory to your DOS machine, and then execute:

```shell
BOOTSTRP
```

This will generate `pasm2.com` (self-hosted assembler) and `pasm.com` (native assembler) and compare them to verify that
they are identical.

Now you can delete `bootstrp.bat`, `pasmboot.com` and `pasm2.com` to keep your assembler and its source code!

---

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
