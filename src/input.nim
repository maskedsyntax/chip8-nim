# src/input.nim
import std/[terminal, posix, termios, tables]
import ./chip8
import sdl2

type
  Input* = ref object
    origTermios: Termios
    useTerminal: bool

proc initInput*(useTerminal: bool): Input =
  result = Input(useTerminal: useTerminal)
  if useTerminal:
    discard tcGetAttr(STDIN_FILENO, result.origTermios.addr)

proc setRawMode*(i: Input) =
  if i.useTerminal:
    var raw = i.origTermios
    raw.c_lflag = raw.c_lflag and not (ICANON or ECHO)
    raw.c_cc[VMIN.int] = 0.char
    raw.c_cc[VTIME.int] = 0.char
    discard tcSetAttr(STDIN_FILENO, TCSANOW, raw.addr)

proc restoreMode*(i: Input) =
  if i.useTerminal:
    discard tcSetAttr(STDIN_FILENO, TCSANOW, i.origTermios.addr)

proc pollInput*(i: Input, c: Chip8) =
  if i.useTerminal:
    var ch: char
    let n = read(STDIN_FILENO, ch.addr, 1)
    if n > 0:
      case ch:
      of '1': c.keys[0x1] = true
      of '2': c.keys[0x2] = true
      of '3': c.keys[0x3] = true
      of '4': c.keys[0xC] = true
      of 'q', 'Q': c.keys[0x4] = true
      of 'w', 'W': c.keys[0x5] = true
      of 'e', 'E': c.keys[0x6] = true
      of 'r', 'R': c.keys[0xD] = true
      of 'a', 'A': c.keys[0x7] = true
      of 's', 'S': c.keys[0x8] = true
      of 'd', 'D': c.keys[0x9] = true
      of 'f', 'F': c.keys[0xE] = true
      of 'z', 'Z': c.keys[0xA] = true
      of 'x', 'X': c.keys[0x0] = true
      of 'c', 'C': c.keys[0xB] = true
      of 'v', 'V': c.keys[0xF] = true
      else: discard

      if c.waitingForKey:
        case ch:
        of '1': c.v[c.waitKeyReg] = 0x1; c.waitingForKey = false
        of '2': c.v[c.waitKeyReg] = 0x2; c.waitingForKey = false
        of '3': c.v[c.waitKeyReg] = 0x3; c.waitingForKey = false
        of '4': c.v[c.waitKeyReg] = 0xC; c.waitingForKey = false
        of 'q', 'Q': c.v[c.waitKeyReg] = 0x4; c.waitingForKey = false
        of 'w', 'W': c.v[c.waitKeyReg] = 0x5; c.waitingForKey = false
        of 'e', 'E': c.v[c.waitKeyReg] = 0x6; c.waitingForKey = false
        of 'r', 'R': c.v[c.waitKeyReg] = 0xD; c.waitingForKey = false
        of 'a', 'A': c.v[c.waitKeyReg] = 0x7; c.waitingForKey = false
        of 's', 'S': c.v[c.waitKeyReg] = 0x8; c.waitingForKey = false
        of 'd', 'D': c.v[c.waitKeyReg] = 0x9; c.waitingForKey = false
        of 'f', 'F': c.v[c.waitKeyReg] = 0xE; c.waitingForKey = false
        of 'z', 'Z': c.v[c.waitKeyReg] = 0xA; c.waitingForKey = false
        of 'x', 'X': c.v[c.waitKeyReg] = 0x0; c.waitingForKey = false
        of 'c', 'C': c.v[c.waitKeyReg] = 0xB; c.waitingForKey = false
        of 'v', 'V': c.v[c.waitKeyReg] = 0xF; c.waitingForKey = false
        else: discard
  else:
    var event: Event
    while pollEvent(event).bool:
      case event.kind:
      of QuitEvent:
        quit(0)
      of KeyDown, KeyUp:
        let isPressed = event.kind == KeyDown
        case event.key.keysym.sym:
        of K_1: c.keys[0x1] = isPressed
        of K_2: c.keys[0x2] = isPressed
        of K_3: c.keys[0x3] = isPressed
        of K_4: c.keys[0xC] = isPressed
        of K_q: c.keys[0x4] = isPressed
        of K_w: c.keys[0x5] = isPressed
        of K_e: c.keys[0x6] = isPressed
        of K_r: c.keys[0xD] = isPressed
        of K_a: c.keys[0x7] = isPressed
        of K_s: c.keys[0x8] = isPressed
        of K_d: c.keys[0x9] = isPressed
        of K_f: c.keys[0xE] = isPressed
        of K_z: c.keys[0xA] = isPressed
        of K_x: c.keys[0x0] = isPressed
        of K_c: c.keys[0xB] = isPressed
        of K_v: c.keys[0xF] = isPressed
        of K_ESCAPE: quit(0)
        else: discard

        if isPressed and c.waitingForKey:
          let keyMap = {K_1: 0x1'u8, K_2: 0x2'u8, K_3: 0x3'u8, K_4: 0xC'u8,
                        K_q: 0x4'u8, K_w: 0x5'u8, K_e: 0x6'u8, K_r: 0xD'u8,
                        K_a: 0x7'u8, K_s: 0x8'u8, K_d: 0x9'u8, K_f: 0xE'u8,
                        K_z: 0xA'u8, K_x: 0x0'u8, K_c: 0xB'u8, K_v: 0xF'u8}.toTable()
          if keyMap.hasKey(event.key.keysym.sym):
            c.v[c.waitKeyReg] = keyMap[event.key.keysym.sym]
            c.waitingForKey = false
      else: discard
