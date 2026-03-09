# src/debug.nim
import std/[strformat, strutils]
import ./chip8

proc disassemble*(opcode: uint16): string =
  let nnn = opcode and 0x0FFF
  let n = uint8(opcode and 0x000F)
  let x = uint8((opcode and 0x0F00) shr 8)
  let y = uint8((opcode and 0x00F0) shr 4)
  let kk = uint8(opcode and 0x00FF)

  case (opcode and 0xF000) shr 12:
  of 0x0:
    case opcode:
    of 0x00E0: "CLS"
    of 0x00EE: "RET"
    else: &"SYS {nnn:03X}"
  of 0x1: &"JP {nnn:03X}"
  of 0x2: &"CALL {nnn:03X}"
  of 0x3: &"SE V{x:X}, {kk:02X}"
  of 0x4: &"SNE V{x:X}, {kk:02X}"
  of 0x5: &"SE V{x:X}, V{y:X}"
  of 0x6: &"LD V{x:X}, {kk:02X}"
  of 0x7: &"ADD V{x:X}, {kk:02X}"
  of 0x8:
    case opcode and 0x000F:
    of 0x0: &"LD V{x:X}, V{y:X}"
    of 0x1: &"OR V{x:X}, V{y:X}"
    of 0x2: &"AND V{x:X}, V{y:X}"
    of 0x3: &"XOR V{x:X}, V{y:X}"
    of 0x4: &"ADD V{x:X}, V{y:X}"
    of 0x5: &"SUB V{x:X}, V{y:X}"
    of 0x6: &"SHR V{x:X}"
    of 0x7: &"SUBN V{x:X}, V{y:X}"
    of 0xE: &"SHL V{x:X}"
    else: "UNKNOWN"
  of 0x9: &"SNE V{x:X}, V{y:X}"
  of 0xA: &"LD I, {nnn:03X}"
  of 0xB: &"JP V0, {nnn:03X}"
  of 0xC: &"RND V{x:X}, {kk:02X}"
  of 0xD: &"DRW V{x:X}, V{y:X}, {n:X}"
  of 0xE:
    case kk:
    of 0x9E: &"SKP V{x:X}"
    of 0xA1: &"SKNP V{x:X}"
    else: "UNKNOWN"
  of 0xF:
    case kk:
    of 0x07: &"LD V{x:X}, DT"
    of 0x0A: &"LD V{x:X}, K"
    of 0x15: &"LD DT, V{x:X}"
    of 0x18: &"LD ST, V{x:X}"
    of 0x1E: &"ADD I, V{x:X}"
    of 0x29: &"LD F, V{x:X}"
    of 0x33: &"LD B, V{x:X}"
    of 0x55: &"LD [I], V{x:X}"
    of 0x65: &"LD V{x:X}, [I]"
    else: "UNKNOWN"
  else: "UNKNOWN"

proc dumpState*(c: Chip8) =
  var output = ""
  output.add(&"PC: {c.pc:03X} I: {c.i:03X} SP: {c.sp:X}\n")
  for i in 0 ..< 8:
    output.add(&"V{i:X}: {c.v[i]:02X} ")
  output.add("\n")
  for i in 8 ..< 16:
    output.add(&"V{i:X}: {c.v[i]:02X} ")
  output.add("\n")
  echo output
