g_button = nil
g_window = nil

function init()
    g_button = modules.client_topmenu.addRightToggleButton('kingdom_button', tr('Kingdom Bot'), 'icon.png', toggle, true)
    g_window = g_ui.displayUI("kingdombot.otui")
    g_window:hide()

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
    g_button:destroy()
    g_button = nil
end
