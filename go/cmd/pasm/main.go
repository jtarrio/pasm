package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jtarrio/pasm/go/assemble"
	"github.com/jtarrio/pasm/go/parse"
)

func help() {
	_, _ = fmt.Fprintf(os.Stderr, "usage: pasm <input> [<output>]\n")
	os.Exit(1)
}

func main() {
	args := os.Args[1:]
	if len(args) < 1 || len(args) > 2 {
		help()
	}

	input := args[0]
	var output string
	if len(args) == 2 {
		output = args[1]
	} else {
		ext := filepath.Ext(input)
		if strings.EqualFold(ext, ".asm") {
			output = input[:len(input)-len(ext)] + ".com"
		} else {
			output = input + ".com"
		}
	}
	if input == output {
		_, _ = fmt.Fprintln(os.Stderr, "input and output cannot be the same file")
		os.Exit(1)
	}

	in, err := os.Open(input)
	if err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "failed to open %s: %v\n", input, err)
		os.Exit(1)
	}

	lexer, err := parse.NewLexer(in, input)
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err.Error())
		_ = in.Close()
		os.Exit(1)
	}

	out, err := os.Create(output)
	if err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "failed to create %s: %v\n", output, err)
		_ = in.Close()
		os.Exit(1)
	}

	if err = assemble.Assemble(lexer, out); err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err.Error())
		_ = in.Close()
		_ = out.Close()
		_ = os.Remove(output)
		os.Exit(1)
	}

	if err = in.Close(); err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err.Error())
	}
	if err = out.Close(); err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err.Error())
	}
}
