looting = {}
dofile("extension.lua")

local function windowChild(id)
	return looting.window:getChildById(id)
end

function looting.init()
   looting.window = g_ui.displayUI("looting.otui")
   looting.window:hide()

   looting.list = windowChild('itemList')
   looting.itemText = windowChild('itemText')
end

function looting.addItemToList(id)
	local id = id or looting.itemText:getText()

	if not id or id == '' then
		return
	end

	if looting.itemText:getText() ~= '' then
		looting.itemText:setText('')
	end

	local item = g_ui.createWidget('LootWidget', looting.list)
	item:getChildById('itemId'):setText(id)
end

function looting.removeItemFromList()
	local item = looting.list:getFocusedChild()
	if not item then
		return
	end

	item:destroy()
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