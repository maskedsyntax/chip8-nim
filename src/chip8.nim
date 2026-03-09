# src/chip8.nim
import std/[random]

const
  MEM_SIZE* = 4096
  V_REGS* = 16
  STACK_SIZE* = 16
  SCREEN_WIDTH* = 64
  SCREEN_HEIGHT* = 32
  FONT_START* = 0x050
  ROM_START* = 0x200

  # CHIP-8 font set (0-F)
  FONT_SET*: array[80, uint8] = [
    0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
    0x20, 0x60, 0x20, 0x20, 0x70, # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
    0x90, 0x90, 0xF0, 0x10, 0x10, # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
    0xF0, 0x10, 0x20, 0x40, 0x40, # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
    0xF0, 0x80, 0x80, 0x80, 0xF0, # C
    0xE0, 0x90, 0x90, 0x90, 0xE0, # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
    0xF0, 0x80, 0xF0, 0x80, 0x80  # F
  ]

type
  Chip8* = ref object
    memory*: array[MEM_SIZE, uint8]
    v*: array[V_REGS, uint8]
    i*: uint16
    pc*: uint16
    sp*: uint8
    stack*: array[STACK_SIZE, uint16]
    delayTimer*: uint8
    soundTimer*: uint8
    display*: array[SCREEN_WIDTH * SCREEN_HEIGHT, bool]
    keys*: array[16, bool]
    waitingForKey*: bool
    waitKeyReg*: uint8

proc initChip8*(): Chip8 =
  result = Chip8(
    pc: ROM_START,
    i: 0,
    sp: 0,
    delayTimer: 0,
    soundTimer: 0,
    waitingForKey: false
  )
  # Load font set into memory
  for i in 0 ..< FONT_SET.len:
    result.memory[FONT_START + i] = FONT_SET[i]

proc loadRom*(c: Chip8, filename: string) =
  let file = open(filename, fmRead)
  defer: file.close()
  let size = file.getFileSize()
  if size > (MEM_SIZE - ROM_START):
    raise newException(ValueError, "ROM too large for memory")
  
  discard file.readBytes(c.memory, ROM_START, int(size))

proc cycle*(c: Chip8) =
  if c.waitingForKey:
    return

  let opcode = (uint16(c.memory[c.pc]) shl 8) or uint16(c.memory[c.pc + 1])
  let nnn = opcode and 0x0FFF
  let n = uint8(opcode and 0x000F)
  let x = uint8((opcode and 0x0F00) shr 8)
  let y = uint8((opcode and 0x00F0) shr 4)
  let kk = uint8(opcode and 0x00FF)

  c.pc += 2

  case (opcode and 0xF000) shr 12:
  of 0x0:
    case opcode:
    of 0x00E0: # CLS
      for i in 0 ..< c.display.len: c.display[i] = false
    of 0x00EE: # RET
      dec c.sp
      c.pc = c.stack[c.sp]
    else: # 0NNN - SYS addr (ignored)
      discard
  of 0x1: # 1NNN - JP addr
    c.pc = nnn
  of 0x2: # 2NNN - CALL addr
    c.stack[c.sp] = c.pc
    inc c.sp
    c.pc = nnn
  of 0x3: # 3XKK - SE Vx, byte
    if c.v[x] == kk: c.pc += 2
  of 0x4: # 4XKK - SNE Vx, byte
    if c.v[x] != kk: c.pc += 2
  of 0x5: # 5XY0 - SE Vx, Vy
    if c.v[x] == c.v[y]: c.pc += 2
  of 0x6: # 6XKK - LD Vx, byte
    c.v[x] = kk
  of 0x7: # 7XKK - ADD Vx, byte
    c.v[x] += kk
  of 0x8:
    case opcode and 0x000F:
    of 0x0: c.v[x] = c.v[y] # 8XY0 - LD Vx, Vy
    of 0x1: c.v[x] = c.v[x] or c.v[y] # 8XY1 - OR Vx, Vy
    of 0x2: c.v[x] = c.v[x] and c.v[y] # 8XY2 - AND Vx, Vy
    of 0x3: c.v[x] = c.v[x] xor c.v[y] # 8XY3 - XOR Vx, Vy
    of 0x4: # 8XY4 - ADD Vx, Vy
      let sum = uint16(c.v[x]) + uint16(c.v[y])
      c.v[0xF] = if sum > 255: 1 else: 0
      c.v[x] = uint8(sum and 0xFF)
    of 0x5: # 8XY5 - SUB Vx, Vy
      c.v[0xF] = if c.v[x] > c.v[y]: 1 else: 0
      c.v[x] -= c.v[y]
    of 0x6: # 8XY6 - SHR Vx {, Vy}
      c.v[0xF] = c.v[x] and 0x1
      c.v[x] = c.v[x] shr 1
    of 0x7: # 8XY7 - SUBN Vx, Vy
      c.v[0xF] = if c.v[y] > c.v[x]: 1 else: 0
      c.v[x] = c.v[y] - c.v[x]
    of 0xE: # 8XYE - SHL Vx {, Vy}
      c.v[0xF] = (c.v[x] and 0x80) shr 7
      c.v[x] = c.v[x] shl 1
    else: discard
  of 0x9: # 9XY0 - SNE Vx, Vy
    if c.v[x] != c.v[y]: c.pc += 2
  of 0xA: # ANNN - LD I, addr
    c.i = nnn
  of 0xB: # BNNN - JP V0, addr
    c.pc = nnn + uint16(c.v[0])
  of 0xC: # CXKK - RND Vx, byte
    c.v[x] = uint8(rand(255)) and kk
  of 0xD: # DXYN - DRW Vx, Vy, nibble
    let x_pos = c.v[x] mod SCREEN_WIDTH
    let y_pos = c.v[y] mod SCREEN_HEIGHT
    c.v[0xF] = 0
    for row in 0 ..< int(n):
      if y_pos + uint8(row) >= SCREEN_HEIGHT: break
      let sprite_byte = c.memory[c.i + uint16(row)]
      for col in 0 ..< 8:
        if x_pos + uint8(col) >= SCREEN_WIDTH: break
        if (sprite_byte and (0x80'u8 shr col)) != 0:
          let idx = (int(y_pos) + row) * SCREEN_WIDTH + (int(x_pos) + col)
          if c.display[idx]:
            c.v[0xF] = 1
          c.display[idx] = not c.display[idx]
  of 0xE:
    case kk:
    of 0x9E: # EX9E - SKP Vx
      if c.keys[c.v[x] and 0xF]: c.pc += 2
    of 0xA1: # EXA1 - SKNP Vx
      if not c.keys[c.v[x] and 0xF]: c.pc += 2
    else: discard
  of 0xF:
    case kk:
    of 0x07: c.v[x] = c.delayTimer # FX07 - LD Vx, DT
    of 0x0A: # FX0A - LD Vx, K
      c.waitingForKey = true
      c.waitKeyReg = x
    of 0x15: c.delayTimer = c.v[x] # FX15 - LD DT, Vx
    of 0x18: c.soundTimer = c.v[x] # FX18 - LD ST, Vx
    of 0x1E: c.i += uint16(c.v[x]) # FX1E - ADD I, Vx
    of 0x29: c.i = FONT_START + uint16(c.v[x] and 0xF) * 5 # FX29 - LD F, Vx
    of 0x33: # FX33 - LD B, Vx
      c.memory[c.i] = c.v[x] div 100
      c.memory[c.i + 1] = (c.v[x] div 10) mod 10
      c.memory[c.i + 2] = c.v[x] mod 10
    of 0x55: # FX55 - LD [I], Vx
      for idx in 0 .. int(x):
        c.memory[c.i + uint16(idx)] = c.v[idx]
    of 0x65: # FX65 - LD Vx, [I]
      for idx in 0 .. int(x):
        c.v[idx] = c.memory[c.i + uint16(idx)]
    else: discard
  else: discard

proc tickTimers*(c: Chip8) =
  if c.delayTimer > 0:
    dec c.delayTimer
  if c.soundTimer > 0:
    dec c.soundTimer
