rem --
rem -- init()
rem --
rem -- Initialize a new PosterList view that will display a list of items
rem -- in a poster-list style view. This puts a list of items on the right
rem -- side of the screen and a thumbnail preview image on the left. Some
rem -- extra detail information will be displayed below the image if it
rem -- is provided in the item details.
rem --
sub init()
  rem --
  rem -- Set initial view properties.
  rem --
  m.pBackgroundRect = m.top.findNode("pBackgroundRect")
  m.pBackgroundImage = m.top.findNode("pBackgroundImage")
  m.lTitle = m.top.findNode("lTitle")
  m.llMenu = m.top.findNode("llMenu")
  m.cnMenuContent = m.top.findNode("cnMenuContent")
  m.pItemImage = m.top.findNode("pItemImage")
  m.lItemDetailLeft = m.top.findNode("lItemDetailLeft")
  m.lItemDetailRight = m.top.findNode("lItemDetailRight")
  m.lItemDescription = m.top.findNode("lItemDescription")

  rem --
  rem -- Configure customized options.
  rem --
  crex = ReadCache(m, "config")

  rem --
  rem -- Configure common resolution options for the view.
  rem --
  resolution = m.top.getScene().currentDesignResolution
  m.pBackgroundRect.width = resolution.width
  m.pBackgroundRect.height = resolution.height
  m.pBackgroundImage.width = resolution.width
  m.pBackgroundImage.height = resolution.height
  m.pBackgroundImage.loadWidth = resolution.width * 0.04
  m.pBackgroundImage.loadHeight = resolution.height * 0.04

  rem --
  rem -- Configure resolution-specific settings for the view.
  rem --
  if resolution.resolution = "FHD"
    rem --
    rem -- Configure for 1920x1080.
    rem --
    m.lTitle.translation = [80, 60]
    m.lTitle.width = 1760
    m.pItemImage.width = 800
    m.pItemImage.height = 450
    m.pItemImage.translation = [80, 200]
    m.lItemDetailLeft.width = 400
    m.lItemDetailLeft.height = 40
    m.lItemDetailLeft.translation = [80, 655]
    m.lItemDetailRight.width = 400
    m.lItemDetailRight.height = 40
    m.lItemDetailRight.translation = [480, 655]
    m.lItemDescription.width = 800
    m.lItemDescription.height = 280
    m.lItemDescription.translation = [80, 715]
    m.llMenu.translation = [1050, 200]
    m.llMenu.itemSize = [750, 48]
    m.llMenu.itemSpacing = [0, 12]
  else
    rem --
    rem -- Configure for 1280x720.
    rem --
    m.lTitle.translation = [50, 40]
    m.lTitle.width = 1180
    m.pItemImage.width = 544
    m.pItemImage.height = 306
    m.pItemImage.translation = [50, 130]
    m.lItemDetailLeft.width = 272
    m.lItemDetailLeft.height = 26
    m.lItemDetailLeft.translation = [50, 440]
    m.lItemDetailRight.width = 272
    m.lItemDetailRight.height = 26
    m.lItemDetailRight.translation = [322, 440]
    m.lItemDescription.width = 544
    m.lItemDescription.height = 160
    m.lItemDescription.translation = [50, 480]
    m.llMenu.translation = [700, 130]
    m.llMenu.itemSize = [500, 32]
    m.llMenu.itemSpacing = [0, 8]
  end if

  rem --
  rem -- Observe the fields we need to monitor for changes.
  rem --
  m.top.observeField("focusedChild", "onFocusedChildChange")
  m.pBackgroundImage.observeField("loadStatus", "onBackgroundStatus")
  m.llMenu.observeField("itemFocused", "onItemFocusedChange")
  m.llMenu.observeField("itemSelected", "onItemSelectedChange")
end sub

rem *******************************************************
rem ** EVENT HANDLERS
rem *******************************************************

rem --
rem -- onDataChange()
rem --
rem -- The data value has changed. This indicates the URL we should
rem -- pull our configuration information from. We need to re-download
rem -- the configuration and apply it to the display elements.
rem --
sub onDataChange()
  m.config = parseJSON(m.top.data)

  if m.config <> invalid
    rem --
    rem -- Set the text and background image for the list.
    rem --
    m.lTitle.text = m.config.Title
    m.pBackgroundImage.uri = GetAbsoluteUrl(BestMatchingUrl(m.config.BackgroundImage))

    rem --
    rem -- Remove all the old menu items.
    rem --
    while m.cnMenuContent.getChildCount() > 0
      m.cnMenuContent.removeChild(0)
    end while

    rem --
    rem -- Add in new menu items for each item in the list.
    rem --
    for each item in m.config.Items
      node = m.cnMenuContent.createChild("ContentNode")
      node.title = item.Title
    end for
  else
    m.top.templateState = "failed"
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
  if m.pBackgroundImage.loadStatus = "ready" or m.pBackgroundImage.loadStatus = "failed"
    LogMessage(m.pBackgroundImage.loadStatus)
    m.top.templateState = "ready"
  end if
end sub

rem --
rem -- onFocusedChildChange()
rem --
rem -- The focus has changed to or from us. If it was set to us then make
rem -- sure the item list control has the actual focus.
rem --
sub onFocusedChildChange()
  if m.top.IsInFocusChain() and not m.llMenu.HasFocus()
    m.llMenu.SetFocus(true)
  end if
end sub

rem --
rem -- onItemFocusedChange()
rem --
rem -- The menu item focus has changed. Update the UI with the details
rem -- of the currently focused item.
rem --
sub onItemFocusedChange()
  if m.config <> invalid and m.llMenu.itemFocused <> -1
    m.pItemImage.uri = GetAbsoluteUrl(BestMatchingUrl(m.config.Items[m.llMenu.itemFocused].Image))
    m.lItemDetailLeft.text = m.config.Items[m.llMenu.itemFocused].DetailLeft
    m.lItemDetailRight.text = m.config.Items[m.llMenu.itemFocused].DetailRight
    m.lItemDescription.text = m.config.Items[m.llMenu.itemFocused].Description
  else
    m.pItemImage.uri = ""
    m.lItemDetailLeft.text = ""
    m.lItemDetailRight.text = ""
    m.lItemDescription.text = ""
  end if
end sub

rem --
rem -- onItemSelectedChange()
rem --
rem -- An item has been selected from the list. Show the item on the screen.
rem --
sub onItemSelectedChange()
  item = m.config.Items[m.llMenu.itemSelected]

  m.top.crexScene.callFunc("ShowItem", item.ActionUrl)
end sub
