targeting = {}

dofile('class.lua')

function targeting.init()
    targeting.window = g_ui.displayUI("targeting.otui")
    targeting.window:hide()

end

function targeting.toggle()
    if targeting.window:isVisible() then
        targeting.window:hide()
    else
        targeting.window:show()
        targeting.window:focus()
    end
end
function targeting.terminate()
   targeting.window:destroy()
end