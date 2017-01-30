healing = {}

function healing.init()
        healing.window = g_ui.displayUI("healing.otui")
      healing.window:hide()

    -- widgets of paramters
    healing.type = healing.window:getChildById('healType')
    healing.spell = healing.window:getChildById('healSpell')
    healing.min = healing.window:getChildById('minPercent')
    healing.max = healing.window:getChildById('maxPercent')
    
    healing.spell.onMouseRelease = healing.choosingItem
    -- perfil list
    healing.listWidget = healing.window:getChildById('perfil_list')

    healing.list = {}
    healing.list['Mana'] = {}
    healing.list['Health'] = {}

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

function healing.addPerfilToList(h_type, h_spell, h_min, h_max)
    local params = {}
    params[1] = h_type or healing.type:getText()
    params[2] = h_spell or healing.spell:getText()
    params[3] = h_min or healing.min:getText()
    params[4] = h_max or healing.max:getText()

    for key, value in pairs(params) do
        if value == '' then
            return print("Coloque todos os parametros")
        end
    end

    local perfils = healing.listWidget:getChildren()
    params[5] = tostring(#perfils+1)
    local item = g_ui.createWidget('HealPerfil', healing.listWidget)

    item:getChildById('type'):setText(params[1])
    item:getChildById('spell'):setText(params[2])
    item:getChildById('min'):setText(params[3])
    item:getChildById('max'):setText(params[4])
    item:setId(params[5])

    table.insert(healing.list[params[1]], params)

    healing.spell:setText('')
    healing.min:setText('')
    healing.max:setText('')
end

function healing.removePerfilFromList()
    local item = healing.listWidget:getFocusedChild()
    if not item then
        return
    end
    
    local params = {}

    params[1] = item:getChildById('type'):getText()
    params[2] = item:getChildById('spell'):getText()
    params[3] = item:getChildById('min'):getText()
    params[4] = item:getChildById('max'):getText()
    params[5] = item:getId()

    for k,v in pairs(healing.list[params[1]]) do
        if v[5] == params[5] then
            healing.list[params[1]][k] = nil
        end
    end

    healing.type:setText(item:getChildById('type'):getText())
    healing.spell:setText(item:getChildById('spell'):getText())
    healing.min:setText(item:getChildById('min'):getText())
    healing.max:setText(item:getChildById('max'):getText())

    item:destroy()
end
function healing.terminate()
    healing.window:destroy()
    healing.disconnectHealthListener()
end

function healing.onHealthChange(player, health, maxHealth, oldHealth, restoreType, tries, spell, healthMin, healthMax)
    local tries = tries or 10
    if restoreType and spells and healthMin and healthMax then
        if restoreType == 'item' then
            local delay = 0
            player = g_game.getLocalPlayer()
            local life = player:getHealthPercent()

            if life >= healthMin and life <= healthMax then
                local itemId = tonumber(spell)
                g_game.useInventoryItemWith(itemId, g_game.getLocalPlayer())
            end
            delay = math.min(500, g_game.getPing()*1.5)
            local nextHeal = scheduleEvent(function()
                player = g_game.getLocalPlayer()
                local life = player:getHealthPercent()
                health, maxHealth = player:getHealth(), player:getMaxHealth()
                if life >= healthMin and life <= healthMax and tries > 0 then
                    tries = tries - 1
                    healing.onHealthChange(player, health, maxHealth, health, "item", tries, healthMin, healthMax)
                else
                    removeEvent(nextHeal)
                end
            end, delay)
        elseif restoreType == "spell" then
            local delay = 0
            player = g_game.getLocalPlayer()
            local life = player:getHealthPercent()

            if life >= healthMin and life <= healthMax then
                g_game.talk(spell)
            end

            delay = math.min(500, g_game.getPing()*1.5)
            local nextHeal = scheduleEvent(function()
                player = g_game.getLocalPlayer()
                local life = player:getHealthPercent()
                health, maxHealth = player:getHealth(), player:getMaxHealth()
                if life >= healthMin and life <= healthMax and tries > 0 then
                    tries = tries - 1
                    healing.onHealthChange(player, health, maxHealth, health, "spell", tries, spell, healthMin, healthMax)
                else
                    removeEvent(nextHeal)
                end
            end, delay)
        end
    else
        for key, params in pairs(healing.list['Health']) do
            local spell = tonumber(params[2]) or params[2]
            if type(spell) == 'string' then
                local delay = 0
                local life = player:getHealthPercent()
                healthMin, healthMax = tonumber(params[3]), tonumber(params[4])
                if life >= healthMin and life <= healthMax then
                    g_game.talk(spell)
                end
                delay = math.min(500, g_game.getPing()*1.5)
                local nextHeal = scheduleEvent(function()
                    player = g_game.getLocalPlayer()
                    local life = player:getHealthPercent()
                    health, maxHealth = player:getHealth(), player:getMaxHealth()
                    if life >= tonumber(params[3])and life <= healthMax and tries > 0 then
                        tries = tries - 1
                        healing.onHealthChange(player, health, maxHealth, health, "spell", tries, spell, healthMin, healthMax)
                    else
                        removeEvent(nextHeal)
                    end
                end, delay)

            elseif type(spell) == 'number' then
                local delay = 0
                local life = player:getHealthPercent()
                healthMin, healthMax = tonumber(params[3]), tonumber(params[4])
                if life >= healthMin and life <= healthMax then
                    local itemId = spell
                    g_game.useInventoryItemWith(itemId, g_game.getLocalPlayer())
                end
                delay = math.min(500, g_game.getPing()*1.5)
                local nextHeal = scheduleEvent(function()
                    player = g_game.getLocalPlayer()
                    local life = player:getHealthPercent()
                    health, maxHealth = player:getHealth(), player:getMaxHealth()
                    if life >= healthMin and life <= healthMax and tries > 0 then
                        tries = tries - 1
                        healing.onHealthChange(player, health, maxHealth, health, "item", tries, spell, healthMin, healthMax)
                    else
                        removeEvent(nextHeal)
                    end
                end, delay)

            end
        end
    end
end

function healing.connectHealthListener()
    if g_game.isOnline() then
        local player = g_game.getLocalPlayer()
        addEvent(healing.onHealthChange(player, player:getHealth(), player:getMaxHealth(), player:getHealth()))
    end

    connect(LocalPlayer, {onHealthChange =  healing.onHealthChange})
end

function healing.disconnectHealthListener()
    disconnect(LocalPlayer, {onHealthChange =  healing.onHealthChange})
end

function healing.choosingItem(self, mousePosition, mouseButton)
    if g_keyboard.getModifiers() == 1 then
        local menu = g_ui.createWidget('PopupMenu')
        menu:addOption(tr('Choose Item'), function() healing.startChooseItem(healing.setItemCallback) end)
        menu:display(mousePosition)
    end
end

function healing.setItemCallback(self, item)
    if item then
        local str = tostring(item:getId())
        healing.spell:setText(str)
        healing.toggle()
    end
    return true
end

function healing.startChooseItem(callback) -- Copyied from candybot

  if not callback then
    error("No mouse release callback parameter set.")
  end
  local mouseGrabberWidget = g_ui.createWidget('UIWidget')
  mouseGrabberWidget:setVisible(false)
  mouseGrabberWidget:setFocusable(false)

  connect(mouseGrabberWidget, { onMouseRelease = function(self, mousePosition, mouseButton)
    local item = nil
    if mouseButton == MouseLeftButton then
      local clickedWidget = modules.game_interface.getRootPanel()
        :recursiveGetChildByPos(mousePosition, false)
    
      if clickedWidget then
        if clickedWidget:getClassName() == 'UIMap' then
          local tile = clickedWidget:getTile(mousePosition)
          
          if tile then
            local thing = tile:getTopMoveThing()
            if thing then
              item = thing:asItem()
            end
          end
          
        elseif clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
          item = clickedWidget:getItem()
        end
      end
    end
    
    if callback(self, item) then
      -- revert mouse change
      g_mouse.popCursor()
      self:ungrabMouse()
      self:destroy()
    end
  end })
  
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')

  healing.toggle()
end
return healing