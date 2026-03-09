# src/input.nim
import std/terminal
import ./chip8

type
  Input* = ref object

proc initInput*(): Input =
  result = Input()

proc pollInput*(i: Input, c: Chip8) =
  # std/terminal does not have a portable keyPressed for all platforms in pure nim
  # For this implementation, we will use a simplified approach.
  # In a real SDL2 implementation, this would be much cleaner.
  # For terminal mode, we can use getch() if available or just skip for now 
  # to focus on the core VM.
  discard
