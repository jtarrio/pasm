package parse

import "fmt"

type TokenType uint8

const (
	EOF TokenType = iota
	EOL
	LBRACKET
	RBRACKET
	LPAREN
	RPAREN
	PLUS
	MINUS
	COMMA
	COLON
	QUESTION
	REGISTER
	SEGMENT
	KEYWORD
	IDENTIFIER
	NUMBER
	STRING
)

type Register uint8

const (
	AX Register = iota
	CX
	DX
	BX
	SP
	BP
	SI
	DI
	AL
	CL
	DL
	BL
	AH
	CH
	DH
	BH
)

var Registers = []string{
	"AX", "CX", "DX", "BX", "SP", "BP", "SI", "DI",
	"AL", "CL", "DL", "BL", "AH", "CH", "DH", "BH",
}

func IsRegister(s string) (Register, bool) {
	return isSymbol[Register](s, Registers)
}

func (r Register) String() string {
	return Registers[r]
}

type Segment uint8

const (
	ES Segment = iota
	CS
	SS
	DS
)

var Segments = []string{
	"ES", "CS", "SS", "DS",
}

func IsSegment(s string) (Segment, bool) {
	return isSymbol[Segment](s, Segments)
}

func (s Segment) String() string {
	return Segments[s]
}

type Keyword uint8

const (
	DUP Keyword = iota
	EQU
	ORG

	BYTE
	DWORD
	FAR
	NEAR
	PTR
	SHORT
	WORD

	DB
	DD
	DW

	LOCK
	REP
	REPE
	REPNE
	REPNZ
	REPZ

	AAA
	AAD
	AAM
	AAS
	ADC
	ADD
	AND
	CALL
	CBW
	CLC
	CLD
	CLI
	CMC
	CMP
	CMPSB
	CMPSW
	CWD
	DAA
	DAS
	DEC
	DIV
	ESC
	HLT
	IDIV
	IMUL
	IN
	INC
	INT
	INTO
	IRET
	JA
	JAE
	JB
	JBE
	JC
	JCXZ
	JE
	JG
	JGE
	JL
	JLE
	JMP
	JNA
	JNAE
	JNB
	JNBE
	JNC
	JNE
	JNG
	JNGE
	JNL
	JNLE
	JNO
	JNP
	JNS
	JNZ
	JO
	JP
	JPE
	JPO
	JS
	JZ
	LAHF
	LDS
	LEA
	LES
	LODSB
	LODSW
	LOOP
	LOOPE
	LOOPNE
	LOOPNZ
	LOOPZ
	MOV
	MOVSB
	MOVSW
	MUL
	NEG
	NOP
	NOT
	OR
	OUT
	POP
	POPF
	PUSH
	PUSHF
	RCL
	RCR
	RET
	RETF
	RETN
	ROL
	ROR
	SAHF
	SAL
	SAR
	SBB
	SCASB
	SCASW
	SHL
	SHR
	STC
	STD
	STI
	STOSB
	STOSW
	SUB
	TEST
	WAIT
	XCHG
	XLAT
	XOR
)

var Keywords = []string{
	"DUP", "EQU", "ORG",

	"BYTE", "DWORD", "FAR", "NEAR", "PTR", "SHORT", "WORD",

	"DB", "DD", "DW",

	"LOCK", "REP", "REPE", "REPNE", "REPNZ", "REPZ",

	"AAA", "AAD", "AAM", "AAS", "ADC", "ADD", "AND",
	"CALL", "CBW", "CLC", "CLD", "CLI", "CMC", "CMP", "CMPSB", "CMPSW", "CWD", "DAA", "DAS", "DEC", "DIV",
	"ESC",
	"HLT",
	"IDIV", "IMUL", "IN", "INC", "INT", "INTO", "IRET",
	"JA", "JAE", "JB", "JBE", "JC", "JCXZ", "JE", "JG", "JGE", "JL", "JLE", "JMP", "JNA", "JNAE", "JNB", "JNBE", "JNC", "JNE", "JNG", "JNGE", "JNL", "JNLE", "JNO", "JNP", "JNS", "JNZ", "JO", "JP", "JPE", "JPO", "JS", "JZ",
	"LAHF", "LDS", "LEA", "LES", "LODSB", "LODSW", "LOOP", "LOOPE", "LOOPNE", "LOOPNZ", "LOOPZ",
	"MOV", "MOVSB", "MOVSW", "MUL",
	"NEG", "NOP", "NOT",
	"OR", "OUT",
	"POP", "POPF", "PUSH", "PUSHF",
	"RCL", "RCR", "RET", "RETF", "RETN", "ROL", "ROR",
	"SAHF", "SAL", "SAR", "SBB", "SCASB", "SCASW", "SHL", "SHR", "STC", "STD", "STI", "STOSB", "STOSW", "SUB",
	"TEST",
	"WAIT",
	"XCHG", "XLAT", "XOR",
}

func IsKeyword(s string) (Keyword, bool) {
	return isSymbol[Keyword](s, Keywords)
}

func (k Keyword) String() string {
	return Keywords[k]
}

func isSymbol[T ~uint8](s string, a []string) (T, bool) {
	for i := range a {
		if a[i] == s {
			return T(i), true
		}
	}
	return T(0), false
}

type Token struct {
	Type       TokenType
	Register   Register
	Segment    Segment
	Keyword    Keyword
	Identifier string
	Number     uint16
	Str        string
	Line       uint
	Col        uint
}

func (t Token) String() string {
	switch t.Type {
	case EOF:
		return "end of file"
	case EOL:
		return "end of line"
	case LBRACKET:
		return "left bracket"
	case RBRACKET:
		return "right bracket"
	case LPAREN:
		return "left parenthesis"
	case RPAREN:
		return "right parenthesis"
	case PLUS:
		return "plus sign"
	case MINUS:
		return "minus sign"
	case COMMA:
		return "comma"
	case COLON:
		return "colon"
	case QUESTION:
		return "question mark"
	case REGISTER:
		return fmt.Sprintf("register %s", t.Register.String())
	case SEGMENT:
		return fmt.Sprintf("segment %s", t.Segment.String())
	case KEYWORD:
		return fmt.Sprintf("keyword %s", t.Keyword.String())
	case IDENTIFIER:
		return fmt.Sprintf("identifier %s", t.Identifier)
	case NUMBER:
		return fmt.Sprintf("number %d (%04xh)", t.Number, t.Number)
	case STRING:
		return fmt.Sprintf("string '%s'", t.Str)
	default:
		return fmt.Sprintf("token of unknown type %d", t.Type)
	}
}
