' BJJ Timer – MainScene.brs (compile-safe)

sub init()
  m.title      = m.top.findNode("title")
  m.timeLabel  = m.top.findNode("time")
  m.tips       = m.top.findNode("tips")
  m.ring       = m.top.findNode("ring")
  m.stage      = m.top.findNode("stage")
  m.pulse      = m.top.findNode("pulse")

  ' Audio nodes
  m.sfxBeep = m.top.findNode("sfxBeep")
  m.sfxBell = m.top.findNode("sfxBell")

  ' Buttons
  m.btnStart = m.top.findNode("btnStart")
  m.btnReset = m.top.findNode("btnReset")
  m.btnFS    = m.top.findNode("btnFS")
  m.minusMin = m.top.findNode("minusMin")
  m.plusMin  = m.top.findNode("plusMin")
  m.minusRnd = m.top.findNode("minusRnd")
  m.plusRnd  = m.top.findNode("plusRnd")

  ' Labels
  m.matchLbl = m.top.findNode("matchLbl")
  m.roundLbl = m.top.findNode("roundLbl")
  m.breakLbl = m.top.findNode("breakLbl")

  ' Huge timer font
  f = CreateObject("roSGNode","Font")
  f.uri = "font:MediumSystemFont"
  f.size = 180
  m.timeLabel.font = f

  ' State
  m.matchSec = 5 * 60
  m.breakSec = 60
  m.rounds   = 5
  m.round    = 1
  m.pre      = 10
  m.phase    = "ready"   ' ready|pre|run|break|done
  m.remain   = m.matchSec
  m.running  = false

  ' Loop bookkeeping
  m.clock       = CreateObject("roTimespan")
  m.lastMS      = 0
  m.lastWhole   = -1
  m.pulseActive = false

  ' Inputs
  m.btnStart.observeField("buttonSelected","onStart")
  m.btnReset.observeField("buttonSelected","onReset")
  m.btnFS.observeField("buttonSelected","onFS")
  m.minusMin.observeField("buttonSelected","onMinusMin")
  m.plusMin.observeField("buttonSelected","onPlusMin")
  m.minusRnd.observeField("buttonSelected","onMinusRnd")
  m.plusRnd.observeField("buttonSelected","onPlusRnd")

  m.top.observeField("renderStats","onFrame")
  m.top.setFocus(true)

  updateUI()
end sub

' Scene key handler
function onKeyEvent(key as string, press as boolean) as boolean
  if not press then
    return false
  end if

  if key = "OK" or key = "Select" then
    onStart()
    return true
  else if key = "Back" then
    onReset()
    return true
  else if key = "Options" then
    onFS()
    return true
  else if key = "up" then
    onPlusMin()
    return true
  else if key = "down" then
    onMinusMin()
    return true
  else if key = "right" then
    onPlusRnd()
    return true
  else if key = "left" then
    onMinusRnd()
    return true
  else if key = "0" then
    onFS()
    return true
  end if

  return false
end function

' ---------------- Controls ----------------
sub onStart()
  if m.running then
    m.running = false
  else
    if m.phase = "ready" or m.phase = "done" then
      m.phase     = "pre"
      m.remain    = m.pre
      m.round     = 1
      m.lastWhole = -1
    end if
    m.running = true
    m.clock.Mark()
    m.lastMS = 0
  end if
  updateUI()
end sub

sub onReset()
  m.running   = false
  m.phase     = "ready"
  m.remain    = m.matchSec
  m.round     = 1
  m.lastWhole = -1
  stopPulse()
  updateUI()
end sub

sub onFS()
  ' No-op on Roku
end sub

sub onMinusMin()
  m.matchSec = max(60, m.matchSec - 60)
  if m.phase = "ready" then
    m.remain = m.matchSec
  end if
  updateUI()
end sub

sub onPlusMin()
  m.matchSec = min(20 * 60, m.matchSec + 60)
  if m.phase = "ready" then
    m.remain = m.matchSec
  end if
  updateUI()
end sub

sub onMinusRnd()
  m.rounds = max(1, m.rounds - 1)
  updateUI()
end sub

sub onPlusRnd()
  m.rounds = min(20, m.rounds + 1)
  updateUI()
end sub

' ---------------- Audio ----------------
sub playBeep()
  if m.sfxBeep <> invalid then
    m.sfxBeep.content = { uri: "pkg:/audio/beep.wav" }
    m.sfxBeep.control = "play"
  end if
end sub

sub playBell()
  if m.sfxBell <> invalid then
    m.sfxBell.content = { uri: "pkg:/audio/bell.wav" }
    m.sfxBell.control = "play"
  end if
end sub

' integer ceiling (avoid Ceil() for max compatibility)
function ceilInt(x as float) as integer
  i = int(x)
  if x = i then
    return i
  else
    return i + 1
  end if
end function

' ---------------- Loop ----------------
sub onFrame()
  if not m.running then
    return
  end if

  now = m.clock.TotalMilliseconds()
  if m.lastMS = 0 then
    m.lastMS = now
  end if

  dt = (now - m.lastMS) / 1000.0
  m.lastMS = now

  m.remain = m.remain - dt
  if m.remain < 0 then
    m.remain = 0
  end if

  ' 3-2-1 beeps in pre-start
  if m.phase = "pre" then
    whole = ceilInt(m.remain)
    if whole <> m.lastWhole then
      if whole = 3 or whole = 2 or whole = 1 then
        playBeep()
      end if
      m.lastWhole = whole
    end if
  end if

  ' Render one frame at exact 0
  updateUI()

  ' Phase transitions + bell
  if m.remain = 0 then
    if m.phase = "pre" then
      playBell()
      m.phase  = "run"
      m.remain = m.matchSec
      m.lastMS = now
      m.lastWhole = -1
    else if m.phase = "run" then
      playBell()
      m.round = m.round + 1
      if m.round > m.rounds then
        m.phase   = "done"
        m.running = false
        stopPulse()
      else
        m.phase  = "break"
        m.remain = m.breakSec
        m.lastMS = now
      end if
    else if m.phase = "break" then
      playBell()
      m.phase  = "run"
      m.remain = m.matchSec
      m.lastMS = now
    end if
  end if

  updateUI()
end sub

' ---------------- UI helpers ----------------
function pad2(n as integer) as string
  if n < 0 then
    n = 0
  end if
  if n < 10 then
    return "0" + StrI(n)
  else
    return StrI(n)
  end if
end function

function fmt(s as float) as string
  if s < 0 then
    s = 0
  end if
  sec = int(s)
  mnt = sec / 60
  rem = sec mod 60
  return pad2(mnt) + ":" + pad2(rem)
end function

function currentTint() as string
  if m.phase = "ready" or m.phase = "done" then
    return "#9aa0a6"
  end if
  if m.phase = "pre" then
    return "#9b5de5"
  end if
  if m.phase = "run" then
    if m.remain <= 10 then
      return "#ff3b30"
    end if
    if m.remain <= 30 then
      return "#ffae00"
    end if
    return "#1db954"
  end if
  if m.phase = "break" then
    if m.remain <= 10 then
      return "#9b5de5"
    end if
    return "#0091ff"
  end if
  return "#9aa0a6"
end function

sub startPulse()
  if m.pulse <> invalid then
    if not m.pulseActive then
      m.pulse.control = "start"
      m.pulseActive = true
    end if
  end if
end sub

sub stopPulse()
  if m.pulse <> invalid then
    if m.pulseActive then
      m.pulse.control = "stop"
      m.pulseActive = false
    end if
  end if
end sub

sub updateUI()
  ' Title
  if m.phase = "pre" then
    m.title.text = "GET READY"
  else if m.phase = "run" then
    m.title.text = "FIGHT"
  else if m.phase = "break" then
    m.title.text = "REST"
  else if m.phase = "done" then
    m.title.text = "FINISHED"
  else
    m.title.text = "READY"
  end if

  ' Big clock
  m.timeLabel.text = fmt(m.remain)

  ' Side labels
  m.matchLbl.text = "Match " + fmt(m.matchSec)
  m.roundLbl.text = "Rounds " + StrI(m.rounds)
  m.breakLbl.text = "Break " + fmt(m.breakSec)

  ' Ring color + progress
  col = currentTint()
  m.ring.tint = col

  ' Total time by phase (explicit multiline IF)
  total = 1.0
  if m.phase = "run" then
    total = m.matchSec
  else if m.phase = "break" then
    total = m.breakSec
  else if m.phase = "pre" then
    total = m.pre
  else
    total = 1.0
  end if

  prog = 0.0
  if total > 0 then
    prog = m.remain / total
  end if
  if prog < 0.0005 then
    prog = 0.0
  end if
  m.ring.progress = prog

  ' Urgency animation (last 10s of fight/rest)
  urgent = false
  if m.phase = "run" or m.phase = "break" then
    if m.remain <= 10 then
      urgent = true
    end if
  end if

  if urgent then
    startPulse()
  else
    stopPulse()
  end if

  ' Start/Pause button label
  if m.running then
    m.btnStart.text = "Pause"
  else if m.phase = "done" then
    m.btnStart.text = "Restart"
  else
    m.btnStart.text = "Start"
  end if
end sub
