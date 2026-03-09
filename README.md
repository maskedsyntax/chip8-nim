# CHIP-8 Emulator

A CHIP-8 virtual machine implemented in Nim. This project implements the core 35 opcodes, 64x32 display, 16-bit address space, and 60Hz timers.

## Technical Specifications

- **Memory**: 4KB (0x000-0xFFF). Programs start at 0x200.
- **Registers**: 16 8-bit general purpose (V0-VF), one 16-bit address register (I), and a 16-bit program counter (PC).
- **Stack**: 16 levels for subroutines.
- **Timers**: 8-bit Delay and Sound timers decrementing at 60Hz.
- **Display**: 64x32 monochrome with XOR sprite drawing and collision detection.

## Prerequisites

- Nim 2.0+
- SDL2 development libraries (`libsdl2-dev` on Linux)
- `nim-sdl2` package (`nimble install sdl2`)

## Build Instructions

Compile with the ORC memory manager and release optimizations:

```bash
nim c -d:release --mm:orc --out:chip8 src/main.nim
```

## Usage

The emulator defaults to SDL2 windowed mode. Use the `--terminal` flag for raw terminal rendering.

```bash
./chip8 <path_to_rom> [options]
```

### Command Line Arguments

- `--terminal`: Force rendering in the terminal using Unicode characters.
- `--debug`: Print PC, opcode disassembly, and register states to stdout for every cycle.
- `--disassemble`: Print the full disassembly of the loaded ROM and exit.
- `--ips:<int>`: Set the execution speed in instructions per second (default: 600).

## Input Mapping

The CHIP-8 4x4 keypad is mapped to the following QWERTY layout:

| CHIP-8 | Key | | CHIP-8 | Key |
| :--- | :--- | --- | :--- | :--- |
| 1 | 1 | | C | 4 |
| 4 | Q | | D | R |
| 7 | A | | E | F |
| A | Z | | F | V |
| 2 | 2 | | 3 | 3 |
| 5 | W | | 6 | E |
| 8 | S | | 9 | D |
| 0 | X | | B | C |

## Testing

Verify opcode correctness using the internal test suite:

```bash
nim r tests/test_opcodes.nim
```
