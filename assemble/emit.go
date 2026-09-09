package assemble

import (
	"fmt"

	"github.com/jtarrio/pasm/parse"
)

func (a *assembler) emitByte(b byte) error {
	a.pc++
	if a.pass == 1 || a.out == nil {
		return nil
	}
	return a.out.WriteByte(b)
}

func (a *assembler) emitWord(w uint16) error {
	if err := a.emitByte(byte(w)); err != nil {
		return err
	}
	return a.emitByte(byte(w >> 8))
}

func (a *assembler) emitDword(w1, w2 uint16) error {
	if err := a.emitWord(w1); err != nil {
		return err
	}
	return a.emitWord(w2)
}

func (a *assembler) emitString(s string) error {
	return a.emitBytes([]byte(s)...)
}

func (a *assembler) emitBytes(b ...byte) error {
	for _, c := range b {
		if err := a.emitByte(c); err != nil {
			return err
		}
	}
	return nil
}

func (a *assembler) emitOrg(addr uint16) error {
	if a.pc == 0 {
		a.pc = addr
	} else if a.pc > addr {
		return a.error(fmt.Sprintf("ORG address (%04Xh) before program counter (%04Xh)", addr, a.pc))
	}
	for a.pc < addr {
		if err := a.emitByte(0); err != nil {
			return err
		}
	}
	return nil
}

func (a *assembler) emitPrefix(kw parse.Keyword) error {
	switch kw {
	case parse.LOCK:
		return a.emitByte(0b11110000)
	case parse.REP, parse.REPE, parse.REPZ:
		return a.emitByte(0b11110011)
	case parse.REPNE, parse.REPNZ:
		return a.emitByte(0b11110010)
	default:
		return a.error(fmt.Sprintf("expected a LOCK or REP prefix, got %s", kw))
	}
}

func (a *assembler) emitSegment(seg regSeg) error {
	return a.emitByte(0b00100110 | byte(seg<<3))
}

func (a *assembler) emitInstruction(kw parse.Keyword, arg1, arg2 *argument) error {
	if arg1 != nil && arg1.argType&argClassMask == argPtr && arg1.eaMode&eaSegment != 0 {
		arg1.eaMode &= ^eaSegment
		if err := a.emitSegment(arg1.regSeg); err != nil {
			return err
		}
	}
	if arg2 != nil && arg2.argType&argClassMask == argPtr && arg2.eaMode&eaSegment != 0 {
		arg2.eaMode &= ^eaSegment
		if err := a.emitSegment(arg2.regSeg); err != nil {
			return err
		}
	}
	return ops[kw].emit(a, arg1, arg2)
}

func (a *assembler) emitRm(opcode byte, ext byte, arg *argument, rest ...byte) error {
	if err := a.emitByte(opcode); err != nil {
		return err
	}

	sup := byte(0)
	sub := byte(0)
	switch arg.argType & argClassMask {
	case argReg:
		sup = 0b11
		sub = byte(arg.regSeg)
	case argPtr:
		sub = byte(arg.eaMode & 0b111)
		if arg.eaMode&eaOffset == 0 {
			sup = 0
		} else if arg.eaMode&eaOffset16 == 0 && int16(arg.value) >= -128 && int16(arg.value) <= 127 {
			sup = 0b01
		} else {
			sup = 0b10
		}
	default:
		return a.errorArg("invalid argument", arg)
	}

	if err := a.emitByte((sup << 6) | ((ext & 0b111) << 3) | sub); err != nil {
		return err
	}

	if sup == 0b01 {
		if err := a.emitByte(byte(arg.value)); err != nil {
			return err
		}
	} else if sup == 0b10 || (sup == 0 && arg.eaMode == eaDirect) {
		if err := a.emitWord(arg.value); err != nil {
			return err
		}
	}

	if len(rest) > 0 {
		return a.emitBytes(rest...)
	}
	return nil
}

func (a *assembler) emitRmWidth1(opcode byte, ext byte, arg *argument, rest ...byte) (error, bool) {
	if arg.IsByte() {
		return a.emitRm(opcode, ext, arg, rest...), true
	}
	if arg.IsWord() {
		return a.emitRm(opcode|1, ext, arg, rest...), true
	}
	return nil, false
}

func (a *assembler) emitRmWidth2(opcode byte, ext byte, a1, a2 *argument, rest ...byte) (error, bool) {
	if a1.IsByte() && a2.IsByte() {
		return a.emitRm(opcode, ext, a1, rest...), true
	}
	if a1.IsWord() && a2.IsWord() {
		return a.emitRm(opcode|1, ext, a1, rest...), true
	}
	return nil, false
}

func (a *assembler) emitRmImm(opcode byte, ext byte, a1, a2 *argument, signExtend bool) (error, bool) {
	if a1.IsByte() && a2.IsByte() {
		return a.emitRm(opcode, ext, a1, byte(a2.value)), true
	}
	if a1.IsWord() && a2.IsByte() && signExtend && int16(a2.value) <= 127 {
		return a.emitRm(opcode|3, ext, a1, byte(a2.value)), true
	}
	if a1.IsWord() && a2.IsWord() {
		return a.emitRm(opcode|1, ext, a1, byte(a2.value), byte(a2.value>>8)), true
	}
	return nil, false
}

func (a *assembler) emitShortJmp(opcode byte, arg *argument) error {
	disp := int16(arg.value - (a.pc + 2))
	if a.pass == 2 && (disp < -128 || disp > 127) {
		return a.error("destination address is too far for a short jump")
	}
	return a.emitBytes(opcode, byte(disp))
}

var ops = [...]opPattern{
	parse.AAA:    noArgs{0b00110111},
	parse.AAD:    aamaad{0b11010101},
	parse.AAM:    aamaad{0b11010100},
	parse.AAS:    noArgs{0b00111111},
	parse.ADC:    arith{0b00010100, 0b00010000, 0b10000000, 0b010, true, false},
	parse.ADD:    arith{0b00000100, 0b00000000, 0b10000000, 0b000, true, false},
	parse.AND:    arith{0b00100100, 0b00100000, 0b10000000, 0b100, false, false},
	parse.CALL:   jmpCall{0, 0b11101000, 0b10011010, 0b11111111, 0b010, 0b011},
	parse.CBW:    noArgs{0b10011000},
	parse.CLC:    noArgs{0b11111000},
	parse.CLD:    noArgs{0b11111100},
	parse.CLI:    noArgs{0b11111010},
	parse.CMC:    noArgs{0b11110101},
	parse.CMPSB:  noArgs{0b10100110},
	parse.CMPSW:  noArgs{0b10100111},
	parse.CMP:    arith{0b00111100, 0b00111000, 0b10000000, 0b111, true, false},
	parse.CWD:    noArgs{0b10011001},
	parse.DAA:    noArgs{0b00100111},
	parse.DAS:    noArgs{0b00101111},
	parse.DEC:    unary{0b01001000, 0b11111110, 0b001},
	parse.DIV:    unary{0, 0b11110110, 0b110},
	parse.HLT:    noArgs{0b11110100},
	parse.ESC:    esc{},
	parse.IDIV:   unary{0, 0b11110110, 0b111},
	parse.IMUL:   unary{0, 0b11110110, 0b101},
	parse.IN:     inOut{0b11100100, 0b11101100, false},
	parse.INC:    unary{0b01000000, 0b11111110, 0b000},
	parse.INT:    interrupt{0b11001100, 0b11001101},
	parse.INTO:   noArgs{0b11001110},
	parse.IRET:   noArgs{0b11001111},
	parse.JA:     jmpShort{0b01110111},
	parse.JAE:    jmpShort{0b01110011},
	parse.JB:     jmpShort{0b01110010},
	parse.JBE:    jmpShort{0b01110110},
	parse.JC:     jmpShort{0b01110010},
	parse.JCXZ:   jmpShort{0b11100011},
	parse.JE:     jmpShort{0b01110100},
	parse.JG:     jmpShort{0b01111111},
	parse.JGE:    jmpShort{0b01111101},
	parse.JL:     jmpShort{0b01111100},
	parse.JLE:    jmpShort{0b01111110},
	parse.JMP:    jmpCall{0b11101011, 0b11101001, 0b11101010, 0b11111111, 0b100, 0b101},
	parse.JNA:    jmpShort{0b01110110},
	parse.JNAE:   jmpShort{0b01110010},
	parse.JNB:    jmpShort{0b01110011},
	parse.JNBE:   jmpShort{0b01110111},
	parse.JNC:    jmpShort{0b01110011},
	parse.JNE:    jmpShort{0b01110101},
	parse.JNG:    jmpShort{0b01111110},
	parse.JNGE:   jmpShort{0b01111100},
	parse.JNL:    jmpShort{0b01111101},
	parse.JNLE:   jmpShort{0b01111111},
	parse.JNO:    jmpShort{0b01110001},
	parse.JNP:    jmpShort{0b01111011},
	parse.JNS:    jmpShort{0b01111001},
	parse.JNZ:    jmpShort{0b01110101},
	parse.JO:     jmpShort{0b01110000},
	parse.JP:     jmpShort{0b01111010},
	parse.JPE:    jmpShort{0b01111010},
	parse.JPO:    jmpShort{0b01111011},
	parse.JS:     jmpShort{0b01111000},
	parse.JZ:     jmpShort{0b01110100},
	parse.LAHF:   noArgs{0b10011111},
	parse.LDS:    loadAddr{0b11000101},
	parse.LEA:    loadAddr{0b10001101},
	parse.LES:    loadAddr{0b11000100},
	parse.LODSB:  noArgs{0b10101100},
	parse.LODSW:  noArgs{0b10101101},
	parse.LOOP:   jmpShort{0b11100010},
	parse.LOOPE:  jmpShort{0b11100001},
	parse.LOOPNE: jmpShort{0b11100000},
	parse.LOOPNZ: jmpShort{0b11100000},
	parse.LOOPZ:  jmpShort{0b11100001},
	parse.MOV:    mov{0b10100000, 0b10110000, 0b10001000, 0b11000110, 0b000, 0b10001100},
	parse.MOVSB:  noArgs{0b10100100},
	parse.MOVSW:  noArgs{0b10100101},
	parse.MUL:    unary{0, 0b11110110, 0b100},
	parse.NEG:    unary{0, 0b11110110, 0b011},
	parse.NOT:    unary{0, 0b11110110, 0b010},
	parse.NOP:    noArgs{0b10010000},
	parse.OR:     arith{0b00001100, 0b00001000, 0b10000000, 0b001, false, false},
	parse.OUT:    inOut{0b11100110, 0b11101110, true},
	parse.POP:    stack{0b01011000, 0b10001111, 0b000, 0b00000111},
	parse.POPF:   noArgs{0b10011101},
	parse.PUSH:   stack{0b01010000, 0b11111111, 0b110, 0b00000110},
	parse.PUSHF:  noArgs{0b10011100},
	parse.RCL:    rotate{0b11010000, 0b010},
	parse.RCR:    rotate{0b11010000, 0b011},
	parse.RET:    ret{0b11000011, 0b11000010},
	parse.RETF:   ret{0b11001011, 0b11001010},
	parse.RETN:   ret{0b11000011, 0b11000010},
	parse.ROL:    rotate{0b11010000, 0b000},
	parse.ROR:    rotate{0b11010000, 0b001},
	parse.SAHF:   noArgs{0b10011110},
	parse.SAL:    rotate{0b11010000, 0b100},
	parse.SAR:    rotate{0b11010000, 0b111},
	parse.SBB:    arith{0b00011100, 0b00011000, 0b10000000, 0b011, true, false},
	parse.SCASB:  noArgs{0b10101110},
	parse.SCASW:  noArgs{0b10101111},
	parse.SHL:    rotate{0b11010000, 0b100},
	parse.SHR:    rotate{0b11010000, 0b101},
	parse.STC:    noArgs{0b11111001},
	parse.STD:    noArgs{0b11111101},
	parse.STOSB:  noArgs{0b10101010},
	parse.STOSW:  noArgs{0b10101011},
	parse.STI:    noArgs{0b11111011},
	parse.SUB:    arith{0b00101100, 0b00101000, 0b10000000, 0b101, true, false},
	parse.TEST:   arith{0b10101000, 0b10000100, 0b11110110, 0b000, false, true},
	parse.WAIT:   noArgs{0b10011011},
	parse.XCHG:   xchg{0b10010000, 0b10000110},
	parse.XLAT:   noArgs{0b11010111},
	parse.XOR:    arith{0b00110100, 0b00110000, 0b10000000, 0b110, false, false},
}

type opPattern interface {
	emit(a *assembler, arg1, arg2 *argument) error
}
type noArgs struct {
	opcode byte
}

func (o noArgs) emit(a *assembler, a1, _ *argument) error {
	if err := expect0Arg(a, a1); err != nil {
		return err
	}
	return a.emitByte(o.opcode)
}

type aamaad struct {
	opcode byte
}

func (o aamaad) emit(a *assembler, a1, a2 *argument) error {
	if a1 == nil {
		return a.emitBytes(o.opcode, 10)
	}

	if err := expect1Arg(a, a1, a2); err != nil {
		return err
	}
	if a1.argType == argNum|sizeByte {
		return a.emitBytes(o.opcode, byte(a1.value))
	}

	return a.error(fmt.Sprintf("invalid argument: %s", a1))
}

type arith struct {
	acImmOpcode byte
	regRmOpcode byte
	rmImmOpcode byte
	rmImmExt    byte
	signExtend  bool
	isTest      bool
}

func (o arith) emit(a *assembler, a1, a2 *argument) error {
	if err := expect2Arg(a, a2); err != nil {
		return err
	}

	equateSizes(a1, a2)

	if a1.IsAccumulator() && a2.IsNum() {
		if a1.IsByte() && a2.IsByte() {
			return a.emitBytes(o.acImmOpcode, byte(a2.value))
		}
		if a1.IsWord() && a2.IsWord() {
			return a.emitBytes(o.acImmOpcode|1, byte(a2.value), byte(a2.value>>8))
		}
	}

	if (a1.IsReg() || a1.IsPtr()) && a2.IsNum() {
		if err, done := a.emitRmImm(o.rmImmOpcode, o.rmImmExt, a1, a2, o.signExtend); done {
			return err
		}
	}
	if (a1.IsReg() || a1.IsPtr()) && a2.IsReg() {
		if err, done := a.emitRmWidth2(o.regRmOpcode, byte(a2.regSeg), a1, a2); done {
			return err
		}
	}
	if a1.IsReg() && (a2.IsReg() || a2.IsPtr()) {
		op := o.regRmOpcode
		if !o.isTest {
			op |= 2
		}
		if err, done := a.emitRmWidth2(op, byte(a1.regSeg), a2, a1); done {
			return err
		}
	}

	return a.error(fmt.Sprintf("invalid arguments: %s and %s", a1, a2))
}

type jmpCall struct {
	shortDirectOpcode byte
	nearDirectOpcode  byte
	farDirectOpcode   byte
	indirectOpcode    byte
	nearExt           byte
	farExt            byte
}

func (o jmpCall) emit(a *assembler, a1, a2 *argument) error {
	if err := expect1Arg(a, a1, a2); err != nil {
		return err
	}

	if (a1.IsNum() && a1.IsByte()) || a1.IsNoSize() {
		a1.argType = a1.argType.WithSize(sizeWord)
	}
	if a1.distance == 0 && a1.IsWord() && a1.IsNum() {
		disp := int16(a1.value - (a.pc + 2))
		if disp >= -128 && disp < 0 {
			a1.distance = short
		} else {
			a1.distance = near
		}
	} else if a1.distance == 0 && a1.IsWord() && !a1.IsNum() {
		a1.distance = near
	} else if a1.distance == 0 && a1.IsDword() {
		a1.distance = far
	} else if a1.distance == near && a1.IsNoSize() {
		a1.argType = a1.argType.WithSize(sizeWord)
	} else if a1.distance == far && a1.IsNoSize() {
		a1.argType = a1.argType.WithSize(sizeDword)
	}

	if a1.IsNum() {
		if a1.IsWord() && a1.distance == short && o.shortDirectOpcode != 0 {
			return a.emitShortJmp(o.shortDirectOpcode, a1)
		}
		if a1.IsWord() && a1.distance == near {
			disp := a1.value - (a.pc + 3)
			return a.emitBytes(o.nearDirectOpcode, byte(disp), byte(disp>>8))
		}
		if a1.IsDword() && a1.distance == far {
			return a.emitBytes(o.farDirectOpcode, byte(a1.value2), byte(a1.value2>>8), byte(a1.value), byte(a1.value>>8))
		}
	}
	if a1.IsReg() || a1.IsPtr() {
		if a1.IsWord() && a1.distance == near {
			return a.emitRm(o.indirectOpcode, o.nearExt, a1)
		}
		if a1.IsDword() && a1.distance == far {
			return a.emitRm(o.indirectOpcode, o.farExt, a1)
		}
	}

	return a.error(fmt.Sprintf("invalid argument: %s", a1))
}

type unary struct {
	regOpcode byte
	rmOpcode  byte
	rmExt     byte
}

func (o unary) emit(a *assembler, a1, a2 *argument) error {
	if err := expect1Arg(a, a1, a2); err != nil {
		return err
	}

	if a1.IsWord() && a1.IsReg() && o.regOpcode != 0 {
		return a.emitByte(o.regOpcode | byte(a1.regSeg))
	}
	if a1.IsReg() || a1.IsPtr() {
		if err, done := a.emitRmWidth1(o.rmOpcode, o.rmExt, a1); done {
			return err
		}
	}

	return a.error(fmt.Sprintf("invalid argument: %s", a1))
}

type esc struct{}

func (o esc) emit(a *assembler, a1, a2 *argument) error {
	if err := expect2Arg(a, a2); err != nil {
		return err
	}

	if a1.IsNum() && a1.value <= 0b111111 {
		v1 := byte((a1.value & 0b111000) >> 3)
		v2 := byte(a1.value & 0b000111)
		return a.emitRm(0b11011000|v1, v2, a2)
	}

	return a.error(fmt.Sprintf("invalid argument: %s", a1))
}

type inOut struct {
	fixedPortOpcode    byte
	variablePortOpcode byte
	isOut              bool
}

func (o inOut) emit(a *assembler, a1, a2 *argument) error {
	if err := expect2Arg(a, a2); err != nil {
		return err
	}

	if o.isOut {
		a1, a2 = a2, a1
	}

	if a1.IsAccumulator() && a2.IsNum() && a2.IsByte() {
		if a1.IsByte() {
			return a.emitBytes(o.fixedPortOpcode, byte(a2.value))
		}
		if a1.IsWord() {
			return a.emitBytes(o.fixedPortOpcode|1, byte(a2.value))
		}
	}
	if a1.IsAccumulator() && a2.IsReg() && a2.IsWord() && a2.regSeg == DX {
		if a1.IsByte() {
			return a.emitByte(o.variablePortOpcode)
		}
		if a1.IsWord() {
			return a.emitByte(o.variablePortOpcode | 1)
		}
	}

	return a.error(fmt.Sprintf("invalid arguments: %s and %s", a1, a2))
}

type interrupt struct {
	int3Opcode byte
	immOpcode  byte
}

func (o interrupt) emit(a *assembler, a1, a2 *argument) error {
	if err := expect1Arg(a, a1, a2); err != nil {
		return err
	}

	if a1.IsNum() && a1.IsByte() && a1.value == 3 {
		return a.emitByte(o.int3Opcode)
	}
	if a1.IsNum() && a1.IsByte() {
		return a.emitBytes(o.immOpcode, byte(a1.value))
	}

	return a.error(fmt.Sprintf("invalid argument: %s", a1))
}

type jmpShort struct {
	opcode byte
}

func (o jmpShort) emit(a *assembler, a1, a2 *argument) error {
	if err := expect1Arg(a, a1, a2); err != nil {
		return err
	}

	if a1.IsNum() && a1.IsWord() {
		return a.emitShortJmp(o.opcode, a1)
	}

	return a.error(fmt.Sprintf("invalid argument: %s", a1))
}

type loadAddr struct {
	opcode byte
}

func (o loadAddr) emit(a *assembler, a1, a2 *argument) error {
	if err := expect2Arg(a, a2); err != nil {
		return err
	}

	if a1.IsReg() && a1.IsWord() && a2.IsPtr() {
		return a.emitRm(o.opcode, byte(a1.regSeg), a2)
	}

	return a.error(fmt.Sprintf("invalid arguments: %s and %s", a1, a2))
}

type mov struct {
	accMemOpcode byte
	regImmOpcode byte
	regRmOpcode  byte
	rmImmOpcode  byte
	rmImmExt     byte
	rmSegOpcode  byte
}

func (o mov) emit(a *assembler, a1, a2 *argument) error {
	if err := expect2Arg(a, a2); err != nil {
		return err
	}

	equateSizes(a1, a2)

	if a1.IsAccumulator() && a2.IsPtr() && a2.eaMode == eaDirect {
		if a1.IsByte() && a2.IsByte() {
			return a.emitBytes(o.accMemOpcode, byte(a2.value), byte(a2.value>>8))
		}
		if a1.IsWord() && a2.IsWord() {
			return a.emitBytes(o.accMemOpcode|1, byte(a2.value), byte(a2.value>>8))
		}
	}
	if a1.IsPtr() && a1.eaMode == eaDirect && a2.IsAccumulator() {
		if a1.IsByte() && a2.IsByte() {
			return a.emitBytes(o.accMemOpcode|2, byte(a1.value), byte(a1.value>>8))
		}
		if a1.IsWord() && a2.IsWord() {
			return a.emitBytes(o.accMemOpcode|3, byte(a1.value), byte(a1.value>>8))
		}
	}
	if a1.IsReg() && a2.IsNum() {
		if a1.IsByte() && a2.IsByte() {
			return a.emitBytes(o.regImmOpcode|byte(a1.regSeg), byte(a2.value))
		}
		if a1.IsWord() && a2.IsWord() {
			return a.emitBytes(o.regImmOpcode|8|byte(a1.regSeg), byte(a2.value), byte(a2.value>>8))
		}
	}
	if (a1.IsReg() || a1.IsPtr()) && a2.IsReg() {
		if err, done := a.emitRmWidth2(o.regRmOpcode, byte(a2.regSeg), a1, a2); done {
			return err
		}
	}
	if a1.IsReg() && (a2.IsReg() || a2.IsPtr()) {
		if err, done := a.emitRmWidth2(o.regRmOpcode|2, byte(a1.regSeg), a2, a1); done {
			return err
		}
	}
	if (a1.IsReg() || a1.IsPtr()) && a2.IsNum() {
		if err, done := a.emitRmImm(o.rmImmOpcode, o.rmImmExt, a1, a2, false); done {
			return err
		}
	}
	if (a1.IsReg() || a1.IsPtr()) && a1.IsWord() && a2.IsSeg() {
		return a.emitRm(o.rmSegOpcode, byte(a2.regSeg), a1)
	}
	if a1.IsSeg() && a1.regSeg != CS && (a2.IsReg() || a2.IsPtr()) && a2.IsWord() {
		return a.emitRm(o.rmSegOpcode|2, byte(a1.regSeg), a2)
	}

	return a.error(fmt.Sprintf("invalid arguments: %s and %s", a1, a2))
}

type stack struct {
	regOpcode byte
	rmOpcode  byte
	rmExt     byte
	segOpcode byte
}

func (o stack) emit(a *assembler, a1, a2 *argument) error {
	if err := expect1Arg(a, a1, a2); err != nil {
		return err
	}

	if a1.IsNoSize() {
		a1.argType = a1.argType.WithSize(sizeWord)
	}

	if a1.IsReg() && a1.IsWord() {
		return a.emitByte(o.regOpcode | byte(a1.regSeg))
	}
	if a1.IsPtr() && a1.IsWord() {
		return a.emitRm(o.rmOpcode, o.rmExt, a1)
	}
	if a1.IsSeg() {
		if a1.regSeg != CS || o.segOpcode != 7 {
			return a.emitByte(o.segOpcode | byte(a1.regSeg<<3))
		}
	}

	return a.error(fmt.Sprintf("invalid argument: %s", a1))
}

type rotate struct {
	opcode byte
	ext    byte
}

func (o rotate) emit(a *assembler, a1, a2 *argument) error {
	if err := expect2Arg(a, a2); err != nil {
		return err
	}

	if (a1.IsReg() || a1.IsPtr()) && a2.IsNum() && a2.IsWord() && a2.value == 1 {
		if err, done := a.emitRmWidth1(o.opcode, o.ext, a1); done {
			return err
		}
	}
	if (a1.IsReg() || a1.IsPtr()) && a2.IsReg() && a2.IsByte() && a2.regSeg == CL {
		if err, done := a.emitRmWidth1(o.opcode|2, o.ext, a1); done {
			return err
		}
	}

	return a.error(fmt.Sprintf("invalid arguments: %s and %s", a1, a2))
}

type ret struct {
	noArgOpcode byte
	argOpcode   byte
}

func (o ret) emit(a *assembler, a1, a2 *argument) error {
	if a1 == nil {
		return a.emitByte(o.noArgOpcode)
	}

	if err := expect1Arg(a, a1, a2); err != nil {
		return err
	}

	if a1.IsNum() && a1.IsWord() {
		return a.emitBytes(o.argOpcode, byte(a1.value), byte(a1.value>>8))
	}

	return a.error(fmt.Sprintf("invalid argument: %s", a1))
}

type xchg struct {
	accRegOpcode byte
	regRmOpcode  byte
}

func (o xchg) emit(a *assembler, a1, a2 *argument) error {
	if err := expect2Arg(a, a2); err != nil {
		return err
	}

	equateSizes(a1, a2)

	if a1.IsAccumulator() && a1.IsWord() && a2.IsReg() && a2.IsWord() {
		return a.emitByte(o.accRegOpcode | byte(a2.regSeg))
	}
	if a1.IsReg() && a1.IsWord() && a2.IsAccumulator() && a2.IsWord() {
		return a.emitByte(o.accRegOpcode | byte(a1.regSeg))
	}
	if (a1.IsReg() || a1.IsPtr()) && a2.IsReg() {
		if err, done := a.emitRmWidth2(o.regRmOpcode, byte(a2.regSeg), a1, a2); done {
			return err
		}
	}
	if a1.IsReg() && (a2.IsReg() || a2.IsPtr()) {
		if err, done := a.emitRmWidth2(o.regRmOpcode, byte(a1.regSeg), a2, a1); done {
			return err
		}
	}

	return a.error(fmt.Sprintf("invalid arguments: %s and %s", a1, a2))
}

func expect0Arg(a *assembler, a1 *argument) error {
	if a1 != nil {
		return a.errorArg("unexpected argument", a1)
	}
	return nil
}

func expect1Arg(a *assembler, a1, a2 *argument) error {
	if a1 == nil {
		return a.error("missing argument")
	}
	if a2 != nil {
		return a.errorArg("unexpected argument", a2)
	}
	return nil
}

func expect2Arg(a *assembler, a2 *argument) error {
	if a2 == nil {
		return a.error("missing argument")
	}
	return nil
}

func equateSizes(a1, a2 *argument) {
	if a1.IsByte() && a2.IsNoSize() {
		a2.argType = a2.argType.WithSize(sizeByte)
	} else if a1.IsWord() && a2.IsNoSize() {
		a2.argType = a2.argType.WithSize(sizeWord)
	} else if a1.IsNoSize() && a2.IsByte() {
		a1.argType = a1.argType.WithSize(sizeByte)
	} else if a1.IsNoSize() && a2.IsWord() {
		a1.argType = a1.argType.WithSize(sizeWord)
	}
}
