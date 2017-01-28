g_button = nil
g_window = nil

function init()
    g_button = modules.client_topmenu.addRightToggleButton('kingdom_button', tr('Kingdom Bot'), 'icon.png', toggle, true)
end

function toggle()

end

function terminate()
    g_button:destroy()
    g_button = nil
end