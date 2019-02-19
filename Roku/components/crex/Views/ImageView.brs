rem --
rem -- init()
rem --
rem -- Initialize a new ImageView view. This displays a full-screen image
rem -- to the user.
rem --
sub init()
  rem --
  rem -- Set initial control values.
  rem --
  m.rImage = m.top.findNode("rImage")
  m.pBackgroundImage = m.top.findNode("pBackgroundImage")

  rem --
  rem -- Set the width and height of the background and image controls
  rem -- to be the width and height of the screen.
  rem --
  resolution = m.top.getScene().currentDesignResolution
  m.rImage.width = resolution.width
  m.rImage.height = resolution.height
  m.pBackgroundImage.width = resolution.width
  m.pBackgroundImage.height = resolution.height

  rem --
  rem -- Observe the fields we need to monitor for changes.
  rem --
  m.pBackgroundImage.observeField("loadStatus", "onBackgroundStatus")
end sub

rem *******************************************************
rem ** EVENT HANDLERS
rem *******************************************************

rem --
rem -- onDataChange()
rem --
rem -- Called when the data has been changed to a new value. Update the
rem -- image to use this new data value.
rem --
sub onDataChange()
  m.pBackgroundImage.uri = GetAbsoluteUrl(BestMatchingUrl(ParseJson(m.top.data)))
end sub

rem --
rem -- onBackgroundStatus()
rem --
rem -- Called once the background image has finished loading. At this
rem -- point we can show the menu bar and hide the loading spinner.
rem --
sub onBackgroundStatus()
  rem --
  rem -- Verify that the image either loaded or failed. We don't want
  rem -- to activate during the loading state.
  rem --
  if m.pBackgroundImage.loadStatus = "ready" or m.pBackgroundImage.loadStatus = "failed"
    m.top.templateState = "ready"
  end if
end sub
