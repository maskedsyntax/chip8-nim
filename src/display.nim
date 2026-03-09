# src/display.nim
import std/terminal
import ./chip8

type
  Display* = ref object
    useTerminal*: bool

proc initDisplay*(useTerminal: bool): Display =
  result = Display(useTerminal: useTerminal)
  if useTerminal:
    hideCursor()
    eraseScreen()

proc render*(d: Display, c: Chip8) =
  if d.useTerminal:
    setCursorPos(0, 0)
    var frame = ""
    for y in 0 ..< SCREEN_HEIGHT:
      for x in 0 ..< SCREEN_WIDTH:
        if c.display[y * SCREEN_WIDTH + x]:
          frame.add("█")
        else:
          frame.add(" ")
      frame.add("\n")
    stdout.write(frame)

proc cleanup*(d: Display) =
  if d.useTerminal:
    showCursor()
    eraseScreen()
