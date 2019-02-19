rem --
rem -- init()
rem --
rem -- Initialize a new Crex Scene component. This handles all the screen
rem -- logic for the application. It is in charge of the stack of views
rem -- as well as the main menu content.
rem --
sub init()
  rem --
  rem -- Set initial control values.
  rem --
  m.pBackground = m.top.findNode("pBackground")
  m.mbMenuBar = m.top.findNode("mbMenuBar")
  m.nNotification = m.top.findNode("nNotification")

  rem --
  rem -- Configure any customized settings.
  rem --
  crex = ReadCache(m, "config")

  rem --
  rem -- Configure UI elements for the screen size we are running.
  rem --
  resolution = m.top.getScene().currentDesignResolution
  m.pBackground.width = resolution.width
  m.pBackground.height = resolution.height
  if resolution.resolution = "FHD"
    rem --
    rem -- Configure for 1920x1080.
    rem --
    m.mbMenuBar.translation = [0, 960]
    m.mbMenuBar.width = 1920
    m.mbMenuBar.height = 120
  else
    rem --
    rem -- Configure for 1280x720.
    rem --
    m.mbMenuBar.translation = [0, 640]
    m.mbMenuBar.width = 1280
    m.mbMenuBar.height = 80
  end if

  rem --
  rem -- Observe the fields we need to monitor for changes.
  rem --
  m.top.observeField("focusedChild", "onFocusedChildChange")
  m.pBackground.observeField("loadStatus", "onBackgroundStatus")
  m.mbMenuBar.observeField("selectedButtonIndex", "onSelectedButtonIndex")
  m.nNotification.observeField("state", "onNotificationStateChange")
end sub

rem *******************************************************
rem ** METHODS
rem *******************************************************

rem --
rem -- showNextNotification()
rem --
rem -- Shows the next notification in our list of notifications. The
rem -- notification must have a date that is later than the last seen
rem -- notification and also before now.
rem --
sub showNextNotification()
  lastNotification = RegistryRead("Crex", "LastSeenNotification")
  if lastNotification <> invalid
    lastNotification = Val(lastNotification, 10)
  else
    lastNotification = 0
  end if

  now = CreateObject("roDateTime").AsSeconds()

  if m.config.Notifications <> invalid
    for each notification in m.config.Notifications
      if notification.StartDateTimeSeconds > lastNotification and notification.StartDateTimeSeconds <= now
        m.nNotification.visible = true
        m.nNotification.notification = notification
        return
      end if
    end for
  end if
end sub

rem *******************************************************
rem ** EVENT HANDLERS
rem *******************************************************

rem --
rem -- onNotificationStateChange
rem --
rem -- Called when the notification state has changed. If the user has
rem -- dismissed the notification then update our registry and show the
rem -- next notification (if any).
rem --
sub onNotificationStateChange()
  if m.nNotification.state = "dismissed"
    m.nNotification.visible = false
    RegistryWrite("Crex", "LastSeenNotification", m.nNotification.notification.StartDateTimeSeconds.ToStr())
    m.mbMenuBar.SetFocus(true)

    showNextNotification()
  end if
end sub

rem --
rem -- onDataChange()
rem --
rem -- Called when the data has been changed to a new value. Load the
rem -- content from the new URL specified by the data.
rem --
sub onDataChange()
  m.config = ParseJson(m.top.data)

  if m.config <> invalid
    rem --
    rem -- Pre-process any notifications to get the date as seconds
    rem --
    if m.config.Notifications <> invalid
      for each notification in m.config.Notifications
        startDateTime = CreateObject("roDateTime")
        startDateTime.FromISO8601String(notification.StartDateTime)
        startDateTime.ToLocalTime()
        notification.StartDateTimeSeconds = startDateTime.AsSeconds()
      end for

      rem -- This method requires the key be in all lowercase
      m.config.Notifications.SortBy("startdatetimeseconds")
    end if

    rem --
    rem -- Configure UI elements with the configuration options.
    rem --
    m.pBackground.uri = GetAbsoluteUrl(BestMatchingUrl(m.config.BackgroundImage))

    rem --
    rem -- Build a list of buttons provided in the config.
    rem --
    buttons = []
    for each b in m.config.buttons
      buttons.Push(b.Title)
    end for

    rem --
    rem -- Set the menu bar's buttons to those we found in the config.
    rem --
    m.mbMenuBar.buttons = buttons
  else
    m.top.templateState = "failed"
  end if
end sub

rem --
rem -- onFocusedChildChange()
rem --
rem -- The focus has changed to or from us. If it was set to us then make
rem -- sure the item list control has the actual focus.
rem --
sub onFocusedChildChange()
  if m.top.IsInFocusChain() and m.top.HasFocus()
    m.mbMenuBar.SetFocus(true)
  end if
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
  if m.pBackground.loadStatus = "ready" or m.pBackground.loadStatus = "failed"
    m.top.templateState = "ready"
    showNextNotification()
  end if
end sub

rem --
rem -- onSelectedButtonIndex()
rem --
rem -- A menu button has been selected. Show the selected item on
rem -- the screen.
rem --
sub onSelectedButtonIndex()
  item = m.config.Buttons[m.mbMenuBar.selectedButtonIndex]

  m.top.crexScene.callFunc("ShowItem", item.ActionUrl)
end sub

rem --
rem -- onKeyEvent(key, press)
rem --
rem -- Called when the user presses a button on the remote. Check if we
rem -- need to handle any keys to change selection or activate their
rem -- current button.
rem --
rem -- @param key Contains the key that was pressed on the remote.
rem -- @param press True if the button was pressed, false if released.
rem -- @returns True if the key was handled, false otherwise.
rem --
function onKeyEvent(key as string, press as boolean) as boolean
  if press
    if key = "up" and m.nNotification.visible
      if not m.nNotification.IsInFocusChain()
        m.nNotification.SetFocus(true)
      end if

      return true
    else if key = "down"
      if not m.mbMenuBar.IsInFocusChain()
        m.mbMenuBar.SetFocus(true)
      end if

      return true
    end if
  end if

  return false
end function
