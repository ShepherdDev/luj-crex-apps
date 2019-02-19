rem --
rem -- init()
rem --
rem -- Initialize a new MenuButton instance. This object handles the visual
rem -- display of a single button in the MenuBar.
rem --
sub init()
  rem --
  rem -- Set initial control values.
  rem --
  m.lblText = m.top.findNode("lblText")
  m.rBackground = m.top.findNode("rBackground")

  rem --
  rem -- Configure the button images.
  rem --
  config = ReadCache(m, "config")
  m.focusedTextColor = config.Buttons.FocusedTextColor
  m.focusedBackgroundColor = config.Buttons.FocusedBackgroundColor
  m.unfocusedTextColor = config.Buttons.UnfocusedTextColor
  m.unfocusedBackgroundColor = config.Buttons.UnfocusedBackgroundColor

  rem --
  rem -- Observe the fields we need to monitor for changes.
  rem --
  m.top.observeField("focusedChild", "onFocusedChildChange")
end sub

rem *******************************************************
rem ** EVENT HANDLERS
rem *******************************************************

rem --
rem -- onSizeChange()
rem --
rem -- Called when our size has changed. Re-layout all the
rem -- elements of the button to fit the size.
rem --
sub onSizeChange()
  rem --
  rem -- Set the basic attributes of the button.
  rem --
  m.lblText.text = UCase(m.top.text)
  m.lblText.height = m.top.height
  m.lblText.font.size = Int(m.top.height / 2)
  padding = Int(m.top.height / 3)
  m.lblText.translation = [padding, Int(m.top.height / 20)]

  rem --
  rem -- Determine the width of the button.
  rem --
  if m.top.width = 0
    m.lblText.width = 0
    m.lblText.width = m.lblText.boundingRect().width
  else
    m.lblText.width = m.top.width - (padding * 2)
  end if

  rem --
  rem -- Setup the rectangle size
  rem --
  m.rBackground.height = m.top.height
  m.rBackground.width = m.lblText.width + (padding * 2)
  m.rBackground.translation = [0, 0]

  rem --
  rem -- Finally, update our boundingWidth so that the MenuBar knows how
  rem -- much space this button is taking up.
  rem --
  m.top.boundingWidth = m.rBackground.width

  rem --
  rem -- Make sure all the colors and such are set.
  rem --
  onFocusedChildChange()
end sub

rem --
rem -- onFocusedChildChange()
rem --
rem -- Called when we receive or lose focus. Update the UI elements to
rem -- match.
rem --
sub onFocusedChildChange()
  if m.top.HasFocus()
    m.lblText.color = m.focusedTextColor
    m.rBackground.color = m.focusedBackgroundColor
  else
    m.lblText.color = m.unfocusedTextColor
    m.rBackground.color = m.unfocusedBackgroundColor
  end if
end sub
