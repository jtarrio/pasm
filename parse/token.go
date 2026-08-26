package parse

type TokenType uint8

const (
	EOF TokenType = iota
	EOL
	LBRACKET
	RBRACKET
	PLUS
	MINUS
	COMMA
	COLON
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
	BX
	CX
	DX
	AL
	AH
	BL
	BH
	CL
	CH
	DL
	DH
	SI
	DI
	BP
	SP
)

var Registers = []string{
	"AX", "BX", "CX", "DX",
	"AL", "AH", "BL", "BH", "CL", "CH", "DL", "DH",
	"SI", "DI", "BP", "SP",
}

func IsRegister(s string) (Register, bool) {
	return isSymbol[Register](s, Registers)
}

type Segment uint8

const (
	CS Segment = iota
	DS
	ES
	SS
)

var Segments = []string{
	"CS", "DS", "ES", "SS",
}

func IsSegment(s string) (Segment, bool) {
	return isSymbol[Segment](s, Segments)
}

type Keyword uint8

const (
	AAA Keyword = iota
	AAD
	AAM
	AAS
	ADC
	ADD
	AND
	BYTE
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
	DB
	DD
	DEC
	DIV
	DW
	DWORD
	ESC
	FAR
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
	LOCK
	LODSB
	LODSW
	LOOP
	LOOPE
	LOOPNE
	LOOPNZ
	LOOPZ
	MOV
	MOVS
	MUL
	NEAR
	NEG
	NOP
	NOT
	OR
	ORG
	OUT
	POP
	POPF
	PUSH
	PUSHF
	RCL
	RCR
	REP
	REPE
	REPNE
	REPNZ
	REPZ
	RET
	ROL
	ROR
	SAHF
	SAL
	SAR
	SBB
	SCASB
	SCASW
	SHL
	SHORT
	SHR
	STC
	STD
	STI
	STOS
	SUB
	TEST
	WAIT
	WORD
	XCHG
	XLAT
	XOR
)

var Keywords = []string{
	"AAA", "AAD", "AAM", "AAS", "ADC", "ADD", "AND",
	"BYTE",
	"CALL", "CBW", "CLC", "CLD", "CLI", "CMC", "CMP", "CMPSB", "CMPSW", "CWD",
	"DAA", "DAS", "DB", "DD", "DEC", "DIV", "DW", "DWORD",
	"ESC",
	"FAR",
	"HLT",
	"IDIV", "IMUL", "IN", "INC", "INT", "INTO", "IRET",
	"JA", "JAE", "JB", "JBE", "JC", "JCXZ", "JE", "JG", "JGE", "JL", "JLE", "JMP",
	"JNA", "JNAE", "JNB", "JNBE", "JNC", "JNE", "JNG", "JNGE", "JNL", "JNLE", "JNO", "JNP", "JNS", "JNZ",
	"JO", "JP", "JPE", "JPO", "JS", "JZ",
	"LAHF", "LDS", "LEA", "LES", "LOCK", "LODSB", "LODSW", "LOOP", "LOOPE", "LOOPNE", "LOOPNZ", "LOOPZ",
	"MOV", "MOVS", "MUL",
	"NEAR", "NEG", "NOP", "NOT",
	"OR", "ORG", "OUT",
	"POP", "POPF", "PUSH", "PUSHF",
	"RCL", "RCR", "REP", "REPE", "REPNE", "REPNZ", "REPZ", "RET", "ROL", "ROR",
	"SAHF", "SAL", "SAR", "SBB", "SCASB", "SCASW", "SHL", "SHORT", "SHR", "STC", "STD", "STI", "STOS", "SUB",
	"TEST",
	"WAIT", "WORD",
	"XCHG", "XLAT", "XOR",
}

func IsKeyword(s string) (Keyword, bool) {
	return isSymbol[Keyword](s, Keywords)
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
	String     string
	Line       uint
	Col        uint
}
