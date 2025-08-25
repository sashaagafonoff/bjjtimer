sub init()
  ' --- 1) grab nodes first ---
  m.bg         = m.top.findNode("bg")
  m.logo       = m.top.findNode("logo")
  m.roundLbl   = m.top.findNode("round")
  m.clockLbl   = m.top.findNode("clock")
  m.phaseLbl   = m.top.findNode("phase")
  m.roundLenLbl= m.top.findNode("roundLen")
  m.restLenLbl = m.top.findNode("restLen")
  m.hintsLbl   = m.top.findNode("hints")
  m.beepNode   = m.top.findNode("beep")
  m.ticker     = m.top.findNode("ticker")
  m.flashTimer = m.top.findNode("flashTimer")

  m.SW = 1280 : m.SH = 720

  ' --- 2) create fonts, then assign to labels ---
  m.clockFont = CreateObject("roSGNode", "Font")
  m.clockFont.uri  = "pkg:/fonts/RobotoMono-Bold.ttf"
  m.clockFont.size = 350   ' adjust 220–260 to taste

  m.roundFont = CreateObject("roSGNode", "Font")
  m.roundFont.uri  = "pkg:/fonts/RobotoMono-Bold.ttf"
  m.roundFont.size = 120

  m.phaseFont = CreateObject("roSGNode", "Font")
  m.phaseFont.uri  = "pkg:/fonts/RobotoMono-Bold.ttf"
  m.phaseFont.size = 120

  m.roundLenFont = CreateObject("roSGNode", "Font")
  m.roundLenFont.uri  = "pkg:/fonts/RobotoMono-Bold.ttf"
  m.roundLenFont.size = 30

  m.restLenFont = CreateObject("roSGNode", "Font")
  m.restLenFont.uri  = "pkg:/fonts/RobotoMono-Bold.ttf"
  m.restLenFont.size = 30

  ' assign (guarded in case an id is off)
  if m.clockLbl <> invalid then m.clockLbl.font = m.clockFont
  if m.roundLbl <> invalid then m.roundLbl.font = m.roundFont
  if m.phaseLbl <> invalid then m.phaseLbl.font = m.phaseFont
  if m.roundLenLbl <> invalid then m.roundLenLbl.font = m.roundLenFont
  if m.restLenLbl <> invalid then m.restLenLbl.font = m.restLenFont

  ' --- colors (string RGBA: 0xRRGGBBAA) ---
  m.colGreen   = "0x048738FF"  ' green
  m.colRed     = "0x870425FF"  ' red
  m.colOrange  = "0xC95100FF"  ' orange
  m.colWhite   = "0xFFFFFFFF"  ' white
  m.colGrey    = "0x888888FF"  ' dark grey
  m.colLight   = "0xAAAAAAFF"  ' light grey
  m.colBlue    = "0x1E90FFFF"  ' blue (phase text when paused)

  ' static labels (non-state)
  m.roundLbl.color    = m.colWhite
  m.roundLenLbl.color = m.colGrey
  m.restLenLbl.color  = m.colGrey
  m.hintsLbl.color    = m.colLight

  ' --- sizes & centering (no bitmap scaling for crispness) ---
  m.logo.width = 850 : m.logo.height = 850 : centerNode(m.logo, -100) : m.logo.opacity = 0.5

  m.roundLbl.width = 1000 : m.roundLbl.height = 120
  m.roundLbl.horizAlign = "center" : m.roundLbl.scale = [1.0, 1.0]
  centerNodeWithScale(m.roundLbl, 20)

  m.clockLbl.width = 1200 : m.clockLbl.height = 250
  m.clockLbl.horizAlign = "center" : m.clockLbl.scale = [1.0, 1.0]
  centerNodeWithScale(m.clockLbl, 100)

  m.phaseLbl.width = 800 : m.phaseLbl.height = 150
  m.phaseLbl.horizAlign = "center" : m.phaseLbl.scale = [1.0, 1.0]
  centerNodeWithScale(m.phaseLbl, 475)

  m.roundLenLbl.width = 300 : m.roundLenLbl.height = 100
  m.roundLenLbl.horizAlign = "center" : m.roundLenLbl.scale = [1.0, 1.0]
  m.roundLenLbl.translation = [100, 600]

  m.restLenLbl.width = 300 : m.restLenLbl.height = 100
  m.restLenLbl.horizAlign = "center" : m.restLenLbl.scale = [1.0, 1.0]
  m.restLenLbl.translation = [900, 600]

  ' --- app state (unchanged) ---
  m.totalRounds  = 5
  m.roundLength  = 300
  m.restLength   = 60
  m.currentRound = 1
  m.phase        = "idle"
  m.prevPhase    = invalid
  m.remaining    = m.roundLength
  m.prepLength   = 10

  ' timers
  m.ticker.duration = 1.0 : m.ticker.repeat = true
  m.ticker.observeField("fire", "onTick")
  m.flashTimer.observeField("fire", "onFlashDone")

  ' preload audio (as before)
  if m.beepNode <> invalid then
    m.cnBeep = CreateObject("roSGNode", "ContentNode")
    m.cnBeep.url = "pkg:/sounds/beep.mp3" : m.cnBeep.streamformat = "mp3"
    m.cnBell = CreateObject("roSGNode", "ContentNode")
    m.cnBell.url = "pkg:/sounds/bell.mp3" : m.cnBell.streamformat = "mp3"
  end if

  m.top.setFocus(true)
  updateLabels()
end sub

' ------------- LAYOUT HELPERS (center on screen) -------------
sub centerNode(node as object, y as integer)
  x = int((m.SW - node.width) / 2)
  node.translation = [x, y]
end sub

sub centerNodeWithScale(node as object, y as integer)
  w = node.width * node.scale[0]
  x = int((m.SW - w) / 2)
  node.translation = [x, y]
end sub

sub handleDeepLink(info as object)
  ' Accept and ignore for now; keep focus on the Scene
  print "[deeplink] "; info
  m.top.setFocus(true)
end sub

' =================== Keys ===================
function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "OK" or key = "play" then
    if m.phase = "running" or m.phase = "rest" or m.phase = "prep"
      pause()
    else
      start()
    end if
    return true
  else if key = "back" then
    reset() : return true
  else if key = "up" then
    adjustRoundLength(15)   : return true
  else if key = "down" then
    adjustRoundLength(-15)  : return true
  else if key = "left" then
    adjustTotalRounds(-1)   : return true
  else if key = "right" then
    adjustTotalRounds(1)    : return true
  else if key = "rev" or key = "rewind" then
    adjustRestLength(-5)    : return true
  else if key = "fwd" or key = "fastforward" then
    adjustRestLength(5)     : return true
  end if
  return false
end function

' =================== Actions ===================
sub start()
  if m.phase = "finished" then reset()
  if m.phase = "paused" then resume() : return

  ' pre-start Round 1
  if m.phase = "idle" and m.currentRound = 1 and m.prepLength > 0 then
    m.phase = "prep" : m.remaining = m.prepLength
    ensureTickerRunning() : updateLabels() : return
  end if

  if m.phase = "idle" or m.phase = "rest" then
    m.phase = "running" : ensureTickerRunning() : updateLabels()
  end if
end sub

sub pause()
  m.prevPhase = m.phase
  m.phase = "paused"
  stopTicker()
  updateLabels()
end sub

sub resume()
  if m.prevPhase <> invalid then m.phase = m.prevPhase else m.phase = "running"
  m.prevPhase = invalid
  ensureTickerRunning()
  updateLabels()
end sub

sub reset()
  stopTicker()
  m.currentRound = 1
  m.phase = "idle" : m.prevPhase = invalid
  m.remaining = m.roundLength
  updateLabels()
end sub

' =================== Adjust ===================
sub adjustRoundLength(d as integer)
  nl = m.roundLength + d : if nl < 30 then nl = 30 : if nl > 900 then nl = 900
  m.roundLength = nl
  if m.phase = "idle" or m.phase = "finished" then m.remaining = m.roundLength
  updateLabels()
end sub

sub adjustRestLength(d as integer)
  nl = m.restLength + d : if nl < 0 then nl = 0 : if nl > 300 then nl = 300
  m.restLength = nl
  if m.phase = "rest" then m.remaining = m.restLength
  updateLabels()
end sub

sub adjustTotalRounds(d as integer)
  nt = m.totalRounds + d : if nt < 1 then nt = 1 : if nt > 20 then nt = 20
  m.totalRounds = nt
  if m.currentRound > m.totalRounds then m.currentRound = m.totalRounds
  updateLabels()
end sub

' =================== Tick & transitions ===================
sub onTick()
  ' PREP: beep on 3/2/1 AFTER decrement; bell on start
  if m.phase = "prep" then
    m.remaining = m.remaining - 1
    if m.remaining = 3 or m.remaining = 2 or m.remaining = 1 then playBeep()
    if m.remaining <= 0 then
      flashClock() : playBell()
      m.phase = "running" : m.remaining = m.roundLength
    end if
    updateLabels() : return
  end if

  ' ---- REST: 3,2,1 (beeps after decrement), then bell and start next round
  if m.phase = "rest" then
    m.remaining = m.remaining - 1
    if m.remaining = 3 or m.remaining = 2 or m.remaining = 1 then playBeep()

    if m.remaining <= 0 then
      flashClock()
      ' increment the round number now that rest is over
      if m.currentRound < m.totalRounds then
        m.currentRound = m.currentRound + 1
      end if
      m.phase = "running"
      playBell()                              ' bell at the start of the next round
      m.remaining = m.roundLength
    end if

    updateLabels()
    return
  end if


  ' RUNNING: bell at finish
  if m.phase = "running" then
    m.remaining = m.remaining - 1
    if m.remaining <= 0 then
      flashClock() : playBell()
      if m.currentRound < m.totalRounds then
        if m.restLength > 0 then
          m.phase = "rest" : m.remaining = m.restLength
        else
          m.currentRound = m.currentRound + 1
          if m.currentRound <= m.totalRounds then
            m.phase = "running" : m.remaining = m.roundLength
          end if
        end if
      else
        m.phase = "finished" : stopTicker()
      end if
    end if
    updateLabels() : return
  end if
end sub

' =================== Flash UI ===================
sub flashClock()
  m.clockLbl.opacity = 0.2
  m.flashTimer.control = "start"
end sub

sub onFlashDone()
  m.clockLbl.opacity = 1.0
end sub

' =================== Helpers ===================
sub ensureTickerRunning()
  if m.ticker.control <> "start" then m.ticker.control = "start"
end sub

sub stopTicker()
  if m.ticker.control = "start" then m.ticker.control = "stop"
end sub

sub updateLabels()
  m.roundLbl.text    = "ROUND " + m.currentRound.toStr() + " / " + m.totalRounds.toStr()
  m.clockLbl.text    = formatSeconds(m.remaining)
  m.roundLenLbl.text = "ROUND: " + formatSeconds(m.roundLength)
  m.restLenLbl.text  = "REST: "  + formatSeconds(m.restLength)

  if m.phase = "running" then
    m.phaseLbl.text  = "FIGHTING"
    m.clockLbl.color = m.colGreen
    m.phaseLbl.color = m.colGreen

  else if m.phase = "prep" then
    m.phaseLbl.text  = "PREPARING"
    m.clockLbl.color = m.colRed
    m.phaseLbl.color = m.colRed

  else if m.phase = "rest" then
    m.phaseLbl.text  = "RESTING"
    if m.remaining <= 10 then
      m.clockLbl.color = m.colRed
      m.phaseLbl.color = m.colRed
    else
      m.clockLbl.color = m.colOrange
      m.phaseLbl.color = m.colOrange
    end if

  else if m.phase = "paused" then
    m.phaseLbl.text  = "PAUSED"
    m.clockLbl.color = m.colGrey
    m.phaseLbl.color = m.colGrey

  else if m.phase = "idle" then
    m.phaseLbl.text  = "IDLE"
    m.clockLbl.color = m.colBlue
    m.phaseLbl.color = m.colBlue

  else
    m.phaseLbl.text  = "DONE"
    m.clockLbl.color = m.colBlue
    m.phaseLbl.color = m.colBlue
  end if
end sub


function formatSeconds(t as integer) as string
  if t < 0 then t = 0
  m = int(t / 60) : s = t mod 60
  return zeroPad(m) + ":" + zeroPad(s)
end function

function zeroPad(n as integer) as string
  if n < 10 then return "0" + n.toStr()
  return n.toStr()
end function

' =================== Audio helpers ===================
sub playBeep()
  if m.beepNode = invalid then return
  m.beepNode.control = "stop"
  m.beepNode.content = m.cnBeep
  m.beepNode.control = "play"
end sub

sub playBell()
  if m.beepNode = invalid then return
  m.beepNode.control = "stop"
  m.beepNode.content = m.cnBell
  m.beepNode.control = "play"
end sub
