package parse

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"strings"
)

type Lexer interface {
	Next() error
	Token() Token
}

func NewLexer(r io.Reader) (Lexer, error) {
	var in io.ByteReader
	if br, ok := r.(io.ByteReader); ok {
		in = br
	} else {
		in = bufio.NewReader(r)
	}
	out := &lexer{in: in, line: 1, col: 0}
	if err := out.readNext(); err != nil {
		return nil, err
	}
	if _, err := out.skipWhitespace(); err != nil {
		return nil, err
	}
	return out, nil
}

type lexer struct {
	in    io.ByteReader
	c     byte
	rawc  byte
	eof   bool
	line  uint
	col   uint
	token Token
}

func (l *lexer) readNext() error {
	if l.eof {
		return nil
	}
	if l.c == '\n' {
		l.line++
		l.col = 1
	} else {
		l.col++
	}
	b, err := l.in.ReadByte()
	if errors.Is(err, io.EOF) {
		l.eof = true
	} else if err != nil {
		return err
	}
	if b >= 'a' && b <= 'z' {
		l.c = b - 32
	} else {
		l.c = b
	}
	l.rawc = b
	return nil
}

func (l *lexer) skipWhitespace() (bool, error) {
	eol := false
	comment := false
	for {
		if l.eof {
			return eol, nil
		} else if l.c == ';' {
			comment = true
		} else if l.c == '\n' {
			eol = true
			comment = false
		} else if !comment && l.c != ' ' && l.c != '\t' {
			return eol, nil
		}
		if err := l.readNext(); err != nil {
			return false, err
		}
	}
}

func (l *lexer) Next() error {
	if l.eof {
		l.token.Type = EOF
		return nil
	}
	eol, err := l.skipWhitespace()
	if err != nil {
		return err
	}
	l.token = Token{Line: l.line, Col: l.col}
	if eol {
		l.token.Type = EOL
		return nil
	}
	return l.readToken()
}

func (l *lexer) readToken() error {
	if l.eof {
		l.token.Type = EOF
		return nil
	}
	if l.c == '[' {
		l.token.Type = LBRACKET
		return l.readNext()
	}
	if l.c == ']' {
		l.token.Type = RBRACKET
		return l.readNext()
	}
	if l.c == '+' {
		l.token.Type = PLUS
		return l.readNext()
	}
	if l.c == '-' {
		l.token.Type = MINUS
		return l.readNext()
	}
	if l.c == ',' {
		l.token.Type = COMMA
		return l.readNext()
	}
	if l.c == ':' {
		l.token.Type = COLON
		return l.readNext()
	}
	if l.c == '\'' {
		return l.readString()
	}
	if l.c >= '0' && l.c <= '9' {
		return l.readNumber()
	}
	if l.c == '_' || (l.c >= 'A' && l.c <= 'Z') {
		return l.readIdentifier()
	}
	return l.error(fmt.Sprintf("invalid character '%c'", l.c))
}

func (l *lexer) readString() error {
	l.token.Type = STRING
	sb := strings.Builder{}
	for {
		if err := l.readNext(); err != nil {
			return err
		}
		if l.eof {
			return l.error("unexpected EOF")
		}
		if l.c == '\r' || l.c == '\n' {
			return l.error("unexpected end of line")
		}
		if l.c == '\'' {
			l.token.String = sb.String()
			return l.readNext()
		}
		sb.WriteByte(l.rawc)
	}
}

func (l *lexer) readNumber() error {
	digits := [17]byte{}
	numDigits := 0
	for {
		if l.eof {
			break
		}
		b := l.c
		if b < '0' || (b > '9' && b < 'A') || (b > 'F' && b != 'H' && b != 'O') {
			break
		}
		if numDigits == len(digits) {
			return l.error("number is too long")
		}
		digits[numDigits] = b
		numDigits++
		if err := l.readNext(); err != nil {
			return err
		}
		if b == 'H' || b == 'O' {
			break
		}
	}
	base := uint16(10)
	numDigits--
	suffix := digits[numDigits]
	if suffix == 'B' {
		base = 2
	} else if suffix == 'O' {
		base = 8
	} else if suffix == 'D' {
		base = 10
	} else if suffix == 'H' {
		base = 16
	} else {
		numDigits++
	}

	const maxValue = uint16(65535)
	value := uint16(0)
	for i := range numDigits {
		digit := uint16(digits[i] - '0')
		if digits[i] >= 'A' {
			digit = uint16(digits[i] - 'A' + 10)
		}
		if digit >= base {
			return l.error(fmt.Sprintf("invalid digit for base %d: '%c'", base, digits[i]))
		}
		if (maxValue-digit)/base < value {
			return l.error("number overflow")
		}
		value = value*base + digit
	}
	l.token.Type = NUMBER
	l.token.Number = value
	return nil
}

func (l *lexer) readIdentifier() error {
	sb := strings.Builder{}
	for {
		if l.eof {
			break
		}
		if l.c == '_' || (l.c >= '0' && l.c <= '9') || (l.c >= 'A' && l.c <= 'Z') {
			sb.WriteByte(l.c)
		} else {
			break
		}
		if err := l.readNext(); err != nil {
			return err
		}
	}
	id := sb.String()
	if reg, found := IsRegister(id); found {
		l.token.Type = REGISTER
		l.token.Register = reg
	} else if seg, found := IsSegment(id); found {
		l.token.Type = SEGMENT
		l.token.Segment = seg
	} else if kw, found := IsKeyword(id); found {
		l.token.Type = KEYWORD
		l.token.Keyword = kw
	} else {
		l.token.Type = IDENTIFIER
		l.token.Identifier = id
	}
	return nil
}

func (l *lexer) error(msg string) error {
	return fmt.Errorf("%d:%d: %s", l.line, l.col, msg)
}

func (l *lexer) Token() Token {
	return l.token
}
