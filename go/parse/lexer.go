package parse

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"strings"
)

// Lexer reads tokens from a restartable source.
// Any empty lines (including EOL) at the beginning of the line are skipped, so you never get EOL as the first token.
// An EOL is always returned right before EOF.
type Lexer interface {
	Restart() error
	Next() error
	Token() Token
	AddEqu(name string, tokens []Token) error
	Include(r io.Reader, filename string) error
	Filename() string
}

func NewLexer(r io.ReadSeeker, filename string) (Lexer, error) {
	out := &lexer{r: r, filename: filename}
	if err := out.start(); err != nil {
		return nil, err
	}
	return out, nil
}

type includeFile struct {
	in       io.ByteReader
	filename string
	line     uint
	c        byte
	rawc     byte
}

type lexer struct {
	r            io.ReadSeeker
	in           io.ByteReader
	filename     string
	c            byte
	rawc         byte
	eof          bool
	line         uint
	token        Token
	equs         map[string][]Token
	currentEqu   []Token
	includeStack []includeFile
}

func (l *lexer) Restart() error {
	if !l.eof || len(l.includeStack) > 0 {
		return l.error("can only restart at EOF")
	}
	if _, err := l.r.Seek(0, io.SeekStart); err != nil {
		return err
	}
	return l.start()
}

func (l *lexer) start() error {
	*l = lexer{r: l.r, in: getByteReader(l.r), filename: l.filename, line: 1, equs: map[string][]Token{}}
	if err := l.readNext(); err != nil {
		return err
	}
	if _, _, err := l.skipWhitespace(); err != nil {
		return err
	}
	return nil
}

func (l *lexer) readNext() error {
	if l.eof {
		return nil
	}
	if l.c == '\n' {
		l.line++
	}
	b, err := l.in.ReadByte()
	if errors.Is(err, io.EOF) {
		l.eof = true
		return nil
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

func (l *lexer) skipWhitespace() (eol bool, eolLine uint, err error) {
	eol = false
	eolLine = 0
	comment := false
	for {
		if l.eof {
			if !eol {
				eolLine = l.line
			}
			return true, eolLine, nil
		} else if l.c == ';' {
			comment = true
		} else if l.c == '\n' {
			if !eol {
				eolLine = l.line
				eol = true
			}
			comment = false
		} else if !comment && l.c != ' ' && l.c != '\t' && l.c != '\r' {
			return eol, eolLine, nil
		}
		if err := l.readNext(); err != nil {
			return false, 0, err
		}
	}
}

func (l *lexer) Next() error {
	if len(l.currentEqu) > 0 {
		l.token = l.currentEqu[0]
		l.currentEqu = l.currentEqu[1:]
		return nil
	}

	if l.eof {
		l.token.Line = l.line
		if l.token.Type != EOL && l.token.Type != EOF {
			l.token.Type = EOL
			return nil
		} else if len(l.includeStack) > 0 {
			if rc, ok := l.in.(io.ReadCloser); ok {
				_ = rc.Close()
			}
			top := l.includeStack[len(l.includeStack)-1]
			l.includeStack = l.includeStack[:len(l.includeStack)-1]
			l.in = top.in
			l.filename = top.filename
			l.line = top.line
			l.c = top.c
			l.rawc = top.rawc
			l.eof = false
		} else {
			l.token.Type = EOF
			return nil
		}
	}
	eol, eolLine, err := l.skipWhitespace()
	if err != nil {
		return err
	}
	if eol {
		l.token = Token{Type: EOL, Line: eolLine}
		return nil
	}
	l.token = Token{Line: l.line}
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
	if l.c == '(' {
		l.token.Type = LPAREN
		return l.readNext()
	}
	if l.c == ')' {
		l.token.Type = RPAREN
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
	if l.c == '?' {
		l.token.Type = QUESTION
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
			l.token.Str = sb.String()
			return l.readNext()
		}
		sb.WriteByte(l.rawc)
	}
}

func (l *lexer) readNumber() error {
	digits := [17]byte{}
	numDigits := 0
	for {
		if l.eof || l.c != '0' {
			break
		}
		if err := l.readNext(); err != nil {
			return err
		}
	}
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
	l.token.Type = NUMBER
	if numDigits == 0 {
		return nil
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
	} else if l.findEqu(id) {
		if len(l.currentEqu) == 0 {
			return l.Next()
		}
		l.token = l.currentEqu[0]
		l.currentEqu = l.currentEqu[1:]
	} else {
		l.token.Type = IDENTIFIER
		l.token.Identifier = id
	}
	return nil
}

func (l *lexer) error(msg string) error {
	return fmt.Errorf("%s:%d: %s", l.filename, l.line, msg)
}

func (l *lexer) Token() Token {
	return l.token
}

func (l *lexer) AddEqu(name string, tokens []Token) error {
	if _, found := l.equs[name]; found {
		return l.error(fmt.Sprintf("%s is already defined as an EQU", name))
	}
	l.equs[name] = tokens
	return nil
}

func (l *lexer) findEqu(name string) bool {
	if tokens, found := l.equs[name]; found {
		l.currentEqu = tokens
		return true
	}
	return false
}

func (l *lexer) Include(r io.Reader, filename string) error {
	l.includeStack = append(l.includeStack, includeFile{in: l.in, filename: l.filename, line: l.line, c: l.c, rawc: l.rawc})
	l.in = getByteReader(r)
	l.filename = filename
	l.line = 1
	l.c = 0
	l.rawc = 0
	l.eof = false
	if err := l.readNext(); err != nil {
		return err
	}
	_, _, err := l.skipWhitespace()
	return err
}

func (l *lexer) Filename() string {
	return l.filename
}

func getByteReader(r io.Reader) io.ByteReader {
	br, ok := r.(io.ByteReader)
	if !ok {
		br = bufio.NewReader(r)
	}
	if rc, ok := r.(io.ReadCloser); ok {
		br = &byteReaderCloser{br, rc}
	}
	return br
}

type byteReaderCloser struct {
	io.ByteReader
	io.ReadCloser
}
