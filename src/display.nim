# src/display.nim
import std/terminal
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
    hideCursor()
    eraseScreen()
  else:
    discard sdl2.init(INIT_VIDEO or INIT_AUDIO)
    result.window = createWindow("CHIP-8 Emulator", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, SDL_WINDOW_SHOWN)
    result.renderer = createRenderer(result.window, -1, Renderer_Accelerated or Renderer_PresentVsync)
    result.texture = createTexture(result.renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT)

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
  # SDL2 beep can be added here with SDL_QueueAudio if needed

proc cleanup*(d: Display) =
  if d.useTerminal:
    showCursor()
    eraseScreen()
  elif d.window != nil:
    destroyTexture(d.texture)
    destroyRenderer(d.renderer)
    destroyWindow(d.window)
    sdl2.quit()
