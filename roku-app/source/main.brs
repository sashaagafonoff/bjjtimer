sub main(args as Dynamic)
  screen = CreateObject("roSGScreen")
  port   = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  scene = screen.CreateScene("MainScene")
  screen.Show()

  ' Required performance beacon once first UI frame is up
  scene.signalBeacon("AppLaunchComplete")

  ' -------- Deep link: cold start --------
  if args <> invalid then
    dl = normalizeDeepLink(args)
    scene.callFunc("handleDeepLink", dl)
  end if

  ' -------- Deep link: while running --------
  input = CreateObject("roInput")
  input.SetMessagePort(port)

  while true
    msg = wait(0, port)
    t = type(msg)
    if t = "roSGScreenEvent" then
      if msg.IsScreenClosed() then return

    else if t = "roInputEvent" then
      info = msg.GetInfo()
      dl = normalizeDeepLink(info)
      scene.callFunc("handleDeepLink", dl)
    end if
  end while
end sub

' Normalize keys so contentId/mediaType exist with predictable casing.
function normalizeDeepLink(x as dynamic) as object
  aa = {}
  if x = invalid then return aa

  ' x can be AssociativeArray or have nested "input" field; normalize both.
  base = x
  if type(x) = "roAssociativeArray" and x.lookupCI("input") <> invalid then
    base = x.input
  end if

  if type(base) = "roAssociativeArray" then
    ' Handle different common casings/aliases from platform tools
    cid = invalid
    mt  = invalid
    for each k in base
      key = lcase(k)
      if key = "contentid" or key = "content_id" then cid = base[k]
      if key = "mediatype" or key = "media_type" then mt  = base[k]
    end for
    if cid <> invalid then aa.contentId = cid
    if mt  <> invalid then aa.mediaType = mt
  end if

  return aa
end function
