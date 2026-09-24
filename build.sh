#!/bin/sh

cat \
  asm/pasm.asm \
  asm/token.asm \
  asm/lexer.asm \
  asm/labels.asm \
  asm/macros.asm \
  asm/argument.asm \
  asm/assemble.asm \
  asm/instrs.asm \
  asm/emit.asm \
  asm/util.asm \
  asm/main.asm \
  asm/errors.asm \
  asm/end.asm \
> pasm.asm
go run ./go/cmd/pasm pasm.asm pasm.com
