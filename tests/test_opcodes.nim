# tests/test_opcodes.nim
import std/unittest
import ../src/chip8

suite "CHIP-8 Opcode Tests":
  setup:
    let c = initChip8()

  test "00E0 - CLS":
    c.display[10] = true
    c.memory[c.pc] = 0x00
    c.memory[c.pc + 1] = 0xE0
    c.cycle()
    for pixel in c.display:
      check pixel == false

  test "1NNN - JP addr":
    c.memory[c.pc] = 0x1A
    c.memory[c.pc + 1] = 0xBC
    c.cycle()
    check c.pc == 0xABC'u16

  test "2NNN - CALL addr and 00EE - RET":
    let oldPc = c.pc
    c.memory[c.pc] = 0x24
    c.memory[c.pc + 1] = 0x56
    c.cycle()
    check c.pc == 0x456'u16
    check c.sp == 1
    check c.stack[0] == oldPc + 2
    
    c.memory[c.pc] = 0x00
    c.memory[c.pc + 1] = 0xEE
    c.cycle()
    check c.pc == oldPc + 2
    check c.sp == 0

  test "3XKK - SE Vx, byte":
    c.v[1] = 0x22
    # SE V1, 0x22 (Match)
    c.memory[c.pc] = 0x31
    c.memory[c.pc + 1] = 0x22
    c.cycle()
    check c.pc == uint16(ROM_START + 4)

    # SE V1, 0x33 (No match)
    c.memory[c.pc] = 0x31
    c.memory[c.pc + 1] = 0x33
    c.cycle()
    check c.pc == uint16(ROM_START + 6)

  test "6XKK - LD Vx, byte":
    c.memory[c.pc] = 0x62
    c.memory[c.pc + 1] = 0x44
    c.cycle()
    check c.v[2] == 0x44

  test "7XKK - ADD Vx, byte":
    c.v[3] = 0x10
    c.memory[c.pc] = 0x73
    c.memory[c.pc + 1] = 0x05
    c.cycle()
    check c.v[3] == 0x15

  test "8XY4 - ADD Vx, Vy (with carry)":
    c.v[0] = 0xFF
    c.v[1] = 0x01
    c.memory[c.pc] = 0x80
    c.memory[c.pc + 1] = 0x14
    c.cycle()
    check c.v[0] == 0x00
    check c.v[0xF] == 1

  test "8XY5 - SUB Vx, Vy (no borrow)":
    c.v[0] = 0x0A
    c.v[1] = 0x03
    c.memory[c.pc] = 0x80
    c.memory[c.pc + 1] = 0x15
    c.cycle()
    check c.v[0] == 0x07
    check c.v[0xF] == 1

  test "ANNN - LD I, addr":
    c.memory[c.pc] = 0xAF
    c.memory[c.pc + 1] = 0xFF
    c.cycle()
    check c.i == 0xFFF'u16

  test "FX33 - LD B, Vx (BCD)":
    c.v[0] = 123
    c.i = 0x300
    c.memory[c.pc] = 0xF0
    c.memory[c.pc + 1] = 0x33
    c.cycle()
    check c.memory[0x300] == 1
    check c.memory[0x301] == 2
    check c.memory[0x302] == 3
