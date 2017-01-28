dofile('modules/healing/healing.lua')

g_button = nil
g_window = nil

optionsButton = {}

function init()
    g_button = modules.client_topmenu.addRightButton('kingdom_button', tr('Kingdom Bot'), 'icon.png', toggle, true)
    g_window = g_ui.displayUI("kingdombot.otui")
    g_window:hide()
    
    healing.init()

    optionsButton['healing'] = g_window:getChildById('healingButton')
    optionsButton['healing'].onClick = healing.toggle

end

function toggle()
    if not g_window then
        return
    end
    
    if g_window:isVisible() then
        g_window:hide()
    else
        g_window:show()
        g_window:focus(true)
    end
end

function terminate()
    healing.terminate()

    g_window:destroy()
    g_button:destroy()
    g_window = nil
    g_button = nil
end
