#!/bin/sh

cat asm/{pasm.asm,token.asm,lexer.asm,util.asm,main.asm} > pasm.asm
go run ./go/cmd/pasm pasm.asm pasm.com
