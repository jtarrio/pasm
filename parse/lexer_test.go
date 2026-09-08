package parse_test

import (
	"errors"
	"io"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/jtarrio/pasm/parse"
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
	lexer, err := parse.NewLexer(&nonByteReader{r: strings.NewReader(input)})
	require.NoError(t, err)
	require.NotNil(t, lexer)

	require.NoError(t, lexer.Next())
	tok := lexer.Token()
	assert.Equal(t, parse.KEYWORD, tok.Type)
	assert.Equal(t, parse.MOV, tok.Keyword)
}

func TestNewLexer_InitialReadError(t *testing.T) {
	expectedErr := errors.New("read failed")
	lexer, err := parse.NewLexer(&errReader{err: expectedErr})
	assert.ErrorIs(t, err, expectedErr)
	assert.Nil(t, lexer)
}

func TestLexer_PunctuationAndTokens(t *testing.T) {
	input := "[ ] + - , :"
	lexer, err := parse.NewLexer(strings.NewReader(input))
	require.NoError(t, err)

	expected := []parse.TokenType{
		parse.LBRACKET,
		parse.RBRACKET,
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
	lexer, err := parse.NewLexer(strings.NewReader(input))
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
		lexer, err := parse.NewLexer(strings.NewReader(input))
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
		lexer, err := parse.NewLexer(strings.NewReader(input))
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
				lexer, err := parse.NewLexer(strings.NewReader(tc.input))
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
			lexer, err := parse.NewLexer(strings.NewReader(tc.input))
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
	lexer, err := parse.NewLexer(strings.NewReader(input))
	require.NoError(t, err)

	// Line 1: MOV AX, 1
	require.NoError(t, lexer.Next())
	tok := lexer.Token()
	assert.Equal(t, parse.MOV, tok.Keyword)
	assert.Equal(t, uint(1), tok.Line)
	assert.Equal(t, uint(1), tok.Col)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.AX, tok.Register)
	assert.Equal(t, uint(1), tok.Line)
	assert.Equal(t, uint(5), tok.Col)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.COMMA, tok.Type)
	assert.Equal(t, uint(1), tok.Line)
	assert.Equal(t, uint(7), tok.Col)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, uint16(1), tok.Number)
	assert.Equal(t, uint(1), tok.Line)
	assert.Equal(t, uint(9), tok.Col)

	// Newline -> EOL token
	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.EOL, tok.Type)

	// Line 3: ADD BX, 2 (Line 2 was comment)
	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.ADD, tok.Keyword)
	assert.Equal(t, uint(3), tok.Line)
	assert.Equal(t, uint(3), tok.Col)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.BX, tok.Register)
	assert.Equal(t, uint(3), tok.Line)
	assert.Equal(t, uint(7), tok.Col)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, parse.COMMA, tok.Type)
	assert.Equal(t, uint(3), tok.Line)
	assert.Equal(t, uint(9), tok.Col)

	require.NoError(t, lexer.Next())
	tok = lexer.Token()
	assert.Equal(t, uint16(2), tok.Number)
	assert.Equal(t, uint(3), tok.Line)
	assert.Equal(t, uint(11), tok.Col)
}

func TestLexer_CommentsAndWhitespace(t *testing.T) {
	t.Run("Trailing Comment Without Newline", func(t *testing.T) {
		input := "NOP ; trailing comment without newline"
		lexer, err := parse.NewLexer(strings.NewReader(input))
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
		lexer, err := parse.NewLexer(strings.NewReader(input))
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
			lexer, err := parse.NewLexer(strings.NewReader(ch))
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
		lexer, err := parse.NewLexer(strings.NewReader(input))
		if err != nil {
			assert.ErrorContains(t, err, "invalid character")
		} else {
			err = lexer.Next()
			assert.ErrorContains(t, err, "invalid character")
		}
	})

	t.Run("Repeated Next Calls After EOF", func(t *testing.T) {
		lexer, err := parse.NewLexer(strings.NewReader(""))
		require.NoError(t, err)

		for range 5 {
			require.NoError(t, lexer.Next())
			assert.Equal(t, parse.EOF, lexer.Token().Type)
		}
	})

	t.Run("Read Error Mid Token", func(t *testing.T) {
		readErr := errors.New("mid-stream failure")
		r := &failingAfterNReader{data: []byte("MOV 'unclosed"), failAt: 5, err: readErr}
		lexer, err := parse.NewLexer(r)
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
