package assemble

import (
	"bufio"
	"fmt"
	"io"

	"github.com/jtarrio/pasm/parse"
)

func Assemble(input parse.Lexer, output io.Writer) error {
	asm := assembler{
		in:     input,
		out:    getByteWriter(output),
		pass:   1,
		pc:     0,
		labels: map[string]label{},
	}

	if err := asm.parseSource(); err != nil {
		return err
	}
	if err := input.Restart(); err != nil {
		return err
	}
	asm.pass = 2
	asm.pc = 0
	if err := asm.parseSource(); err != nil {
		return err
	}
	if bw, ok := asm.out.(*bufio.Writer); ok {
		return bw.Flush()
	}
	return nil
}

type assembler struct {
	in     parse.Lexer
	out    io.ByteWriter
	pass   int
	pc     uint16
	labels map[string]label
}

type label struct {
	class labelClass
	addr  uint16
	line  uint
}

type labelClass uint8

const (
	noLabel labelClass = iota
	anyAddr
	byteAddr
	wordAddr
	dwordAddr
)

func getByteWriter(w io.Writer) io.ByteWriter {
	if bw, ok := w.(io.ByteWriter); ok {
		return bw
	}
	if w == nil {
		return nil
	}
	return bufio.NewWriter(w)
}

func (a *assembler) parseSource() error {
	if err := a.in.Next(); err != nil {
		return err
	}
	for a.in.Token().Type != parse.EOF {
		if err := a.parseLine(); err != nil {
			return err
		}
		if err := a.expect(parse.EOL, "expected end of line"); err != nil {
			return err
		}
		for a.in.Token().Type == parse.EOL {
			if err := a.in.Next(); err != nil {
				return err
			}
		}
	}
	return nil
}

func (a *assembler) parseLine() error {
	token := a.in.Token()
	switch token.Type {
	case parse.IDENTIFIER:
		return a.parseLabeledStatement()
	case parse.KEYWORD:
		if token.Keyword == parse.ORG {
			return a.parseOrgDirective()
		}
		return a.parseStatement()
	default:
		return a.errorFound("expected label or keyword")
	}
}

func (a *assembler) parseLabeledStatement() error {
	labelToken := a.in.Token()
	if err := a.in.Next(); err != nil {
		return err
	}
	switch a.in.Token().Type {
	case parse.COLON:
		if err := a.addLabel(labelToken, anyAddr); err != nil {
			return err
		}
		if err := a.in.Next(); err != nil {
			return err
		}
		if a.in.Token().Type == parse.EOL {
			return nil
		}
		if err := a.expect(parse.KEYWORD, "expected keyword"); err != nil {
			return err
		}
		return a.parseStatement()
	case parse.KEYWORD:
		switch a.in.Token().Keyword {
		case parse.DB:
			class := byteAddr
			if err := a.addLabel(labelToken, class); err != nil {
				return err
			}
			return a.parseDataStatement()
		case parse.DW:
			class := wordAddr
			if err := a.addLabel(labelToken, class); err != nil {
				return err
			}
			return a.parseDataStatement()
		case parse.DD:
			class := dwordAddr
			if err := a.addLabel(labelToken, class); err != nil {
				return err
			}
			return a.parseDataStatement()
		case parse.EQU:
			return a.parseEquDirective(labelToken.Identifier)
		default:
			return a.errorFound("expected DB, DW, DD, or EQU")
		}
	default:
		return a.errorFound("expected colon, DB, DW, DD, or EQU")
	}
}

func (a *assembler) parseOrgDirective() error {
	if err := a.nextAndExpect(parse.NUMBER, "expected number"); err != nil {
		return err
	}
	if err := a.emitOrg(a.in.Token().Number); err != nil {
		return err
	}
	return a.in.Next()
}

func (a *assembler) parseEquDirective(id string) error {
	if _, ok := a.labels[id]; ok {
		return a.error(fmt.Sprintf("%s is already defined", id))
	}
	var tokens []parse.Token
	for {
		if err := a.in.Next(); err != nil {
			return err
		}
		if a.in.Token().Type == parse.EOL {
			return a.in.AddEqu(id, tokens)
		}
		tokens = append(tokens, a.in.Token())
	}
}

func (a *assembler) parseDataStatement() error {
	switch a.in.Token().Keyword {
	case parse.DB:
		if err := a.in.Next(); err != nil {
			return err
		}
		return a.parseByteSequence()
	case parse.DW:
		if err := a.in.Next(); err != nil {
			return err
		}
		return a.parseWordSequence()
	case parse.DD:
		if err := a.in.Next(); err != nil {
			return err
		}
		return a.parseDwordSequence()
	default:
		return a.errorFound("expected DB, DW, or DD")
	}
}

func (a *assembler) parseStatement() error {
	kw := a.in.Token().Keyword
	if kw >= parse.LOCK && kw <= parse.REPZ {
		if err := a.emitPrefix(kw); err != nil {
			return err
		}
		if err := a.in.Next(); err != nil {
			return err
		}
		if a.in.Token().Type == parse.EOL {
			return nil
		}
		return a.parseStatement()
	}

	if kw >= parse.DB && kw <= parse.DW {
		return a.parseDataStatement()
	}

	if kw < parse.AAA {
		return a.errorFound("expected an instruction")
	}
	if err := a.in.Next(); err != nil {
		return err
	}

	if a.in.Token().Type == parse.EOL {
		return a.emitInstruction(kw, nil, nil)
	}

	var arg1 argument
	if err := a.parseArgument(&arg1); err != nil {
		return err
	}
	if a.in.Token().Type == parse.EOL {
		return a.emitInstruction(kw, &arg1, nil)
	}

	if err := a.expectAndNext(parse.COMMA, "expected comma"); err != nil {
		return err
	}
	var arg2 argument
	if err := a.parseArgument(&arg2); err != nil {
		return err
	}
	if err := a.expect(parse.EOL, "expected end of line"); err != nil {
		return err
	}
	return a.emitInstruction(kw, &arg1, &arg2)
}

func (a *assembler) parseByteSequence() error {
	for {
		var arg argument
		if err := a.parseArgument(&arg); err != nil {
			return err
		}
		var dup uint16
		if err := a.parseDup(&arg, &dup); err != nil {
			return err
		}
		if arg.argType == argNum|sizeByte {
			for i := uint16(0); i < dup; i++ {
				if err := a.emitByte(byte(arg.value)); err != nil {
					return err
				}
			}
		} else if arg.argType == argString {
			for i := uint16(0); i < dup; i++ {
				if err := a.emitString(arg.string); err != nil {
					return err
				}
			}
		} else {
			return a.errorArg("expected byte or string argument", &arg)
		}
		if a.in.Token().Type == parse.EOL {
			return nil
		}
		if err := a.expectAndNext(parse.COMMA, "expected comma"); err != nil {
			return err
		}
	}
}

func (a *assembler) parseWordSequence() error {
	for {
		var arg argument
		if err := a.parseArgument(&arg); err != nil {
			return err
		}
		var dup uint16
		if err := a.parseDup(&arg, &dup); err != nil {
			return err
		}
		if arg.argType.Class() == argNum {
			for i := uint16(0); i < dup; i++ {
				if err := a.emitWord(arg.value); err != nil {
					return err
				}
			}
		} else if arg.argType == argString && len(arg.string) == 2 {
			for i := uint16(0); i < dup; i++ {
				if err := a.emitString(arg.string); err != nil {
					return err
				}
			}
		} else {
			return a.errorArg("expected word argument", &arg)
		}
		if a.in.Token().Type == parse.EOL {
			return nil
		}
		if err := a.expectAndNext(parse.COMMA, "expected comma"); err != nil {
			return err
		}
	}
}

func (a *assembler) parseDwordSequence() error {
	for {
		var arg argument
		if err := a.parseArgument(&arg); err != nil {
			return err
		}
		var dup uint16
		if err := a.parseDup(&arg, &dup); err != nil {
			return err
		}
		if arg.argType == argNum|sizeDword {
			for i := uint16(0); i < dup; i++ {
				if err := a.emitDword(arg.value, arg.value2); err != nil {
					return err
				}
			}
		} else if arg.argType == argString && len(arg.string) == 4 {
			for i := uint16(0); i < dup; i++ {
				if err := a.emitString(arg.string); err != nil {
					return err
				}
			}
		} else {
			return a.errorArg("expected dword argument", &arg)
		}
		if a.in.Token().Type == parse.EOL {
			return nil
		}
		if err := a.expectAndNext(parse.COMMA, "expected comma"); err != nil {
			return err
		}
	}
}

func (a *assembler) parseDup(arg *argument, dup *uint16) error {
	*dup = 1
	level := 0
	for {
		if arg.argType.Class() != argNum || a.in.Token().Type != parse.KEYWORD || a.in.Token().Keyword != parse.DUP {
			for level > 0 {
				if err := a.expectAndNext(parse.RPAREN, "expected right parenthesis"); err != nil {
					return err
				}
				level--
			}
			return nil
		}
		level++
		*dup = *dup * arg.value
		if err := a.in.Next(); err != nil {
			return err
		}
		if err := a.expectAndNext(parse.LPAREN, "expected left parenthesis"); err != nil {
			return err
		}
		if err := a.parseArgument(arg); err != nil {
			return err
		}
	}
}

func (a *assembler) parseArgument(arg *argument) error {
	switch a.in.Token().Type {
	case parse.IDENTIFIER, parse.NUMBER, parse.PLUS, parse.MINUS:
		return a.parseNumberArg(arg)
	case parse.STRING:
		return a.parseStringArg(arg)
	case parse.REGISTER:
		return a.parseRegisterArg(arg)
	case parse.SEGMENT:
		return a.parseSegmentArg(arg)
	case parse.LBRACKET:
		return a.parseBarePtrArg(arg)
	case parse.KEYWORD:
		return a.parseKeywordArg(arg)
	default:
		return a.errorFound("expected an argument")
	}
}

func (a *assembler) parseNumberArg(arg *argument) error {
	value := int32(0)
	labelClass := noLabel
	if err := a.parseNumberExpr(&value, &labelClass); err != nil {
		return err
	}
	if a.in.Token().Type == parse.COLON {
		if err := a.in.Next(); err != nil {
			return err
		}
		offset := int32(0)
		if err := a.parseNumberExpr(&offset, &labelClass); err != nil {
			return err
		}
		arg.argType = argNum | sizeDword
		arg.value = uint16(offset)
		arg.value2 = uint16(value)
		return nil
	}

	if labelClass == noLabel && value >= -128 && value <= 255 {
		arg.argType = argNum | sizeByte
	} else {
		arg.argType = argNum | sizeWord
	}
	arg.value = uint16(value)
	return nil
}

func (a *assembler) parseStringArg(arg *argument) error {
	str := a.in.Token().Str
	if len(str) == 1 {
		arg.argType = argNum | sizeByte
		arg.value = uint16(str[0])
	} else {
		arg.argType = argString
		arg.string = str
	}
	return a.in.Next()
}

func (a *assembler) parseRegisterArg(arg *argument) error {
	reg := a.in.Token().Register
	if reg >= parse.AL {
		arg.argType = argReg | sizeByte
		arg.regSeg = regSeg(reg - parse.AL)
	} else {
		arg.argType = argReg | sizeWord
		arg.regSeg = regSeg(reg - parse.AX)
	}
	return a.in.Next()
}

func (a *assembler) parseSegmentArg(arg *argument) error {
	arg.regSeg = regSeg(a.in.Token().Segment)
	if err := a.in.Next(); err != nil {
		return err
	}
	if a.in.Token().Type != parse.COLON {
		arg.argType = argSeg
		return nil
	}
	if err := a.nextAndExpect(parse.LBRACKET, "expected left bracket"); err != nil {
		return err
	}
	arg.eaMode |= eaSegment
	if err := a.parseBarePtrArg(arg); err != nil {
		return err
	}
	return nil
}

func (a *assembler) parseBarePtrArg(arg *argument) error {
	if err := a.in.Next(); err != nil {
		return err
	}
	bxBp := 0
	siDi := 0
	offset := uint16(0)
	labelClass := noLabel
	for {
		switch a.in.Token().Type {
		case parse.REGISTER:
			reg := a.in.Token().Register
			if reg == parse.BX && bxBp == 0 {
				bxBp = 1
			} else if reg == parse.BP && bxBp == 0 {
				bxBp = 2
			} else if reg == parse.SI && siDi == 0 {
				siDi = 1
			} else if reg == parse.DI && siDi == 0 {
				siDi = 2
			} else {
				return a.error(fmt.Sprintf("invalid register %s in pointer", reg))
			}
			if err := a.in.Next(); err != nil {
				return err
			}
		case parse.PLUS, parse.MINUS, parse.NUMBER, parse.IDENTIFIER:
			o := int32(0)
			if err := a.parseSingleNumber(&o, &labelClass); err != nil {
				return err
			}
			offset += uint16(o)
		default:
			return a.errorFound("expected BX, BP, SI, DI, or an offset")
		}
		if a.in.Token().Type == parse.RBRACKET {
			break
		} else if a.in.Token().Type == parse.PLUS {
			if err := a.in.Next(); err != nil {
				return err
			}
		} else if a.in.Token().Type != parse.MINUS {
			return a.errorFound("expected right bracket or arithmetic operator")
		}
	}

	if bxBp == 0 && siDi == 0 {
		arg.value = offset
		arg.eaMode |= eaDirect
	} else if bxBp == 0 && siDi == 1 {
		arg.eaMode |= eaSi
	} else if bxBp == 0 && siDi == 2 {
		arg.eaMode |= eaDi
	} else if bxBp == 1 && siDi == 0 {
		arg.eaMode |= eaBx
	} else if bxBp == 1 && siDi == 1 {
		arg.eaMode |= eaBxSi
	} else if bxBp == 1 && siDi == 2 {
		arg.eaMode |= eaBxDi
	} else if bxBp == 2 && siDi == 0 {
		arg.eaMode |= eaBp | eaOffset
	} else if bxBp == 2 && siDi == 1 {
		arg.eaMode |= eaBpSi
	} else if bxBp == 2 && siDi == 2 {
		arg.eaMode |= eaBpDi
	}
	if (offset != 0 || labelClass != noLabel) && arg.eaMode & ^eaSegment != eaDirect {
		arg.eaMode |= eaOffset
		if labelClass != noLabel {
			arg.eaMode |= eaOffset16
		}
		arg.value = offset
	}
	if arg.eaMode&eaSegment != 0 {
		if (bxBp == 2 && arg.regSeg == SS) || (bxBp != 2 && arg.regSeg == DS) {
			arg.eaMode &= ^eaSegment
		}
	}
	switch labelClass {
	case byteAddr:
		arg.argType = argPtr | sizeByte
	case wordAddr:
		arg.argType = argPtr | sizeWord
	case dwordAddr:
		arg.argType = argPtr | sizeDword
	default:
		arg.argType = argPtr
	}
	return a.in.Next()
}

func (a *assembler) parseKeywordArg(arg *argument) error {
	switch a.in.Token().Keyword {
	case parse.BYTE, parse.WORD, parse.DWORD:
		size := a.in.Token().Keyword
		if err := a.in.Next(); err != nil {
			return err
		}
		if a.in.Token().Type != parse.KEYWORD || a.in.Token().Keyword != parse.PTR {
			return a.errorFound("expected PTR")
		}
		if err := a.in.Next(); err != nil {
			return err
		}
		if err := a.parsePtrArg(arg); err != nil {
			return err
		}
		if size == parse.BYTE {
			arg.argType = arg.argType.WithSize(sizeByte)
		} else if size == parse.WORD {
			arg.argType = arg.argType.WithSize(sizeWord)
		} else if size == parse.DWORD {
			arg.argType = arg.argType.WithSize(sizeDword)
		}
	case parse.SHORT, parse.NEAR, parse.FAR:
		if arg.distance != 0 {
			return a.error("unexpected distance specifier")
		}
		dist := a.in.Token().Keyword
		if err := a.in.Next(); err != nil {
			return err
		}
		if dist == parse.SHORT {
			arg.distance = short
		} else if dist == parse.NEAR {
			arg.distance = near
		} else if dist == parse.FAR {
			arg.distance = far
		}
		if err := a.parseArgument(arg); err != nil {
			return err
		}
		if arg.distance == short && (arg.argType != argNum|sizeByte && arg.argType != argNum|sizeWord) {
			return a.errorArg("invalid short target", arg)
		} else if arg.distance == near && arg.argType == argPtr {
			arg.argType |= sizeWord
		} else if arg.distance == near && (arg.argType.Size() != sizeByte && arg.argType.Size() != sizeWord) {
			return a.errorArg("invalid near target", arg)
		} else if arg.distance == far && arg.argType == argPtr {
			arg.argType |= sizeDword
		} else if arg.distance == far && (arg.argType.Size() != sizeDword) {
			return a.errorArg("invalid far target", arg)
		}
		return nil
	default:
		return a.errorFound("expected size or distance specifier")
	}
	return nil
}

func (a *assembler) parsePtrArg(arg *argument) error {
	if a.in.Token().Type == parse.SEGMENT {
		arg.regSeg = regSeg(a.in.Token().Segment)
		arg.eaMode |= eaSegment
		if err := a.nextAndExpect(parse.COLON, "expected colon"); err != nil {
			return err
		}
		if err := a.in.Next(); err != nil {
			return err
		}
	}
	if err := a.expect(parse.LBRACKET, "expected left bracket"); err != nil {
		return err
	}
	return a.parseBarePtrArg(arg)
}

func (a *assembler) parseNumberExpr(value *int32, labelClass *labelClass) error {
	add := true
	for {
		n := int32(0)
		if err := a.parseSingleNumber(&n, labelClass); err != nil {
			return err
		}

		if add {
			*value += n
		} else {
			*value -= n
			add = true
		}
		if a.in.Token().Type != parse.PLUS && a.in.Token().Type != parse.MINUS {
			return nil
		}
		add = a.in.Token().Type == parse.PLUS
		if err := a.in.Next(); err != nil {
			return err
		}
	}
}

func (a *assembler) parseSingleNumber(value *int32, labelClass *labelClass) error {
	minus := a.in.Token().Type == parse.MINUS
	if minus || a.in.Token().Type == parse.PLUS {
		if err := a.in.Next(); err != nil {
			return err
		}
	}
	n := int32(0)
	switch a.in.Token().Type {
	case parse.NUMBER:
		n = int32(a.in.Token().Number)
	case parse.IDENTIFIER:
		lbl, err := a.getLabel(a.in.Token().Identifier)
		if err != nil {
			return err
		}
		n = int32(lbl.addr)
		*labelClass = lbl.class
	default:
		return a.errorFound("expected number or label")
	}
	if minus {
		if n > 32768 {
			return a.error("number underflow")
		}
		*value = -n
	} else {
		if n > 65535 {
			return a.error("number overflow")
		}
		*value = n
	}
	return a.in.Next()
}

func (a *assembler) addLabel(labelToken parse.Token, class labelClass) error {
	name := labelToken.Identifier
	if p, ok := a.labels[name]; ok {
		if a.pass == 2 {
			if p.addr == a.pc {
				return nil
			}
			return a.error(fmt.Sprintf("internal error: label %s changed address between passes 1 and 2: %04Xh -> %04Xh", name, p.addr, a.pc))
		}
		return a.error(fmt.Sprintf("duplicate label %s; previously found on line %d", name, p.line))
	}
	l := label{class: class, addr: a.pc, line: labelToken.Line}
	a.labels[name] = l
	return nil
}

func (a *assembler) getLabel(name string) (label, error) {
	if v, ok := a.labels[name]; ok {
		return v, nil
	} else if a.pass == 1 {
		return label{class: anyAddr, addr: a.pc + 260, line: a.in.Token().Line}, nil
	}
	return label{}, a.error(fmt.Sprintf("label %s not found", name))
}

func (a *assembler) expect(tokenType parse.TokenType, msg string) error {
	if a.in.Token().Type != tokenType {
		return a.errorFound(msg)
	}
	return nil
}

func (a *assembler) nextAndExpect(tokenType parse.TokenType, msg string) error {
	if err := a.in.Next(); err != nil {
		return err
	}
	return a.expect(tokenType, msg)
}

func (a *assembler) expectAndNext(tokenType parse.TokenType, msg string) error {
	if err := a.expect(tokenType, msg); err != nil {
		return err
	}
	return a.in.Next()
}

func (a *assembler) error(msg string) error {
	return fmt.Errorf("%d:%d: %s", a.in.Token().Line, a.in.Token().Col, msg)
}

func (a *assembler) errorFound(msg string) error {
	return fmt.Errorf("%d:%d: %s; found %s", a.in.Token().Line, a.in.Token().Col, msg, a.in.Token())
}

func (a *assembler) errorArg(msg string, arg *argument) error {
	return fmt.Errorf("%d:%d: %s; found %s", a.in.Token().Line, a.in.Token().Col, msg, arg)
}
