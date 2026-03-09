# src/main.nim
import std/[os, times, parseopt, strutils, strformat, monotimes]
import ./chip8, ./display, ./input, ./debug

proc main() =
  var filename = ""
  var debugMode = false
  var terminalMode = false
  var disassembleOnly = false
  var ips = 600

  var p = initOptParser()
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case p.key
      of "debug": debugMode = true
      of "ips": ips = parseInt(p.val)
      of "terminal": terminalMode = true
      of "disassemble": disassembleOnly = true
      else: discard
    of cmdArgument:
      filename = p.key

  if filename == "":
    echo "Usage: ./main <ROM_FILE> [--debug] [--ips:600] [--terminal] [--disassemble]"
    return

  let c = initChip8()
  try:
    c.loadRom(filename)
  except CatchableError as e:
    echo "Error loading ROM: ", e.msg
    return

  if disassembleOnly:
    var pc = uint16(ROM_START)
    let fileSize = getFileSize(filename)
    while pc < ROM_START + uint16(fileSize):
      let opcode = (uint16(c.memory[pc]) shl 8) or uint16(c.memory[pc + 1])
      echo &"{pc:03X}: {opcode:04X} - {disassemble(opcode)}"
      pc += 2
    return

  let d = initDisplay(terminalMode)
  let i = initInput(terminalMode)

  if terminalMode:
    i.setRawMode()
    defer: i.restoreMode()

  defer: d.cleanup()

  let cycleTimeNanos = 1_000_000_000 div ips
  let timerTimeNanos = 1_000_000_000 div 60

  var lastCycle = getMonoTime()
  var lastTimer = getMonoTime()

  while true:
    let now = getMonoTime()

    # Process instructions
    while (now - lastCycle).inNanoseconds >= cycleTimeNanos:
      if debugMode:
        let opcode = (uint16(c.memory[c.pc]) shl 8) or uint16(c.memory[c.pc + 1])
        echo &"{c.pc:03X}: {opcode:04X} - {disassemble(opcode)}"
        c.dumpState()
      
      i.pollInput(c)
      c.cycle()
      if terminalMode:
        for k in 0 ..< c.keys.len: c.keys[k] = false
      lastCycle = lastCycle + initDuration(nanoseconds = cycleTimeNanos)

    # Process timers and rendering
    if (now - lastTimer).inNanoseconds >= timerTimeNanos:
      c.tickTimers()
      if c.soundTimer > 0:
        d.beep()
      d.render(c)
      lastTimer = lastTimer + initDuration(nanoseconds = timerTimeNanos)

    # Small sleep to prevent pinning the CPU, but keep it tight
    os.sleep(1)

if isMainModule:
  main()
