package assemble

import (
	"fmt"
	"strings"
)

type argument struct {
	argType  argType
	value    uint16
	value2   uint16
	regSeg   regSeg
	eaMode   eaMode
	distance distance
	string   string
}

func (a *argument) IsNum() bool {
	return a.argType.Class() == argNum
}

func (a *argument) IsReg() bool {
	return a.argType.Class() == argReg
}

func (a *argument) IsSeg() bool {
	return a.argType.Class() == argSeg
}

func (a *argument) IsAccumulator() bool {
	return a.argType.Class() == argReg && a.regSeg == AX
}

func (a *argument) IsPtr() bool {
	return a.argType.Class() == argPtr
}

func (a *argument) IsNoSize() bool {
	return a.argType.Size() == 0
}

func (a *argument) IsByte() bool {
	return a.argType.Size() == sizeByte
}

func (a *argument) IsWord() bool {
	return a.argType.Size() == sizeWord || a.argType == argNum|sizeByte || a.argType == argSeg
}

func (a *argument) IsDword() bool {
	return a.argType.Size() == sizeDword
}

func (a *argument) String() string {
	sb := strings.Builder{}
	switch a.distance {
	case short:
		sb.WriteString("short ")
	case near:
		sb.WriteString("near ")
	case far:
		sb.WriteString("far ")
	default:
		// do nothing
	}
	sb.WriteString(a.argType.String())
	sb.WriteByte(' ')
	switch a.argType & argClassMask {
	case argNum:
		switch a.argType & sizeMask {
		case sizeByte:
			_, _ = fmt.Fprintf(&sb, "%02X", a.value)
		case sizeDword:
			_, _ = fmt.Fprintf(&sb, "%04Xh:%04Xh", a.value, a.value2)
		default:
			_, _ = fmt.Fprintf(&sb, "%04Xh", a.value)
		}
	case argString:
		sb.WriteByte('\'')
		sb.WriteString(a.string)
		sb.WriteByte('\'')
	case argReg:
		switch a.argType & sizeMask {
		case sizeByte:
			sb.WriteString(regSegs[a.regSeg+8])
		default:
			sb.WriteString(regSegs[a.regSeg])
		}
	case argSeg:
		sb.WriteString(regSegs[a.regSeg+16])
	case argPtr:
		switch a.argType & sizeMask {
		case sizeByte:
			sb.WriteString("BYTE PTR ")
		case sizeWord:
			sb.WriteString("WORD PTR ")
		case sizeDword:
			sb.WriteString("DWORD PTR ")
		}
		if a.eaMode&eaSegment != 0 {
			sb.WriteString(regSegs[a.regSeg+16])
			sb.WriteByte(':')
		}
		sb.WriteByte('[')
		if a.eaMode&^eaSegment == eaDirect {
			_, _ = fmt.Fprintf(&sb, "%04Xh", a.value)
		} else {
			sb.WriteString(eaModes[a.eaMode&0x07])
			if a.eaMode&eaOffset != 0 {
				_, _ = fmt.Fprintf(&sb, " + %04Xh", a.value)
			}
		}
		sb.WriteByte(']')
	default:
		sb.WriteString("argument")
	}
	return sb.String()
}

type argType uint8

const (
	argNum       argType = 0x1
	argString    argType = 0x2
	argReg       argType = 0x3
	argSeg       argType = 0x4
	argPtr       argType = 0x5
	argClassMask         = 0x0f

	sizeByte  argType = 0x10
	sizeWord  argType = 0x20
	sizeDword argType = 0x30
	sizeMask          = 0xf0
)

var atypes = []string{
	argNum:             "number",
	argNum | sizeByte:  "byte",
	argNum | sizeWord:  "word",
	argNum | sizeDword: "dword",
	argString:          "string",
	argReg | sizeByte:  "byte register",
	argReg | sizeWord:  "word register",
	argSeg:             "segment",
	argPtr:             "pointer",
	argPtr | sizeByte:  "byte pointer",
	argPtr | sizeWord:  "word pointer",
	argPtr | sizeDword: "dword pointer",
}

func (a argType) Class() argType {
	return a & argClassMask
}

func (a argType) Size() argType {
	switch a & argClassMask {
	case argNum, argReg, argPtr:
		return a & sizeMask
	default:
		return 0
	}
}

func (a argType) WithSize(size argType) argType {
	t := a & argClassMask
	switch t {
	case argNum, argReg, argPtr:
		return t | (size & sizeMask)
	default:
		return t
	}
}

func (a argType) String() string {
	return atypes[a]
}

type regSeg uint8

const (
	AX regSeg = 0
	CX regSeg = 1
	DX regSeg = 2
	BX regSeg = 3
	SP regSeg = 4
	BP regSeg = 5
	SI regSeg = 6
	DI regSeg = 7

	AL regSeg = 0
	CL regSeg = 1
	DL regSeg = 2
	BL regSeg = 3
	AH regSeg = 4
	CH regSeg = 5
	DH regSeg = 6
	BH regSeg = 7

	ES regSeg = 0
	CS regSeg = 1
	SS regSeg = 2
	DS regSeg = 3
)

var regSegs = []string{
	"AX", "CX", "DX", "BX", "SP", "BP", "SI", "DI",
	"AL", "CL", "DL", "BL", "AH", "CH", "DH", "BH",
	"ES", "CS", "SS", "DS",
}

type eaMode uint8

const (
	eaBxSi     eaMode = 0
	eaBxDi     eaMode = 1
	eaBpSi     eaMode = 2
	eaBpDi     eaMode = 3
	eaSi       eaMode = 4
	eaDi       eaMode = 5
	eaBp       eaMode = 6
	eaDirect   eaMode = 6
	eaBx       eaMode = 7
	eaOffset   eaMode = 8
	eaOffset16 eaMode = 16
	eaSegment  eaMode = 32
)

var eaModes = []string{
	"BX + SI", "BX + DI", "BP + SI", "BP + DI",
	"SI", "DI", "BP", "BX",
}

type distance uint8

const (
	short distance = 1
	near  distance = 2
	far   distance = 3
)
