looting = {}
dofile("extension.lua")

function looting.init()
   looting.window = g_ui.displayUI("looting.otui")
   looting.window:hide()
end

function looting.terminate()
   looting.window:destroy()
end

function looting.toggle()
	if looting.window then
        if looting.window:isVisible() then
            looting:hide()
        else
        	looting.window:show()
        	looting.window:focus(true)
        end
    end
end