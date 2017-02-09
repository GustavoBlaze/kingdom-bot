dofile('modules/healing/healing.lua')
dofile('modules/targeting/targeting.lua')
dofile('modules/looting/looting.lua')

g_button = nil
g_window = nil

optionsButton = {}

function init()
  g_fonts.importFont("fonts/my-font")
  g_button = modules.client_topmenu.addRightToggleButton('kingdom_button', tr('Kingdom Bot'), 'images/bot_icon.png', toggle, true)
  g_window = g_ui.displayUI("kingdombot.otui")
  g_window:hide()
  
  healing.init()
  targeting.init()
  looting.init()

  optionsButton['healing'] = g_window:getChildById('healingButton')
  optionsButton['targeting'] = g_window:getChildById('targetingButton')
  optionsButton['looting'] = g_window:getChildById('lootingButton')

  optionsButton['healing'].onClick = healing.toggle
  optionsButton['targeting'].onClick = targeting.toggle
  optionsButton['looting'].onClick = looting.toggle
end

function toggle()
  if not g_window then
    return
  end
  
  if g_window:isVisible() then
    g_window:hide()
    g_button:setOn(false)
  else
    g_window:show()
    g_window:focus(true)
    g_button:setOn(true)
  end
end

function terminate()
  healing.terminate()
  targeting.terminate()
  looting.terminate()

  g_window:destroy()
  g_button:destroy()
  g_window = nil
  g_button = nil
end
