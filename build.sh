#!/bin/sh

cat \
  asm/pasm.asm \
  asm/token.asm \
  asm/lexer.asm \
  asm/hashtabl.asm \
  asm/labels.asm \
  asm/macros.asm \
  asm/argument.asm \
  asm/assemble.asm \
  asm/instrs.asm \
  asm/emit.asm \
  asm/util.asm \
  asm/main.asm \
  asm/errors.asm \
  asm/buffers.asm \
| sed 's/$/\r/g' \
> pasm.asm
go run ./go/cmd/pasm pasm.asm pasmboot.com
