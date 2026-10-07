package parse_test

import (
	"errors"
	"io"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/jtarrio/pasm/go/parse"
)

// nonByteReader wraps an io.Reader so it does NOT implement io.ByteReader.
type nonByteReader struct {
	r io.ReadSeeker
}

func (n *nonByteReader) Read(p []byte) (int, error) {
	return n.r.Read(p)
}
func (n *nonByteReader) Seek(offset int64, whence int) (int64, error) {
	return n.r.Seek(offset, whence)
}

// errReader returns an error upon reading.
type errReader struct {
	err error
}

func (e *errReader) Read(p []byte) (int, error) {
	return 0, e.err
}
func (e *errReader) ReadByte() (byte, error) {
	return 0, e.err
}
func (e *errReader) Seek(offset int64, whence int) (int64, error) { return 0, e.err }

func TestNewLexer_NonByteReader(t *testing.T) {
	input := "MOV AX, 123"
	lexer, err := parse.NewLexer(&nonByteReader{r: strings.NewReader(input)}, "test.asm")
	require.NoError(t, err)
	require.NotNil(t, lexer)

	require.NoError(t, lexer.Next())
	tok := lexer.Token()
	assert.Equal(t, parse.KEYWORD, tok.Type)
	assert.Equal(t, parse.MOV, tok.Keyword)
}

func TestNewLexer_InitialReadError(t *testing.T) {
	expectedErr := errors.New("read failed")
	lexer, err := parse.NewLexer(&errReader{err: expectedErr}, "test.asm")
	assert.ErrorIs(t, err, expectedErr)
	assert.Nil(t, lexer)
}

func TestLexer_PunctuationAndTokens(t *testing.T) {
	input := "[ ] ( ) + - , :"
	lexer, err := parse.NewLexer(strings.NewReader(input), "test.asm")
	require.NoError(t, err)

	expected := []parse.TokenType{
		parse.LBRACKET,
		parse.RBRACKET,
		parse.LPAREN,
		parse.RPAREN,
		parse.PLUS,
		parse.MINUS,
		parse.COMMA,
		parse.COLON,
	}

	for _, expType := range expected {
		require.NoError(t, lexer.Next())
		tok := lexer.Token()
		assert.Equal(t, expType, tok.Type)
	}

	require.NoError(t, lexer.Next())
	assert.Equal(t, parse.EOL, lexer.Token().Type)

	require.NoError(t, lexer.Next())
	assert.Equal(t, parse.EOF, lexer.Token().Type)
}

func TestLexer_CaseInsensitivityAndSymbols(t *testing.T) {
	input := "mov Mov MOV ax Ax AX cs Cs CS my_var MY_VAR"
	lexer, err := parse.NewLexer(strings.NewReader(input), "test.asm")
	require.NoError(t, err)

	// Keywords (MOV)
	for range 3 {
		require.NoError(t, lexer.Next())
		tok := lexer.Token()
		assert.Equal(t, parse.KEYWORD, tok.Type)
		assert.Equal(t, parse.MOV, tok.Keyword)
	}

	// Registers (AX)
	for range 3 {
		require.NoError(t, lexer.Next())
		tok := lexer.Token()
		assert.Equal(t, parse.REGISTER, tok.Type)
		assert.Equal(t, parse.AX, tok.Register)
	}

	// Segments (CS)
	for range 3 {
		require.NoError(t, lexer.Next())
		tok := lexer.Token()
		assert.Equal(t, parse.SEGMENT, tok.Type)
		assert.Equal(t, parse.CS, tok.Segment)
	}

	// Identifiers (MY_VAR)
	for range 2 {
		require.NoError(t, lexer.Next())
		tok := lexer.Token()
		assert.Equal(t, parse.IDENTIFIER, tok.Type)
		assert.Equal(t, "MY_VAR", tok.Identifier)
	}
}

func TestLexer_Strings(t *testing.T) {
	t.Run("Valid String Case Preservation", func(t *testing.T) {
		input := "'Hello, World!' '' '123 ABC xyz'"
		lexer, err := parse.NewLexer(strings.NewReader(input), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.Next())
		tok := lexer.Token()
		assert.Equal(t, parse.STRING, tok.Type)
		assert.Equal(t, "Hello, World!", tok.Str)

		require.NoError(t, lexer.Next())
		tok = lexer.Token()
		assert.Equal(t, parse.STRING, tok.Type)
		assert.Equal(t, "", tok.Str)

		require.NoError(t, lexer.Next())
		tok = lexer.Token()
		assert.Equal(t, parse.STRING, tok.Type)
		assert.Equal(t, "123 ABC xyz", tok.Str)
	})

	t.Run("Unclosed String EOF Error", func(t *testing.T) {
		input := "'unclosed string"
		lexer, err := parse.NewLexer(strings.NewReader(input), "test.asm")
		require.NoError(t, err)

		err = lexer.Next()
		assert.ErrorContains(t, err, "unexpected EOF")
	})

	t.Run("Unclosed String EOL Error", func(t *testing.T) {
		tests := []struct {
			name  string
			input string
		}{
			{name: "Newline LF", input: "'unclosed string\n"},
			{name: "Newline CRLF", input: "'unclosed string\r\n"},
			{name: "Carriage Return CR", input: "'unclosed string\r"},
			{name: "Multiline String Attempt", input: "'line 1\nline 2'"},
		}

		for _, tc := range tests {
			t.Run(tc.name, func(t *testing.T) {
				lexer, err := parse.NewLexer(strings.NewReader(tc.input), "test.asm")
				require.NoError(t, err)

				err = lexer.Next()
				assert.ErrorContains(t, err, "unexpected end of line")
			})
		}
	})
}

func TestLexer_Numbers(t *testing.T) {
	tests := []struct {
		name          string
		input         string
		expectedVal   uint16
		expectedError string
	}{
		{name: "Decimal default", input: "1234", expectedVal: 1234},
		{name: "Decimal explicit D", input: "1234D", expectedVal: 1234},
		{name: "Decimal explicit d lowercase", input: "1234d", expectedVal: 1234},
		{name: "Decimal 0", input: "0", expectedVal: 0},
		{name: "Decimal max uint16", input: "65535", expectedVal: 65535},

		{name: "Binary 1010B", input: "1010B", expectedVal: 10},
		{name: "Binary lowercase b", input: "1111b", expectedVal: 15},
		{name: "Binary 0B", input: "0B", expectedVal: 0},

		{name: "Octal 777O", input: "777O", expectedVal: 511},
		{name: "Octal lowercase o", input: "100o", expectedVal: 64},

		{name: "Hex 0FFH", input: "0FFH", expectedVal: 255},
		{name: "Hex lowercase h", input: "1234h", expectedVal: 0x1234},
		{name: "Hex with B digit before H suffix", input: "10BH", expectedVal: 0x10B},
		{name: "Hex max uint16 0FFFFh", input: "0FFFFH", expectedVal: 65535},

		{name: "Zero", input: "0", expectedVal: 0},
		{name: "Zero hex", input: "0h", expectedVal: 0},
		{name: "Many leading zeros", input: "00000000000000000000101b", expectedVal: 5},

		// Failure cases
		{name: "Invalid binary digit", input: "102B", expectedError: "invalid digit for base 2: '2'"},
		{name: "Invalid octal digit", input: "78O", expectedError: "invalid digit for base 8: '8'"},
		{name: "Invalid decimal digit (implicit base 10)", input: "0FF", expectedError: "invalid digit for base 10: 'F'"},
		{name: "Overflow > 65535", input: "65536", expectedError: "number overflow"},
		{name: "Large Overflow", input: "999999999", expectedError: "number overflow"},
		{name: "Number too long (> 17 digits)", input: "123456789012345678", expectedError: "number is too long"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			lexer, err := parse.NewLexer(strings.NewReader(tc.input), "test.asm")
			require.NoError(t, err)

			err = lexer.Next()
			if tc.expectedError != "" {
				assert.ErrorContains(t, err, tc.expectedError)
			} else {
				require.NoError(t, err)
				tok := lexer.Token()
				assert.Equal(t, parse.NUMBER, tok.Type)
				assert.Equal(t, tc.expectedVal, tok.Number)
			}
		})
	}
}

func TestLexer_LineAndColumnTracking(t *testing.T) {
	input := "MOV AX, 1\n; comment\n  ADD BX, 2"
	lexer, err := parse.NewLexer(strings.NewReader(input), "test.asm")
	require.NoError(t, err)

	// Line 1: MOV AX, 1
	require.NoError(t, lexer.Next())
	tok := lexer.Token()
	assert.Equal(t, parse.MOV, tok.Keyword)
	assert.Equal(t, uint(1), tok.Line)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.AX, tok.Register)
	assert.Equal(t, uint(1), tok.Line)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.COMMA, tok.Type)
	assert.Equal(t, uint(1), tok.Line)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, uint16(1), tok.Number)
	assert.Equal(t, uint(1), tok.Line)

	// Newline -> EOL token
	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.EOL, tok.Type)

	// Line 3: ADD BX, 2 (Line 2 was comment)
	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.ADD, tok.Keyword)
	assert.Equal(t, uint(3), tok.Line)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.BX, tok.Register)
	assert.Equal(t, uint(3), tok.Line)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.COMMA, tok.Type)
	assert.Equal(t, uint(3), tok.Line)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, uint16(2), tok.Number)
	assert.Equal(t, uint(3), tok.Line)
}

func TestLexer_CommentsAndWhitespace(t *testing.T) {
	t.Run("Trailing Comment Without Newline", func(t *testing.T) {
		input := "NOP ; trailing comment without newline"
		lexer, err := parse.NewLexer(strings.NewReader(input), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.Next())
		tok := lexer.Token()
		assert.Equal(t, parse.KEYWORD, tok.Type)
		assert.Equal(t, parse.NOP, tok.Keyword)

		require.NoError(t, lexer.Next())
		tok = lexer.Token()
		assert.Equal(t, parse.EOL, tok.Type)

		require.NoError(t, lexer.Next())
		tok = lexer.Token()
		assert.Equal(t, parse.EOF, tok.Type)
	})

	t.Run("Only Comments", func(t *testing.T) {
		input := "; comment line 1\n; comment line 2"
		lexer, err := parse.NewLexer(strings.NewReader(input), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.Next())
		tok := lexer.Token()
		assert.Equal(t, parse.EOF, tok.Type)
	})
}

func TestLexer_AdversarialAndBreakCases(t *testing.T) {
	t.Run("Invalid Characters", func(t *testing.T) {
		invalidChars := []string{"@", "$", "#", "~", "\\", "\""}
		for _, ch := range invalidChars {
			lexer, err := parse.NewLexer(strings.NewReader(ch), "test.asm")
			if err != nil {
				assert.ErrorContains(t, err, "invalid character")
			} else {
				err = lexer.Next()
				assert.ErrorContains(t, err, "invalid character")
			}
		}
	})

	t.Run("UTF-8 Multi-byte Characters", func(t *testing.T) {
		input := "€"
		lexer, err := parse.NewLexer(strings.NewReader(input), "test.asm")
		if err != nil {
			assert.ErrorContains(t, err, "invalid character")
		} else {
			err = lexer.Next()
			assert.ErrorContains(t, err, "invalid character")
		}
	})

	t.Run("Repeated Next Calls After EOF", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader(""), "test.asm")
		require.NoError(t, err)

		for range 5 {
			require.NoError(t, lexer.Next())
			assert.Equal(t, parse.EOF, lexer.Token().Type)
		}
	})

	t.Run("Read Error Mid Token", func(t *testing.T) {
		readErr := errors.New("mid-stream failure")
		r := &failingAfterNReader{data: []byte("MOV 'unclosed"), failAt: 5, err: readErr}
		lexer, err := parse.NewLexer(r, "test.asm")
		if err != nil {
			assert.ErrorIs(t, err, readErr)
			return
		}

		err = lexer.Next()
		if err != nil {
			assert.ErrorIs(t, err, readErr)
		}
	})
}

type failingAfterNReader struct {
	data   []byte
	pos    int
	failAt int
	err    error
}

func (f *failingAfterNReader) Read(p []byte) (int, error) {
	if len(p) == 0 {
		return 0, nil
	}
	b, err := f.ReadByte()
	if err != nil {
		return 0, err
	}
	p[0] = b
	return 1, nil
}

func (f *failingAfterNReader) ReadByte() (byte, error) {
	if f.pos >= f.failAt {
		return 0, f.err
	}
	if f.pos >= len(f.data) {
		return 0, io.EOF
	}
	b := f.data[f.pos]
	f.pos++
	return b, nil
}

func (f *failingAfterNReader) Seek(offset int64, whence int) (int64, error) {
	var p int
	switch whence {
	case io.SeekStart:
		p = int(offset)
	case io.SeekCurrent:
		p = f.pos + int(offset)
	case io.SeekEnd:
		p = len(f.data) + int(offset)
	}
	if p < 0 || p >= len(f.data) {
		return 0, errors.New("out of range")
	}
	f.pos = p
	return int64(p), nil
}

func TestLexer_Equ(t *testing.T) {
	t.Run("single token substitution", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("MOV AX, CONST"), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.AddEqu("CONST", []parse.Token{{Type: parse.NUMBER, Number: 42}}))

		expected := []parse.Token{
			{Type: parse.KEYWORD, Keyword: parse.MOV},
			{Type: parse.REGISTER, Register: parse.AX},
			{Type: parse.COMMA},
			{Type: parse.NUMBER, Number: 42},
			{Type: parse.EOL},
			{Type: parse.EOF},
		}

		for i, exp := range expected {
			require.NoError(t, lexer.Next(), "Next() at index %d", i)
			tok := lexer.Token()
			assert.Equal(t, exp.Type, tok.Type, "Type at index %d", i)
			if exp.Type == parse.NUMBER {
				assert.Equal(t, exp.Number, tok.Number, "Number at index %d", i)
			}
			if exp.Type == parse.REGISTER {
				assert.Equal(t, exp.Register, tok.Register, "Register at index %d", i)
			}
			if exp.Type == parse.KEYWORD {
				assert.Equal(t, exp.Keyword, tok.Keyword, "Keyword at index %d", i)
			}
		}
	})

	t.Run("multi-token substitution", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("MOV MEM, 1"), "test.asm")
		require.NoError(t, err)

		tokens := []parse.Token{
			{Type: parse.LBRACKET},
			{Type: parse.REGISTER, Register: parse.BX},
			{Type: parse.PLUS},
			{Type: parse.REGISTER, Register: parse.SI},
			{Type: parse.RBRACKET},
		}
		require.NoError(t, lexer.AddEqu("MEM", tokens))

		expected := []parse.Token{
			{Type: parse.KEYWORD, Keyword: parse.MOV},
			{Type: parse.LBRACKET},
			{Type: parse.REGISTER, Register: parse.BX},
			{Type: parse.PLUS},
			{Type: parse.REGISTER, Register: parse.SI},
			{Type: parse.RBRACKET},
			{Type: parse.COMMA},
			{Type: parse.NUMBER, Number: 1},
			{Type: parse.EOL},
			{Type: parse.EOF},
		}

		for i, exp := range expected {
			require.NoError(t, lexer.Next(), "Next() at index %d", i)
			tok := lexer.Token()
			assert.Equal(t, exp.Type, tok.Type, "Type at index %d", i)
			if exp.Type == parse.NUMBER {
				assert.Equal(t, exp.Number, tok.Number, "Number at index %d", i)
			}
			if exp.Type == parse.REGISTER {
				assert.Equal(t, exp.Register, tok.Register, "Register at index %d", i)
			}
			if exp.Type == parse.KEYWORD {
				assert.Equal(t, exp.Keyword, tok.Keyword, "Keyword at index %d", i)
			}
		}
	})

	t.Run("multiple equs in sequence", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("MOV DEST, SRC"), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.AddEqu("DEST", []parse.Token{{Type: parse.REGISTER, Register: parse.AX}}))
		require.NoError(t, lexer.AddEqu("SRC", []parse.Token{{Type: parse.REGISTER, Register: parse.BX}}))

		expected := []parse.Token{
			{Type: parse.KEYWORD, Keyword: parse.MOV},
			{Type: parse.REGISTER, Register: parse.AX},
			{Type: parse.COMMA},
			{Type: parse.REGISTER, Register: parse.BX},
			{Type: parse.EOL},
			{Type: parse.EOF},
		}

		for i, exp := range expected {
			require.NoError(t, lexer.Next(), "Next() at index %d", i)
			tok := lexer.Token()
			assert.Equal(t, exp.Type, tok.Type, "Type at index %d", i)
			if exp.Type == parse.REGISTER {
				assert.Equal(t, exp.Register, tok.Register, "Register at index %d", i)
			}
			if exp.Type == parse.KEYWORD {
				assert.Equal(t, exp.Keyword, tok.Keyword, "Keyword at index %d", i)
			}
		}
	})

	t.Run("empty equ is skipped mid-statement", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("MOV EMPTY AX"), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.AddEqu("EMPTY", nil))

		expected := []parse.Token{
			{Type: parse.KEYWORD, Keyword: parse.MOV},
			{Type: parse.REGISTER, Register: parse.AX},
			{Type: parse.EOL},
			{Type: parse.EOF},
		}

		for i, exp := range expected {
			require.NoError(t, lexer.Next(), "Next() at index %d", i)
			tok := lexer.Token()
			assert.Equal(t, exp.Type, tok.Type, "Type at index %d", i)
			if exp.Type == parse.REGISTER {
				assert.Equal(t, exp.Register, tok.Register, "Register at index %d", i)
			}
			if exp.Type == parse.KEYWORD {
				assert.Equal(t, exp.Keyword, tok.Keyword, "Keyword at index %d", i)
			}
		}
	})

	t.Run("empty equ at EOL", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("MOV AX EMPTY\nNOP"), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.AddEqu("EMPTY", nil))

		expected := []parse.Token{
			{Type: parse.KEYWORD, Keyword: parse.MOV},
			{Type: parse.REGISTER, Register: parse.AX},
			{Type: parse.EOL},
			{Type: parse.KEYWORD, Keyword: parse.NOP},
			{Type: parse.EOL},
			{Type: parse.EOF},
		}

		for i, exp := range expected {
			require.NoError(t, lexer.Next(), "Next() at index %d", i)
			tok := lexer.Token()
			assert.Equal(t, exp.Type, tok.Type, "Type at index %d", i)
			if exp.Type == parse.REGISTER {
				assert.Equal(t, exp.Register, tok.Register, "Register at index %d", i)
			}
			if exp.Type == parse.KEYWORD {
				assert.Equal(t, exp.Keyword, tok.Keyword, "Keyword at index %d", i)
			}
		}
	})

	t.Run("restart clears equs", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("CONST"), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.AddEqu("CONST", []parse.Token{{Type: parse.NUMBER, Number: 99}}))

		require.NoError(t, lexer.Next())
		assert.Equal(t, parse.NUMBER, lexer.Token().Type)
		assert.Equal(t, uint16(99), lexer.Token().Number)

		require.NoError(t, lexer.Restart())

		require.NoError(t, lexer.Next())
		assert.Equal(t, parse.IDENTIFIER, lexer.Token().Type)
		assert.Equal(t, "CONST", lexer.Token().Identifier)
	})

	t.Run("duplicate equ name error", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader(""), "test.asm")
		require.NoError(t, err)

		require.NoError(t, lexer.AddEqu("FOO", nil))
		err = lexer.AddEqu("FOO", nil)
		require.Error(t, err)
		assert.Contains(t, err.Error(), "FOO is already defined as an EQU")
	})
}

type testCloserReader struct {
	io.Reader
	closed bool
}

func (c *testCloserReader) Close() error {
	c.closed = true
	return nil
}

func TestLexer_Include(t *testing.T) {
	t.Run("basic include and token streaming", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("MOV AX, 1\n"), "main.asm")
		require.NoError(t, err)
		assert.Equal(t, "main.asm", lexer.Filename())

		require.NoError(t, lexer.Next()) // MOV
		require.NoError(t, lexer.Next()) // AX
		require.NoError(t, lexer.Next()) // ,
		require.NoError(t, lexer.Next()) // 1
		require.NoError(t, lexer.Next()) // EOL

		require.NoError(t, lexer.Include(strings.NewReader("NOP\n"), "sub.inc"))
		assert.Equal(t, "sub.inc", lexer.Filename())

		require.NoError(t, lexer.Next()) // NOP
		assert.Equal(t, parse.KEYWORD, lexer.Token().Type)
		assert.Equal(t, parse.NOP, lexer.Token().Keyword)
		assert.Equal(t, uint(1), lexer.Token().Line)

		require.NoError(t, lexer.Next()) // EOL for NOP
		assert.Equal(t, parse.EOL, lexer.Token().Type)

		require.NoError(t, lexer.Next()) // EOL before EOF of main.asm
		assert.Equal(t, parse.EOL, lexer.Token().Type)
		assert.Equal(t, "main.asm", lexer.Filename())

		require.NoError(t, lexer.Next()) // EOF of main.asm
		assert.Equal(t, parse.EOF, lexer.Token().Type)
	})

	t.Run("closes reader on pop", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("NOP\n"), "main.asm")
		require.NoError(t, err)

		closer := &testCloserReader{Reader: strings.NewReader("HLT\n")}
		require.NoError(t, lexer.Include(closer, "inc.asm"))
		assert.False(t, closer.closed)

		for {
			require.NoError(t, lexer.Next())
			if lexer.Token().Type == parse.EOF {
				break
			}
		}
		assert.True(t, closer.closed)
	})

	t.Run("restart validation", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader("NOP\n"), "main.asm")
		require.NoError(t, err)

		// Cannot restart mid-stream
		err = lexer.Restart()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "can only restart at EOF")

		// Consume through EOF
		for {
			require.NoError(t, lexer.Next())
			if lexer.Token().Type == parse.EOF {
				break
			}
		}
		require.NoError(t, lexer.Restart())
		assert.Equal(t, "main.asm", lexer.Filename())
	})
}
