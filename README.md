# CHIP-8 Emulator in Nim

A minimal, self-contained CHIP-8 emulator written in Nim.

## Features

- Full support for all 35 CHIP-8 opcodes.
- Terminal-based rendering (ASCII/Unicode art).
- Integrated disassembler and debugger.
- 60Hz timers and adjustable instruction speed.
- Zero external dependencies (uses Nim standard library).

## Building

Ensure you have [Nim](https://nim-lang.org/) installed.

```bash
nim c -d:release --mm:orc --out:chip8 src/main.nim
```

## Usage

Run a ROM file:
```bash
./chip8 path/to/rom.ch8
```

### Options
- `--debug`: Enable step-by-step state dumping.
- `--disassemble`: Output the ROM disassembly and exit.
- `--ips:N`: Set instructions per second (default: 600).
- `--terminal`: Force terminal rendering mode (default).

## Controls (Mapping)
CHIP-8 Keypad -> Keyboard
1 2 3 C -> 1 2 3 4
4 5 6 D -> Q W E R
7 8 9 E -> A S D F
A 0 B F -> Z X C V

## Testing
Run unit tests:
```bash
nim r tests/test_opcodes.nim
```
