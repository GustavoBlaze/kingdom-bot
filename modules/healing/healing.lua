healing = {}

function healing.init()
    healing.window = g_ui.displayUI("healing.otui")
    healing.window:hide()

    -- widgets of paramters
    healing.type = healing.window:getChildById('healType')
    healing.spell = healing.window:getChildById('healSpell')
    healing.min = healing.window:getChildById('minPercent')
    healing.max = healing.window:getChildById('maxPercent')

    -- perfil list
    healing.list = healing.window:getChildById('perfil_list')


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

function healing.addPerfilToList()
    local params = {}
    params[1] = healing.type:getText()
    params[2] = healing.spell:getText()
    params[3] = healing.min:getText()
    params[4] = healing.max:getText()

    for key, value in pairs(params) do
        if value == '' then
            return print("Coloque todos os parametros")
        end
    end

    local perfils = healing.list:getChildren()
    local item = g_ui.createWidget('HealPerfil', healing.list)

    item:getChildById('type'):setText(params[1])
    item:getChildById('spell'):setText(params[2])
    item:getChildById('min'):setText(params[3])
    item:getChildById('max'):setText(params[4])
end

function healing.removePerfilFromList()
    local item = healing.list:getFocusedChild()
    if not item then
        return
    end

    item:destroy()
end
function healing.terminate()
    healing.window:destroy()
end

return healing