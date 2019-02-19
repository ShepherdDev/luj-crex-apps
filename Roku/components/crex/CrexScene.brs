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
  m.gViews = m.top.findNode("gViews")
  m.bsLoading = m.top.findNode("bsLoading")
  m.aFadeView = m.top.findNode("aFadeView")
  m.templateTask = invalid
  m.loadingView = invalid

  rem --
  rem -- Load the config file and cache it.
  rem --
  crex = ReadCrexConfig()
  WriteCache(m, "config", crex)

  rem --
  rem -- Set configured values
  rem --
  m.bsLoading.uri = crex.LoadingSpinner
  m.bsLoading.visible = false
  m.bsLoading.control = "stop"
  m.aFadeView.duration = crex.AnimationTime

  rem --
  rem -- Configure UI elements for the screen size we are running.
  rem --
  resolution = m.top.getScene().currentDesignResolution
  if resolution.resolution = "FHD"
    rem --
    rem -- Configure for 1920x1080.
    rem --
    m.bsLoading.translation = [880, 460]
    m.bsLoading.poster.width = 160
    m.bsLoading.poster.height = 160
  else
    rem --
    rem -- Configure for 1280x720.
    rem --
    m.bsLoading.translation = [587, 304]
    m.bsLoading.poster.width = 106
    m.bsLoading.poster.height = 106
  end if

  rem --
  rem -- Observe the fields we need to monitor for changes.
  rem --
  m.aFadeView.observeField("state", "onFadeViewState")

  LogMessage("Launching with Root URL: " + crex.ApplicationRootUrl)

  rem --
  rem -- Default template and root url.
  rem --
  ShowItem(crex.ApplicationRootUrl)
end sub

rem *******************************************************
rem ** METHODS
rem *******************************************************

rem --
rem -- PushView(view)
rem --
rem -- Push a new view onto the stack and set it as the primary
rem -- view with focus.
rem --
rem -- @param view The view to be pushed onto the view stack.
rem --
sub PushView(view as Object)
  rem --
  rem -- Set the view to scale around its center and make it invisible
  rem -- for the fade-in.
  rem --
  resolution = m.top.getScene().currentDesignResolution
  view.scaleRotateCenter = [resolution.width / 2, resolution.height / 2]
  view.opacity = 0

  rem --
  rem -- Set the id of the view so that our animations can target it.
  rem --
  view.id = "viewAnimationTarget"
  m.gViews.appendChild(view)

  rem --
  rem -- Remove all old animations.
  rem --
  while m.aFadeView.getChildCount() > 0
    m.aFadeView.removeChildIndex(0)
  end while

  rem --
  rem -- Configure the animation that handles fading in.
  rem --
  field = m.aFadeView.createChild("FloatFieldInterpolator")
  field.key = [0.0, 1.0]
  field.keyValue = [0.0, 1.0]
  field.fieldToInterp = "viewAnimationTarget.opacity"

  rem --
  rem -- Configure the animation that handles the subtle zoom effect.
  rem --
  field = m.aFadeView.createChild("Vector2DFieldInterpolator")
  field.key = [0.0, 0.5, 1.0]
  field.keyValue = [[0.95, 0.95], [1.0, 1.0], [1.0, 1.0]]
  field.fieldToInterp = "viewAnimationTarget.scale"

  rem --
  rem -- Notify the view to do final initialization.
  rem --
  view.callFunc("willShowView")

  rem --
  rem -- Indicate that we are fading in, then start the animation.
  rem --
  m.viewFadingIn = true
  m.aFadeView.control = "start"
end sub

rem --
rem -- PopActiveView()
rem --
rem -- Removes the top-most view from the stack and returns control
rem -- to the view behind it, or to the main menu if no views remain.
rem --
sub PopActiveView()
  rem --
  rem -- Tag the top-most view so our animations can target it.
  rem --
  m.gViews.getChild(m.gViews.getChildCount() - 1).id = "viewAnimationTarget"

  rem --
  rem -- Remove all existing animations.
  rem --
  while m.aFadeView.getChildCount() > 0
    m.aFadeView.removeChildIndex(0)
  end while

  rem --
  rem -- Configure the animation for fading the view out.
  rem --
  field = m.aFadeView.createChild("FloatFieldInterpolator")
  field.key = [0.0, 1.0]
  field.keyValue = [1.0, 0.0]
  field.fieldToInterp = "viewAnimationTarget.opacity"

  rem --
  rem -- Configure the animation for zooming the view out a bit.
  rem --
  field = m.aFadeView.createChild("Vector2DFieldInterpolator")
  field.key = [0.0, 0.0, 1.0]
  field.keyValue = [[1.0, 1.0], [1.0, 1.0], [0.95, 0.95]]
  field.fieldToInterp = "viewAnimationTarget.scale"

  rem --
  rem -- Set the flag indicating we are fading out and start the
  rem -- animations.
  rem --
  m.viewFadingIn = false
  m.aFadeView.control = "start"
end sub

rem --
rem -- ShowItem(url)
rem --
rem -- Shows an item on screen by requesting the data in the
rem -- url supplied.
rem --
rem -- @param url The url that contains the data to be shown.
rem --
sub ShowItem(url as String)
  if m.templateTask <> invalid or m.loadingView <> invalid
    LogMessage("Tried to ShowItem while already loading.")
    return
  end if

  rem --
  rem -- Show the loading spinner.
  rem --
  m.bsLoading.control = "start"
  m.bsLoading.visible = true
  m.bsLoading.setFocus(true)

  rem --
  rem -- Start a task to load the URL data.
  rem --
  m.templateTask = CreateObject("roSGNode", "URLTask")
  m.templateTask.url = GetAbsoluteUrl(url)
  m.templateTask.observeField("content", "onTemplateTaskChanged")
  m.templateTask.control = "RUN"
end sub

rem --
rem -- ShowTemplate(url)
rem --
rem -- Shows a template from the data provided.
rem --
rem -- @param item The object that contains the templte and data.
rem --
sub ShowTemplate(item as Object)
  rem --
  rem -- Each item should have a Template and Url property.
  rem --
  if item.Template <> invalid and item.Data <> invalid
    if item.RequiredCrexVersion <> invalid and item.RequiredCrexVersion > GetCrexVersion()
      ShowUpdateRequiredDialog(false)
      return
    end if

    m.loadingView = CreateObject("roSGNode", item.Template + "View")
    m.loadingView.crexScene = m.top
    m.loadingView.observeField("templateState", "onTemplateStateChange")
    m.loadingView.data = FormatJson(item.Data)
  else
    m.bsLoading.control = "stop"
    m.bsLoading.visible = false
    if m.gViews.getChildCount() > 0
      m.gViews.getChild(m.gViews.getChildCount() - 1).setFocus(true)
    end if

    ShowLoadingErrorDialog(false)
  end if
end sub

rem *******************************************************
rem ** EVENT HANDLERS
rem *******************************************************

rem --
rem -- onTemplateTaskChanged()
rem --
rem -- The URL download task has finished and provided content for
rem -- use to parse.
rem --
sub onTemplateTaskChanged()
  rem --
  rem -- Try to parse the retrieved content as JSON.
  rem --
  data = invalid
  if m.templateTask <> invalid and m.templateTask.success = true
    data = parseJSON(m.templateTask.content)
  end if
  m.templateTask = invalid

  if data <> invalid
    ShowTemplate(data)
  else
    if m.gViews.getChildCount() > 0
      m.gViews.getChild(m.gViews.getChildCount() - 1).setFocus(true)
    end if

    ShowLoadingErrorDialog(false)
  end if
end sub

rem --
rem -- onTemplateStateChange()
rem --
rem -- The template has indicated that it is either fully
rem -- loaded or has failed to load.
rem --
sub onTemplateStateChange()
  m.bsLoading.control = "stop"
  m.bsLoading.visible = false
  loadingView = m.loadingView
  m.loadingView.unobserveField("templateState")
  m.loadingView = invalid

  if loadingView.templateState = "ready"
    PushView(loadingView)
  else
    if m.gViews.getChildCount() > 0
      m.gViews.getChild(m.gViews.getChildCount() - 1).setFocus(true)
    end if

    ShowLoadingErrorDialog(false)
  end if
end sub

rem --
rem -- onFadeViewState()
rem --
rem -- A fade animation for showing or hiding a view has completed. Do
rem -- final processing.
rem --
sub onFadeViewState()
  if m.aFadeView.state = "stopped"
    if m.viewFadingIn = true
      rem --
      rem -- If we were fading in, make sure the new view has focus
      rem -- and clear the animation identifier.
      rem --
      m.gViews.getChild(m.gViews.getChildCount() - 1).setFocus(true)
      m.gViews.getChild(m.gViews.getChildCount() - 1).id = ""
    else
      rem --
      rem -- If we were fading out, remove the old view.
      rem --
      m.gViews.removeChildIndex(m.gViews.getChildCount() - 1)

      rem --
      rem -- Set the focus to either the previous view on the stack
      rem -- or the main menu bar if no views remain.
      rem --
      m.gViews.getChild(m.gViews.getChildCount() - 1).setFocus(true)
    end if
  end if
end sub

rem --
rem -- onKeyEvent(key, press)
rem --
rem -- A key has been pressed or released on the remote. Do any
rem -- required processing to handle the event.
rem --
rem -- @param key The description of the key that was pressed or released.
rem -- @param press True if the key was pressed, false if it was released.
rem -- @returns True if the key was handled, false otherwise.
rem --
function onKeyEvent(key as string, press as boolean) as boolean
  rem --
  rem -- Consume all key events if we are currently transitioning
  rem -- between views.
  rem --
  if m.aFadeView.state = "running"
    return true
  end if

  if press
    if key = "back"
      rem --
      rem -- If we don't have any views visible yet just let
      rem -- the app exit.
      rem --
      if m.gViews.getChildCount() = 0
        return false
      end if

      rem --
      rem -- If we are loading the URL, cancel.
      rem --
      if m.templateTask <> invalid
        m.templateTask.cancel = true
        m.templateTask = invalid
        m.bsLoading.visible = false
        m.bsLoading.control = "stop"
        m.gViews.getChild(m.gViews.getChildCount() - 1).setFocus(true)
        return true
      end if

      rem --
      rem -- If we are waiting for the view to enter ready state, cancel.
      rem --
      if m.loadingView <> invalid
        m.loadingView = invalid
        m.bsLoading.visible = false
        m.bsLoading.control = "stop"
        m.gViews.getChild(m.gViews.getChildCount() - 1).setFocus(true)
        return true
      end if

      rem --
      rem -- If the back button was pressed and we have views on
      rem -- the stack, then pop the active view. Otherwise allow
      rem -- the back button to exit out of the app.
      rem --
      if m.gViews.getChildCount() > 1
        PopActiveView()

        return true
      else
        return false
      end if
    end if
  end if

  return false
end function
