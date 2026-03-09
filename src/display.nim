# src/display.nim
import std/[terminal, strutils]
import ./chip8
import sdl2

const SCALE = 10

type
  Display* = ref object
    useTerminal*: bool
    window: WindowPtr
    renderer: RendererPtr
    texture: TexturePtr

proc initDisplay*(useTerminal: bool): Display =
  result = Display(useTerminal: useTerminal)
  if useTerminal:
    # Clear screen and hide cursor
    stdout.write("\x1B[2J\x1B[H\x1B[?25l")
    stdout.flushFile()
  else:
    discard sdl2.init(INIT_VIDEO or INIT_AUDIO)
    result.window = createWindow("CHIP-8 Emulator", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, SDL_WINDOW_SHOWN)
    result.renderer = createRenderer(result.window, -1, Renderer_Accelerated or Renderer_PresentVsync)
    result.texture = createTexture(result.renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT)

proc render*(d: Display, c: Chip8) =
  if d.useTerminal:
    # Move cursor to top-left
    var output = "\x1B[H"
    # Add a top border
    output.add("+" & "-".repeat(SCREEN_WIDTH) & "+\n")
    for y in 0 ..< SCREEN_HEIGHT:
      output.add("|")
      for x in 0 ..< SCREEN_WIDTH:
        if c.display[y * SCREEN_WIDTH + x]:
          output.add("#")
        else:
          output.add(" ")
      output.add("|\n")
    # Add a bottom border
    output.add("+" & "-".repeat(SCREEN_WIDTH) & "+\n")
    output.add("\n[Press Ctrl+C to Exit]\n")
    stdout.write(output)
    stdout.flushFile()
  elif d.window != nil:
    var pixels: array[SCREEN_WIDTH * SCREEN_HEIGHT, uint32]
    for i in 0 ..< c.display.len:
      pixels[i] = if c.display[i]: 0xFFFFFFFF'u32 else: 0xFF000000'u32
    
    updateTexture(d.texture, nil, pixels[0].addr, SCREEN_WIDTH * 4)
    clear(d.renderer)
    copy(d.renderer, d.texture, nil, nil)
    present(d.renderer)

proc beep*(d: Display) =
  if d.useTerminal:
    stdout.write("\a")
    stdout.flushFile()

proc cleanup*(d: Display) =
  if d.useTerminal:
    # Show cursor and clear screen
    stdout.write("\x1B[?25h\x1B[2J\x1B[H")
    stdout.flushFile()
  elif d.window != nil:
    destroyTexture(d.texture)
    destroyRenderer(d.renderer)
    destroyWindow(d.window)
    sdl2.quit()
