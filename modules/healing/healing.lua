healing = {}

local friend_event = nil
local nextHeal = {}

function healing.init()
    healing.window = g_ui.displayUI("healing.otui")
    healing.window:hide()

    -- widgets of paramters
    healing.type = healing.window:getChildById('healType')
    healing.spell = healing.window:getChildById('healSpell')
    healing.min = healing.window:getChildById('minPercent')
    healing.max = healing.window:getChildById('maxPercent')
    healing.friend = healing.window:getChildById('friendText')
    healing.spell.onMouseRelease = healing.choosingItem
    --lists
    healing.perfilsWidget = healing.window:getChildById('perfil_list')
    healing.friendList = healing.window:getChildById('friendList')



    healing.types = {}
    healing.types['Mana'] = {}
    healing.types['Health'] = {}
    healing.types['Friend'] = {}
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

function healing.addFriend(name)
    local name = name or healing.friend:getText()
 
    if name == '' then
       return print("You need set friend name")
    end
    
    local id = #healing.friendList:getChildren() + 1
    local item = g_ui.createWidget('FriendLabel', healing.friendList)
    item:getChildById('name'):setText(name)
    item:setId(id)

    healing.friend:setText('')
end

function healing.removeFriend()
    local item = healing.friendList:getFocusedChild()
    if not item then
        return
    end

    item:destroy()
end

function healing.addPerfilToList(h_type, h_spell, h_min, h_max)
    local params = {}
    params[1] = h_type or healing.type:getCurrentOption().text
    params[2] = h_spell or healing.spell:getText()
    params[3] = h_min or healing.min:getText()
    params[4] = h_max or healing.max:getText()

    for key, value in pairs(params) do
        if value == '' then
            return print("You need set all paramters")
        end
    end

    params[2] = params[2]:lower()

    local perfils = healing.perfilsWidget:getChildren()
    params[5] = tostring(#perfils+1)
    local item = g_ui.createWidget('HealPerfil', healing.perfilsWidget)

    item:getChildById('type'):setText(params[1])
    item:getChildById('spell'):setText(params[2])
    item:getChildById('min'):setText(params[3])
    item:getChildById('max'):setText(params[4])
    item:setId(params[5])

    table.insert(healing.types[params[1]], params)

    healing.spell:setText('')
    healing.min:setText('')
    healing.max:setText('')
end

function healing.removePerfilFromList()
    local item = healing.perfilsWidget:getFocusedChild()
    if not item then
        return
    end
    
    local params = {}

    params[1] = item:getChildById('type'):getText()
    params[2] = item:getChildById('spell'):getText()
    params[3] = item:getChildById('min'):getText()
    params[4] = item:getChildById('max'):getText()
    params[5] = item:getId()

    for k,v in pairs(healing.types[params[1]]) do
        if v[5] == params[5] then
            healing.types[params[1]][k] = nil
        end
    end

    healing.type:setOption(item:getChildById('type'):getText())
    healing.spell:setText(item:getChildById('spell'):getText())
    healing.min:setText(item:getChildById('min'):getText())
    healing.max:setText(item:getChildById('max'):getText())

    item:destroy()
end
function healing.terminate()
    healing.window:destroy()
    healing.disconnectHealListener()
    healing.stopHealFriend()
end

function healing.onHealthChange(player, health, maxHealth, oldHealth, oldMaxHealth, try)
	if not healing.window:getChildById('enableHeal'):isChecked() then
        return
	end

    local try = try or 10

    for key, params in pairs(healing.types['Health']) do
        local spell = tonumber(params[2]) or params[2]
        if type(spell) == 'string' then
            local delay = 0
            local life = player:getHealthPercent()
            local healthMin, healthMax = tonumber(params[3]), tonumber(params[4])
            if (life >= healthMin and life <= healthMax) then
                local say, match
                match = spell:match("exura sio")
                if match then
                   say = match.." \""..player:getName()
                else
                   say = spell
                end
                g_game.talk(say)
            end
                delay = 500
            removeEvent(nextHeal['health'])
            nextHeal['health'] = scheduleEvent(function()
                local player = g_game.getLocalPlayer()
                if not player then
                    return
                end
                local life = player:getHealthPercent()
                health, maxHealth = player:getHealth(), player:getMaxHealth()
                if life >= healthMin and life <= healthMax and try > 0 then
                    try = try - 1
                    healing.onHealthChange(player, health, maxHealth, health, maxHealth, try)
                else
                    removeEvent(nextHeal['health'])
                    nextHeal['health'] = nil
                end
            end, delay)
            break
        elseif type(spell) == 'number' then
            local delay = 0
            local life = player:getHealthPercent()
            local healthMin, healthMax = tonumber(params[3]), tonumber(params[4])
            if (life >= healthMin and life <= healthMax) then
                local itemId = spell
                g_game.useInventoryItemWith(itemId, g_game.getLocalPlayer())
            end
            delay = 500
            removeEvent(nextHeal['health'])
            nextHeal['health'] = scheduleEvent(function()
                player = g_game.getLocalPlayer()
                if not player then
                    return
                end
                local life = player:getHealthPercent()
                health, maxHealth = player:getHealth(), player:getMaxHealth()
                if (life >= healthMin and life <= healthMax and try > 0) then
                    try = try - 1
                    healing.onHealthChange(player, health, maxHealth, health, maxHealth, try)
                else
                    removeEvent(nextHeal['health'])
                    nextHeal['health'] = nil              
                end
            end, delay)
            break
        end
    end
end

function healing.onManaChange(player, mana, maxMana, oldMana, oldMaxMana, try)
    if not healing.window:getChildById('enableHeal'):isChecked() then
        return
	end
    
    local try = try or 10

    for k, params in pairs(healing.types['Mana']) do
        itemId = tonumber(params[2])
        local delay = 0
        local manaPercent = player:getManaPercent()
        manaMin, manaMax = tonumber(params[3]), tonumber(params[4])

        if manaPercent >= manaMin and manaPercent <= manaMax then
            g_game.useInventoryItemWith(itemId, player)
        end

        delay = 1000

        removeEvent(nextHeal['mana'])
        nextHeal['mana'] = scheduleEvent(function()
            local player = g_game.getLocalPlayer()
            if not player then
                return
            end

            mana, maxMana = player:getMana(), player:getMaxMana()
            local manaPercent = player:getManaPercent()

            if manaPercent >= manaMin and manaPercent <= manaMax and try > 0 then
                try = try - 1
                healing.onManaChange(player, mana, maxMana, mana, maxMana, try)
            else
                removeEvent(nextHeal['mana'])
                nextHeal['mana'] = nil
                
            end
        end, delay)
        break
    end
end
function healing.startHealFriend()
    if friend_event == nil then
        friend_event = cycleEvent(function()
            if not g_game.isOnline() then
                return
            end
            local player = g_game.getLocalPlayer()
            local list = healing.friendList:getChildren()
            local healBar = tonumber(healing.window:getChildById('healFriendBar'):getValue())
            
            if player:getHealthPercent() < healBar then
                return
            end

            if #healing.types['Friend'] == 0 or #list == 0 then
                 return
            end
            local friends = {}

            for k,v in pairs(list) do
                table.insert(friends, v:getChildById('name'):getText())
            end

            local player = g_game.getLocalPlayer()
            local creatures = g_map.getSpectators(player:getPosition(), false)

            for a, creature in pairs(creatures) do
                for b, name in pairs(friends) do
                    if creature:getName():lower() == name:lower() then

                        for c, params in pairs(healing.types['Friend']) do
                            local spell = tonumber(params[2]) or params[2]
                            local min,max = tonumber(params[3]), tonumber(params[4])
                            local life = creature:getHealthPercent()

                            if type(spell) == 'string' then
                                if life >= min and life <= max then
                                    local say, match
                                    match = spell:match("exura sio")
                                    if match then
                                       say = match.." \""..name
                                    else
                                       say = spell
                                    end
                                    return g_game.talk(say)
                                end
                            elseif type(spell) == 'number' then
                                if life >= min and life <= max then
                                    local itemId = spell
                                    g_game.useInventoryItemWith(itemId, creature)
                                end
                            end
                        end
                    end
                end
            end
        end, 600)
    end
end

function healing.stopHealFriend()
    removeEvent(friend_event)
    friend_event = nil
end

function healing.executeHeal()
	if healing.window:getChildById('enableHeal'):isChecked() then
	    if g_game.isOnline() then
	        local player = g_game.getLocalPlayer()
	        addEvent(healing.onHealthChange(player, player:getHealth(), player:getMaxHealth(), player:getHealth()))
	        addEvent(healing.onManaChange(player, player:getMana(), player:getMaxMana(), player:getMana()))
	    end
	end
end
function healing.connectHealistener()
	healing.executeHeal()
    connect(LocalPlayer, {onHealthChange =  healing.onHealthChange})
    connect(LocalPlayer, {onManaChange = healing.onManaChange})
end

function healing.disconnectHealListener()
    disconnect(LocalPlayer, {onHealthChange =  healing.onHealthChange})
    disconnect(LocalPlayer, {onManaChange =  healing.onManaChange})
end

function healing.choosingItem(self, mousePosition, mouseButton)
    if mouseButton == MouseRightButton then
        local menu = g_ui.createWidget('PopupMenu')
        menu:addOption(tr('Choose Item'), function() startChooseItem(healing.setItemCallback) end)
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

function startChooseItem(callback) -- Copyied from candybot

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