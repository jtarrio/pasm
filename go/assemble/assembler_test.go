package assemble_test

import (
	"bytes"
	"fmt"
	"strings"
	"testing"

	"github.com/jtarrio/pasm/go/assemble"
	"github.com/jtarrio/pasm/go/parse"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func assembleString(t *testing.T, src string) ([]byte, error) {
	t.Helper()
	lex, err := parse.NewLexer(strings.NewReader(src))
	if err != nil {
		return nil, err
	}
	var buf bytes.Buffer
	err = assemble.Assemble(lex, &buf)
	return buf.Bytes(), err
}

func assertAssemble(t *testing.T, src, expectedHex string) {
	t.Helper()
	out, err := assembleString(t, src)
	require.NoError(t, err, "assembling: %q", src)
	if len(out) == 0 {
		assert.Equal(t, "", strings.TrimSpace(expectedHex), "assembling: %q", src)
		return
	}
	gotHex := strings.ToUpper(strings.TrimSpace(fmt.Sprintf("% 02X", out)))
	wantHex := strings.ToUpper(strings.TrimSpace(expectedHex))
	assert.Equal(t, wantHex, gotHex, "assembling: %q", src)
}

func assertAssembleError(t *testing.T, src string) {
	t.Helper()
	_, err := assembleString(t, src)
	assert.Error(t, err, "expected error for: %q", src)
}

func TestAssemble_DirectivesAndData(t *testing.T) {
	t.Run("ORG and Whitespace", func(t *testing.T) {
		assertAssemble(t, "ORG 100h\nNOP\n", "90")
		assertAssemble(t, "ORG 0\nNOP\n", "90")
		assertAssemble(t, "ORG 100h\nNOP\nORG 105h\nNOP\n", "90 00 00 00 00 90")
		assertAssemble(t, "", "")
		assertAssemble(t, "; only comments\n", "")
		assertAssemble(t, "\n\n; comment\n\n", "")
	})

	t.Run("LineEndings_CRLF", func(t *testing.T) {
		assertAssemble(t, "MOV AX, 1\r\nMOV BX, 2\r\n", "B8 01 00 BB 02 00")
	})

	t.Run("DB", func(t *testing.T) {
		assertAssemble(t, "DB 0\n", "00")
		assertAssemble(t, "DB 255\n", "FF")
		assertAssemble(t, "DB -1\n", "FF")
		assertAssemble(t, "DB -128\n", "80")
		assertAssemble(t, "DB +1\n", "01")
		assertAssemble(t, "DB 'hello'\n", "68 65 6C 6C 6F")
		assertAssemble(t, "DB 'a'\n", "61")
		assertAssemble(t, "DB ''\n", "")
		assertAssemble(t, "DB 'hello;world'\n", "68 65 6C 6C 6F 3B 77 6F 72 6C 64")
		assertAssemble(t, "DB 'hello', 0Dh, 0Ah, '$'\n", "68 65 6C 6C 6F 0D 0A 24")
	})

	t.Run("DW", func(t *testing.T) {
		assertAssemble(t, "DW 0\n", "00 00")
		assertAssemble(t, "DW 1234h\n", "34 12")
		assertAssemble(t, "DW -1\n", "FF FF")
		assertAssemble(t, "DW +1\n", "01 00")
		assertAssemble(t, "DW 'AB'\n", "41 42")
		assertAssemble(t, "salutation: DB 'hi'\naddress DW salutation\n", "68 69 00 00")
	})

	t.Run("DD", func(t *testing.T) {
		assertAssemble(t, "DD 'ABCD'\n", "41 42 43 44")
		assertAssemble(t, "screen DD 0b800h:0000h\n", "00 00 00 B8")
		assertAssemble(t, "DD 1234h:5678h\n", "78 56 34 12")
	})

	t.Run("EQU", func(t *testing.T) {
		assertAssemble(t, "VAL EQU 42h\nMOV AL, VAL\n", "B0 42")
		assertAssemble(t, "VAL EQU 10h + 5\nMOV AL, VAL\n", "B0 15")
		assertAssemble(t, "DEST EQU BL\nSRC EQU AL\nMOV DEST, SRC\n", "88 C3")
		assertAssemble(t, "SREG EQU DS\nPUSH SREG\n", "1E")
		assertAssemble(t, "MEM EQU BYTE PTR [BX + SI]\nMOV MEM, 1\n", "C6 00 01")
		assertAssemble(t, "ADDR EQU [BP + 4]\nMOV AX, ADDR\n", "8B 46 04")
		assertAssemble(t, "OFFSET EQU 10h\nMOV AL, [BX + OFFSET]\n", "8A 47 10")
		assertAssemble(t, "A EQU 10h\nB EQU A + 5\nMOV AL, B\n", "B0 15")
		assertAssemble(t, "TARGET EQU LBL\nJMP SHORT TARGET\nLBL: NOP\n", "EB 00 90")
		assertAssemble(t, "EMPTY EQU\nMOV AX, EMPTY 1\n", "B8 01 00")
		assertAssemble(t, "VAL EQU 1\nMOV AX, VAL", "B8 01 00")
	})

	t.Run("DUP", func(t *testing.T) {
		assertAssemble(t, "DB 5 DUP(0)\n", "00 00 00 00 00")
		assertAssemble(t, "DB 3 DUP('A')\n", "41 41 41")
		assertAssemble(t, "DB 2 DUP('AB')\n", "41 42 41 42")
		assertAssemble(t, "DW 3 DUP(1234h)\n", "34 12 34 12 34 12")
		assertAssemble(t, "DW 2 DUP('AB')\n", "41 42 41 42")
		assertAssemble(t, "DD 2 DUP(1234h:5678h)\n", "78 56 34 12 78 56 34 12")
		assertAssemble(t, "DD 2 DUP('ABCD')\n", "41 42 43 44 41 42 43 44")
		assertAssemble(t, "DB 0 DUP(1)\nNOP\n", "90")
		assertAssemble(t, "DB 2 DUP(3 DUP(1))\n", "01 01 01 01 01 01")
		assertAssemble(t, "DB 2 DUP(3 DUP(2 DUP(7)))\n", "07 07 07 07 07 07 07 07 07 07 07 07")
		assertAssemble(t, "DB 2 DUP(1), 3 DUP(2), 3\n", "01 01 02 02 02 03")
		assertAssemble(t, "DB 2 DUP(10h + 5)\n", "15 15")
		assertAssemble(t, "COUNT EQU 3\nDB COUNT DUP(42h)\n", "42 42 42")
		assertAssemble(t, "DW 2 DUP(target)\ntarget: NOP\n", "04 00 04 00 90")
	})
}

func TestAssemble_SimpleInstructions(t *testing.T) {
	tests := []struct {
		src string
		hex string
	}{
		{"NOP\n", "90"},
		{"NOP", "90"},
		{"CBW\n", "98"},
		{"CWD\n", "99"},
		{"CLC\n", "F8"},
		{"STC\n", "F9"},
		{"CMC\n", "F5"},
		{"CLD\n", "FC"},
		{"STD\n", "FD"},
		{"CLI\n", "FA"},
		{"STI\n", "FB"},
		{"HLT\n", "F4"},
		{"WAIT\n", "9B"},
		{"PUSHF\n", "9C"},
		{"POPF\n", "9D"},
		{"SAHF\n", "9E"},
		{"LAHF\n", "9F"},
		{"INTO\n", "CE"},
		{"IRET\n", "CF"},
		{"XLAT\n", "D7"},
	}

	for _, tc := range tests {
		t.Run(strings.TrimSpace(tc.src), func(t *testing.T) {
			assertAssemble(t, tc.src, tc.hex)
		})
	}
}

func TestAssemble_StringInstructionsAndPrefixes(t *testing.T) {
	tests := []struct {
		src string
		hex string
	}{
		{"MOVSB\n", "A4"},
		{"MOVSW\n", "A5"},
		{"CMPSB\n", "A6"},
		{"CMPSW\n", "A7"},
		{"SCASB\n", "AE"},
		{"SCASW\n", "AF"},
		{"LODSB\n", "AC"},
		{"LODSW\n", "AD"},
		{"STOSB\n", "AA"},
		{"STOSW\n", "AB"},
		{"REP MOVSB\n", "F3 A4"},
		{"REPNE SCASB\n", "F2 AE"},
		{"REPE CMPSB\n", "F3 A6"},
		{"LOCK INC BYTE PTR [BX]\n", "F0 FE 07"},
	}

	for _, tc := range tests {
		t.Run(strings.TrimSpace(tc.src), func(t *testing.T) {
			assertAssemble(t, tc.src, tc.hex)
		})
	}
}

func TestAssemble_AamAad(t *testing.T) {
	assertAssemble(t, "AAM\n", "D4 0A")
	assertAssemble(t, "AAM 16\n", "D4 10")
	assertAssemble(t, "AAD\n", "D5 0A")
	assertAssemble(t, "AAD 16\n", "D5 10")
}

func TestAssemble_Returns(t *testing.T) {
	assertAssemble(t, "RET\n", "C3")
	assertAssemble(t, "RET 4\n", "C2 04 00")
	assertAssemble(t, "RETN\n", "C3")
	assertAssemble(t, "RETN 4\n", "C2 04 00")
	assertAssemble(t, "RETF\n", "CB")
	assertAssemble(t, "RETF 8\n", "CA 08 00")
}

func TestAssemble_Interrupts(t *testing.T) {
	assertAssemble(t, "INT 3\n", "CC")
	assertAssemble(t, "INT 21h\n", "CD 21")
	assertAssemble(t, "INT 0\n", "CD 00")
	assertAssemble(t, "INT 255\n", "CD FF")
}

func TestAssemble_InOut(t *testing.T) {
	assertAssemble(t, "IN AL, 60h\n", "E4 60")
	assertAssemble(t, "IN AX, 60h\n", "E5 60")
	assertAssemble(t, "IN AL, DX\n", "EC")
	assertAssemble(t, "IN AX, DX\n", "ED")
	assertAssemble(t, "OUT 60h, AL\n", "E6 60")
	assertAssemble(t, "OUT 60h, AX\n", "E7 60")
	assertAssemble(t, "OUT DX, AL\n", "EE")
	assertAssemble(t, "OUT DX, AX\n", "EF")
}

func TestAssemble_Stack(t *testing.T) {
	assertAssemble(t, "PUSH AX\n", "50")
	assertAssemble(t, "PUSH BX\n", "53")
	assertAssemble(t, "PUSH CX\n", "51")
	assertAssemble(t, "PUSH DX\n", "52")
	assertAssemble(t, "PUSH SP\n", "54")
	assertAssemble(t, "PUSH BP\n", "55")
	assertAssemble(t, "PUSH SI\n", "56")
	assertAssemble(t, "PUSH DI\n", "57")
	assertAssemble(t, "PUSH CS\n", "0E")
	assertAssemble(t, "PUSH SS\n", "16")
	assertAssemble(t, "PUSH DS\n", "1E")
	assertAssemble(t, "PUSH ES\n", "06")
	assertAssemble(t, "PUSH [BX]\n", "FF 37")
	assertAssemble(t, "POP AX\n", "58")
	assertAssemble(t, "POP BX\n", "5B")
	assertAssemble(t, "POP CX\n", "59")
	assertAssemble(t, "POP DX\n", "5A")
	assertAssemble(t, "POP SP\n", "5C")
	assertAssemble(t, "POP BP\n", "5D")
	assertAssemble(t, "POP SI\n", "5E")
	assertAssemble(t, "POP DI\n", "5F")
	assertAssemble(t, "POP SS\n", "17")
	assertAssemble(t, "POP DS\n", "1F")
	assertAssemble(t, "POP ES\n", "07")
	assertAssemble(t, "POP [BX]\n", "8F 07")

	assertAssembleError(t, "PUSH AL\n")
	assertAssembleError(t, "POP CS\n")
}

func TestAssemble_SegmentMov(t *testing.T) {
	assertAssemble(t, "MOV DS, AX\n", "8E D8")
	assertAssemble(t, "MOV AX, DS\n", "8C D8")
	assertAssemble(t, "MOV ES, [BX]\n", "8E 07")
	assertAssemble(t, "MOV [BX], ES\n", "8C 07")
	assertAssemble(t, "MOV AX, CS\n", "8C C8")

	assertAssembleError(t, "MOV CS, AX\n")
	assertAssembleError(t, "MOV CS, [BX]\n")
}

func TestAssemble_Arithmetic(t *testing.T) {
	t.Run("ADD", func(t *testing.T) {
		assertAssemble(t, "ADD AL, 1\n", "04 01")
		assertAssemble(t, "ADD AX, 1\n", "05 01 00")
		assertAssemble(t, "ADD AX, 127\n", "05 7F 00")
		assertAssemble(t, "ADD AX, 128\n", "05 80 00")
		assertAssemble(t, "ADD AX, 1000\n", "05 E8 03")
		assertAssemble(t, "ADD BX, 1000\n", "81 C3 E8 03")
		assertAssemble(t, "ADD BX, 127\n", "83 C3 7F")
		assertAssemble(t, "ADD BX, 128\n", "81 C3 80 00")
		assertAssemble(t, "ADD BX, -128\n", "83 C3 80")
		assertAssemble(t, "ADD BX, -129\n", "81 C3 7F FF")
		assertAssemble(t, "ADD [BX], AL\n", "00 07")
		assertAssemble(t, "ADD AL, [BX]\n", "02 07")
		assertAssemble(t, "ADD [BX], AX\n", "01 07")
		assertAssemble(t, "ADD AX, [BX]\n", "03 07")
		assertAssemble(t, "ADD BYTE PTR [BX], 1\n", "80 07 01")
		assertAssemble(t, "ADD WORD PTR [BX], 1\n", "83 07 01")
		assertAssemble(t, "ADD WORD PTR [BX], 1000\n", "81 07 E8 03")
	})

	t.Run("ADC", func(t *testing.T) {
		assertAssemble(t, "ADC AL, 5\n", "14 05")
		assertAssemble(t, "ADC AX, 5\n", "15 05 00")
		assertAssemble(t, "ADC BX, AX\n", "11 C3")
	})

	t.Run("SUB and SBB", func(t *testing.T) {
		assertAssemble(t, "SUB AL, 10\n", "2C 0A")
		assertAssemble(t, "SUB AX, 10\n", "2D 0A 00")
		assertAssemble(t, "SUB CX, 1\n", "83 E9 01")
		assertAssemble(t, "SBB AL, 2\n", "1C 02")
		assertAssemble(t, "SBB AX, 2\n", "1D 02 00")
	})

	t.Run("CMP", func(t *testing.T) {
		assertAssemble(t, "CMP AL, 5\n", "3C 05")
		assertAssemble(t, "CMP AX, 5\n", "3D 05 00")
		assertAssemble(t, "CMP DX, 127\n", "83 FA 7F")
		assertAssemble(t, "CMP DX, 128\n", "81 FA 80 00")
	})

	t.Run("AND OR XOR", func(t *testing.T) {
		assertAssemble(t, "AND AL, 0Fh\n", "24 0F")
		assertAssemble(t, "AND AX, 0FFh\n", "25 FF 00")
		assertAssemble(t, "AND BX, 0FFh\n", "81 E3 FF 00")
		assertAssemble(t, "OR AL, 80h\n", "0C 80")
		assertAssemble(t, "OR AX, 8000h\n", "0D 00 80")
		assertAssemble(t, "XOR AX, AX\n", "31 C0")
		assertAssemble(t, "XOR BX, BX\n", "31 DB")
	})
}

func TestAssemble_Test(t *testing.T) {
	assertAssemble(t, "TEST AL, 1\n", "A8 01")
	assertAssemble(t, "TEST AX, 1\n", "A9 01 00")
	assertAssemble(t, "TEST AX, 1000\n", "A9 E8 03")
	assertAssemble(t, "TEST BX, 1\n", "F7 C3 01 00")
	assertAssemble(t, "TEST BL, 1\n", "F6 C3 01")
	assertAssemble(t, "TEST [BX], AL\n", "84 07")
	assertAssemble(t, "TEST AL, [BX]\n", "84 07")
	assertAssemble(t, "TEST [BX], AX\n", "85 07")
	assertAssemble(t, "TEST AX, [BX]\n", "85 07")
	assertAssemble(t, "TEST BYTE PTR [BX], 1\n", "F6 07 01")
	assertAssemble(t, "TEST WORD PTR [BX], 1\n", "F7 07 01 00")
}

func TestAssemble_IncDec(t *testing.T) {
	assertAssemble(t, "INC AX\n", "40")
	assertAssemble(t, "INC AL\n", "FE C0")
	assertAssemble(t, "INC BYTE PTR [BX]\n", "FE 07")
	assertAssemble(t, "INC WORD PTR [BX]\n", "FF 07")
	assertAssemble(t, "DEC AX\n", "48")
	assertAssemble(t, "DEC AL\n", "FE C8")
	assertAssemble(t, "DEC BYTE PTR [BX]\n", "FE 0F")
	assertAssemble(t, "DEC WORD PTR [BX]\n", "FF 0F")
}

func TestAssemble_UnaryArithmetic(t *testing.T) {
	assertAssemble(t, "NOT AX\n", "F7 D0")
	assertAssemble(t, "NOT AL\n", "F6 D0")
	assertAssemble(t, "NOT BYTE PTR [BX]\n", "F6 17")
	assertAssemble(t, "NOT WORD PTR [BX]\n", "F7 17")
	assertAssemble(t, "NEG AX\n", "F7 D8")
	assertAssemble(t, "MUL BL\n", "F6 E3")
	assertAssemble(t, "IMUL BX\n", "F7 EB")
	assertAssemble(t, "DIV BYTE PTR [BX]\n", "F6 37")
	assertAssemble(t, "IDIV WORD PTR [BX]\n", "F7 3F")
}

func TestAssemble_ShiftsAndRotates(t *testing.T) {
	assertAssemble(t, "SHL AX, 1\n", "D1 E0")
	assertAssemble(t, "SHL AX, CL\n", "D3 E0")
	assertAssemble(t, "SHR AL, 1\n", "D0 E8")
	assertAssemble(t, "SHR AL, CL\n", "D2 E8")
	assertAssemble(t, "SAR AX, 1\n", "D1 F8")
	assertAssemble(t, "SAR AX, CL\n", "D3 F8")
	assertAssemble(t, "ROL BYTE PTR [BX], 1\n", "D0 07")
	assertAssemble(t, "ROR WORD PTR [BX], CL\n", "D3 0F")
	assertAssemble(t, "RCL AX, 1\n", "D1 D0")
	assertAssemble(t, "RCR AX, CL\n", "D3 D8")
}

func TestAssemble_Xchg(t *testing.T) {
	assertAssemble(t, "XCHG AX, AX\n", "90")
	assertAssemble(t, "XCHG AX, BX\n", "93")
	assertAssemble(t, "XCHG BX, AX\n", "93")
	assertAssemble(t, "XCHG AX, [BX]\n", "87 07")
	assertAssemble(t, "XCHG [BX], AX\n", "87 07")
	assertAssemble(t, "XCHG AL, [BX]\n", "86 07")
	assertAssemble(t, "XCHG [BX], AL\n", "86 07")
	assertAssemble(t, "XCHG AL, BL\n", "86 D8")
	assertAssemble(t, "XCHG BL, AL\n", "86 C3")
}

func TestAssemble_AddressingModes(t *testing.T) {
	assertAssemble(t, "MOV AX, [BX]\n", "8B 07")
	assertAssemble(t, "MOV AX, [BP]\n", "8B 46 00")
	assertAssemble(t, "MOV AX, [SI]\n", "8B 04")
	assertAssemble(t, "MOV AX, [DI]\n", "8B 05")
	assertAssemble(t, "MOV AX, [BX+SI]\n", "8B 00")
	assertAssemble(t, "MOV AX, [BX+DI]\n", "8B 01")
	assertAssemble(t, "MOV AX, [BP+SI]\n", "8B 02")
	assertAssemble(t, "MOV AX, [BP+DI]\n", "8B 03")
	assertAssemble(t, "MOV AX, [1234h]\n", "A1 34 12")
	assertAssemble(t, "MOV BX, [1234h]\n", "8B 1E 34 12")
	assertAssemble(t, "MOV AX, [BX+4]\n", "8B 47 04")
	assertAssemble(t, "MOV AX, [BX+1234h]\n", "8B 87 34 12")
	assertAssemble(t, "MOV AX, [BX-1]\n", "8B 47 FF")
	assertAssemble(t, "MOV AX, [BP+4]\n", "8B 46 04")
	assertAssemble(t, "MOV AX, [BP-4]\n", "8B 46 FC")
	assertAssemble(t, "MOV AX, [+4+BX]\n", "8B 47 04")
	assertAssemble(t, "MOV AX, [BX+SI+1234h]\n", "8B 80 34 12")
}

func TestAssemble_SegmentOverrides(t *testing.T) {
	assertAssemble(t, "MOV AX, ES:[BX]\n", "26 8B 07")
	assertAssemble(t, "MOV AX, CS:[BX]\n", "2E 8B 07")
	assertAssemble(t, "MOV AX, SS:[BX]\n", "36 8B 07")
	assertAssemble(t, "MOV AX, DS:[BP]\n", "3E 8B 46 00")
	assertAssemble(t, "MOV AX, SS:[BP]\n", "8B 46 00") // default SS suppressed
	assertAssemble(t, "MOV AX, DS:[BX]\n", "8B 07")    // default DS suppressed
	assertAssemble(t, "MOV AL, ES:[1234h]\n", "26 A0 34 12")
	assertAssemble(t, "MOV ES:[1234h], AL\n", "26 A2 34 12")
	assertAssemble(t, "MOV BX, ES:[1234h]\n", "26 8B 1E 34 12")
}

func TestAssemble_LoadAddress(t *testing.T) {
	assertAssemble(t, "LEA AX, [BX+SI]\n", "8D 00")
	assertAssemble(t, "LEA AX, [BX+SI+10h]\n", "8D 40 10")
	assertAssemble(t, "LDS BX, [SI]\n", "C5 1C")
	assertAssemble(t, "LES DI, [BP+4]\n", "C4 7E 04")
}

func TestAssemble_JumpsAndCalls(t *testing.T) {
	t.Run("Direct and Relative", func(t *testing.T) {
		assertAssemble(t, "start: JMP start\n", "EB FE")
		assertAssemble(t, "target: NOP\nJMP target\n", "90 EB FD")
		assertAssemble(t, "JMP short forward\nNOP\nforward: NOP\n", "EB 01 90 90")
		assertAssemble(t, "JMP forward\nNOP\nforward: NOP\n", "E9 01 00 90 90")
		assertAssemble(t, "JZ forward\nNOP\nforward: NOP\n", "74 01 90 90")
	})

	t.Run("Indirect Jumps and Calls", func(t *testing.T) {
		assertAssemble(t, "JMP AX\n", "FF E0")
		assertAssemble(t, "JMP [BX]\n", "FF 27")
		assertAssemble(t, "JMP WORD PTR [BX]\n", "FF 27")
		assertAssemble(t, "JMP DWORD PTR [BX]\n", "FF 2F")
		assertAssemble(t, "JMP FAR [BX]\n", "FF 2F")
		assertAssemble(t, "target DW 100h\nJMP [target]\n", "00 01 FF 26 00 00")
		assertAssemble(t, "target DD 100h:200h\nJMP [target]\n", "00 02 00 01 FF 2E 00 00")

		assertAssemble(t, "CALL AX\n", "FF D0")
		assertAssemble(t, "CALL [BX]\n", "FF 17")
		assertAssemble(t, "CALL WORD PTR [BX]\n", "FF 17")
		assertAssemble(t, "CALL DWORD PTR [BX]\n", "FF 1F")
		assertAssemble(t, "CALL FAR [BX]\n", "FF 1F")
		assertAssemble(t, "target DW 100h\nCALL [target]\n", "00 01 FF 16 00 00")
		assertAssemble(t, "target DD 100h:200h\nCALL [target]\n", "00 02 00 01 FF 1E 00 00")
	})
}

func TestAssemble_ConditionalJumps(t *testing.T) {
	jumps := []struct {
		mnemonic string
		opcode   string
	}{
		{"JA", "77"}, {"JAE", "73"}, {"JB", "72"}, {"JBE", "76"},
		{"JC", "72"}, {"JCXZ", "E3"}, {"JE", "74"}, {"JG", "7F"},
		{"JGE", "7D"}, {"JL", "7C"}, {"JLE", "7E"}, {"JNA", "76"},
		{"JNAE", "72"}, {"JNB", "73"}, {"JNBE", "77"}, {"JNC", "73"},
		{"JNE", "75"}, {"JNG", "7E"}, {"JNGE", "7C"}, {"JNL", "7D"},
		{"JNLE", "7F"}, {"JNO", "71"}, {"JNP", "7B"}, {"JNS", "79"},
		{"JNZ", "75"}, {"JO", "70"}, {"JP", "7A"}, {"JPE", "7A"},
		{"JPO", "7B"}, {"JS", "78"}, {"JZ", "74"},
		{"LOOP", "E2"}, {"LOOPE", "E1"}, {"LOOPNE", "E0"},
		{"LOOPNZ", "E0"}, {"LOOPZ", "E1"},
	}

	for _, j := range jumps {
		t.Run(j.mnemonic, func(t *testing.T) {
			src := fmt.Sprintf("target: NOP\n%s target\n", j.mnemonic)
			assertAssemble(t, src, fmt.Sprintf("90 %s FD", j.opcode))
		})
	}
}

func TestAssemble_LabelsAndExpressions(t *testing.T) {
	t.Run("Labels", func(t *testing.T) {
		assertAssemble(t, "foo: NOP\n", "90")
		assertAssemble(t, "foo:\nNOP\n", "90")
		assertAssemble(t, "foo DW 1234h\n", "34 12")
		assertAssemble(t, "lbl1:\nlbl2:\nMOV AX, 1\n", "B8 01 00")
		assertAssemble(t, "lbl1:\nlbl2:\nDW lbl1, lbl2\n", "00 00 00 00")
	})

	t.Run("Negative Numbers", func(t *testing.T) {
		assertAssemble(t, "MOV AL, -1\n", "B0 FF")
		assertAssemble(t, "MOV AL, -128\n", "B0 80")
		assertAssemble(t, "MOV AX, -1\n", "B8 FF FF")
		assertAssemble(t, "DB -1\n", "FF")
		assertAssemble(t, "DB -128\n", "80")
		assertAssemble(t, "DW -1\n", "FF FF")
	})

	t.Run("Arithmetic Expressions", func(t *testing.T) {
		assertAssemble(t, "MOV AX, +1\n", "B8 01 00")
		assertAssemble(t, "MOV AX, 1 + 2\n", "B8 03 00")
		assertAssemble(t, "MOV AX, 5 - 2\n", "B8 03 00")
		assertAssemble(t, "MOV AX, 10 - 2 + 5\n", "B8 0D 00")
	})

	t.Run("Phase Error Label Offset Zero", func(t *testing.T) {
		// Label displacement in pointer that evaluates to 0 in pass 2 must maintain word displacement
		assertAssemble(t, "target: NOP\nMOV AX, [target - target + BX]\n", "90 8B 87 00 00")
	})

	t.Run("Sized Labels", func(t *testing.T) {
		// Inferred read
		assertAssemble(t, "b DB 12h\nMOV AL, [b]\n", "12 A0 00 00")
		assertAssemble(t, "w DW 1234h\nMOV AX, [w]\n", "34 12 A1 00 00")

		// Inferred write
		assertAssemble(t, "b DB 12h\nMOV [b], AL\n", "12 A2 00 00")
		assertAssemble(t, "w DW 1234h\nMOV [w], AX\n", "34 12 A3 00 00")

		// Inferred immediate store
		assertAssemble(t, "w DW 0\nMOV [w], 1234h\n", "00 00 C7 06 00 00 34 12")

		// Explicit PTR overrides over sized labels
		assertAssemble(t, "w DW 1234h\nMOV AL, BYTE PTR [w]\n", "34 12 A0 00 00")
		assertAssemble(t, "b DB 12h\nMOV AX, WORD PTR [b]\n", "12 A1 00 00")
	})

	t.Run("Forward Label in Arithmetic", func(t *testing.T) {
		assertAssemble(t, "ADD BX, target\nNOP\ntarget:\nJMP target\n", "81 C3 05 00 90 EB FE")
	})
}

func TestAssemble_Errors(t *testing.T) {
	tests := []struct {
		name string
		src  string
	}{
		{"Invalid register size in PUSH", "PUSH AL\n"},
		{"Invalid segment register in POP", "POP CS\n"},
		{"Invalid destination segment in MOV", "MOV CS, AX\n"},
		{"Invalid destination segment from mem in MOV", "MOV CS, [BX]\n"},
		{"Duplicate label", "lbl: NOP\nlbl: NOP\n"},
		{"Byte overflow", "MOV AL, 300\n"},
		{"DB overflow", "DB 300\n"},
		{"Backward ORG", "ORG 100h\nNOP\nORG 50h\nNOP\n"},
		{"Mismatch DB label with word register", "b DB 12h\nMOV AX, [b]\n"},
		{"Mismatch DW label with byte register", "w DW 1234h\nMOV AL, [w]\n"},
		{"Invalid indirect JMP via DB", "target DB 10h\nJMP [target]\n"},
		{"Invalid indirect CALL via DB", "target DB 10h\nCALL [target]\n"},
		{"Collision: code label then EQU", "LBL: NOP\nLBL EQU 10\n"},
		{"Collision: data label then EQU", "DATA DB 1\nDATA EQU 10\n"},
		{"Collision: EQU then code label", "FOO EQU 10\nFOO: NOP\n"},
		{"Duplicate EQU definition", "VAL EQU 1\nVAL EQU 2\n"},
		{"Forward reference to EQU", "MOV AX, VAL\nVAL EQU 42h\n"},
		{"Colon before EQU", "VAL: EQU 10\n"},
		{"EQU without identifier", "EQU 10\n"},
		{"DUP without left parenthesis", "DB 5 DUP 0)\n"},
		{"DUP without right parenthesis", "DB 5 DUP(0\n"},
		{"Nested DUP missing right parenthesis", "DB 2 DUP(3 DUP(1)\n"},
		{"DUP with empty parentheses", "DB 5 DUP()\n"},
		{"DUP without count", "DB DUP(0)\n"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			assertAssembleError(t, tc.src)
		})
	}
}
