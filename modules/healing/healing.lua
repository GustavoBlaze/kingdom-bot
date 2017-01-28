healing = {}

function healing.init()
    healing.window = g_ui.displayUI("healing.otui")
    healing.window:hide()
end

function healing.toggle()
    if not healing.window then
       return
    end

    if healing.window:isVisible() then
        healing.window:hide()
    else
        healing.window:show()
        healing.window:focus(true)
    end
end


function healing.terminate()
    healing.window:destroy()
end

return healing