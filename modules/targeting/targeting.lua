targeting = {}

dofile('class.lua')

targeting.event = nil
local m_delay = 1000
local m_spellTime = 0

local function windowChild(id)
	return targeting.window:getChildById(id)
end

function targeting.init()
    targeting.window = g_ui.displayUI("targeting.otui")
    targeting.window:hide()
    
    targeting.monsterList = windowChild('monsterList')
    targeting.name = windowChild('name')
    targeting.min = windowChild('min')
    targeting.max = windowChild('max')
    targeting.movement = windowChild('movement')
    targeting.danger = windowChild('danger')
    targeting.attack = windowChild('attack')
    targeting.spell = windowChild('spell')
    targeting.follow = windowChild('follow')
    targeting.loot = windowChild('loot')

    targeting.spell.onMouseRelease = targeting.choosingItem

    targeting.run = windowChild('run')
    targeting.range = windowChild('range')

    targeting.Targets = {}

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
   targeting.stopEvent()
   targeting.Targets = nil
end

function targeting.choosingItem(self, mousePosition, mouseButton)
    if mouseButton == MouseRightButton then
        local menu = g_ui.createWidget('PopupMenu')
        menu:addOption(tr('Choose Item'), function() modules.kingdom_bot.startChooseItem(targeting.setItemCallback) end)
        menu:display(mousePosition)
    end
end

function targeting.setItemCallback(self, item)
    if item then
        local str = tostring(item:getId())
        targeting.spell:setText(str)
    end
    return true
end

function targeting.addTargetToList(name, min, max, movement, danger, attack, spell, follow, loot) -- All the parameters have to be string
    local target = Target.create(name or targeting.name:getText(), 
    	min or targeting.min:getText(),
    	max or targeting.max:getText(),
    	movement or targeting.movement:getCurrentOption().text,
    	danger or tostring(targeting.danger:getCurrentOption().text),
    	attack or targeting.attack:getCurrentOption().text,
    	spell or targeting.spell:getText(),
    	follow or tostring(targeting.follow:isChecked()),
    	loot or tostring(targeting.loot:isChecked()))

    for k,value in pairs(target) do
        if not value then
        	return print(k, "nil")
        end
        if value == '' and k ~= "spell" then
             return print(k, "is empty")
        end
    end

    local widgets = targeting.monsterList:getChildren()
    target:setId(tostring(#widgets + 1))

    local item = g_ui.createWidget('MosterLabel', targeting.monsterList)

    for k,v in pairs(target) do
        if k ~= "id" then
            item:getChildById(k):setText(v)
        end
    end

    targeting.Targets[target.id] = target

    item:setId(target.id)

    targeting.newSettings()
end

function targeting.removeTargetFromList(id)
    if not id then
        local item = targeting.monsterList:getFocusedChild()
        if not item then
            return print("You need select the target on list to remove")
        end
        targeting.Targets[item:getId()] = nil
        item:destroy()
    else
       if targeting.Targets[id] then
           targeting.Targets[id] = nil
       else
           return print("This target not exists on list")
       end
    end
end

function targeting.editTarget()
	local item = targeting.monsterList:getFocusedChild()

	if not item then
        return
    end
    
    targeting.Targets[item:getId()] = nil

    targeting.name:setText(item:getChildById('name'):getText())
    targeting.min:setText(item:getChildById('min'):getText())
    targeting.max:setText(item:getChildById('max'):getText())
    targeting.movement:setCurrentOption(item:getChildById('movement'):getText())
    targeting.danger:setCurrentOption(tonumber(item:getChildById('danger'):getText()))
    targeting.attack:setCurrentOption(item:getChildById('attack'):getText())
    targeting.spell:setText(item:getChildById('spell'):getText())
    targeting.follow:setChecked(toboolean(item:getChildById('follow'):getText()))
    targeting.loot:setChecked(toboolean(item:getChildById('loot'):getText()))

    item:destroy()

end
function targeting.newSettings()
    targeting.name:setText('')
    targeting.min:setText('0')
    targeting.max:setText('100')
    targeting.movement:setCurrentIndex(1)
    targeting.danger:setCurrentIndex(1)
    targeting.attack:setCurrentIndex(1)
    targeting.spell:setText('')
    targeting.follow:setChecked(false)
    targeting.loot:setChecked(false)
end

function targeting.executeTargeting()
	if not targeting.run:isChecked() then
		return targeting.stopEvent()
	end
    if not g_game.isOnline() then
    	return
    end

    if table.size(targeting.Targets) == 0 then
    	return
    end

    local player = g_game:getLocalPlayer()
    if player:hasState(PlayerStates.Pz) then
    	return
    end

    local targetList = {}
    for k,v in pairs(targeting.Targets) do
        table.insert(targetList, v.name:lower())
    end
    
    local creatures = player:getTargetsInArea(targetList, true)

    if #creatures == 0 then
        return
    end

    local attackingCreature = g_game.getAttackingCreature()

    if attackingCreature then
        local health = attackingCreature:getHealthPercent()
        local settings = targeting.getCreatureSettings(attackingCreature)
        local distance = player:getCreatureDistance(attackingCreature)
        local TCreatures = {}
        
        for k,v in pairs(creatures) do
            local tcreature = TCreature.create(v, tonumber(targeting.getCreatureSettings(v).danger))
            table.insert(TCreatures, tcreature)
        end
    
        TCreatures = targeting.filterByRange(TCreatures)

        for k,v in pairs(TCreatures) do
            local t_settings = targeting.getCreatureSettings(v.creature)
            local t_health = v.creature:getHealthPercent()

            if tonumber(settings.danger) < tonumber(t_settings.danger) then
                if t_health >= tonumber(t_settings.min) and t_health <= tonumber(t_settings.max) then
                	if player:getCreatureDistance(v.creature) <= tonumber(targeting.range:getCurrentOption().text) then
                        g_game.attack(v.creature)
                        return
                    end
                end
            end
        end
        if not (health >= tonumber(settings.min) and health <= tonumber(settings.max)) or 
        	distance > tonumber(targeting.range:getCurrentOption().text) then

            g_game.cancelAttack()
            return
        end
        
        local chaseMode = toboolean(g_game.getChaseMode())
        local follow = toboolean(settings.follow)
        if follow ~= chaseMode then
           if follow then
               g_game.setChaseMode(ChaseOpponent)
           else
               g_game.setChaseMode(DontChase)
           end
        end

        targeting.useItemOrSpell(attackingCreature, settings)
       
    elseif attackingCreature == nil then

        local TCreatures = {}
        
        for k,v in pairs(creatures) do
            local tcreature = TCreature.create(v, tonumber(targeting.getCreatureSettings(v).danger))
            table.insert(TCreatures, tcreature)
        end
    
        TCreatures = targeting.filterByRange(TCreatures)

        if g_game.isAttacking() then
        	return
        end

        for k,v in pairs(TCreatures) do
        	local settings = targeting.getCreatureSettings(v.creature)
        	local health = v.creature:getHealthPercent() 
            if health >= tonumber(settings.min) and health <= tonumber(settings.max) 
            	and player:getCreatureDistance(v.creature) <= tonumber(targeting.range:getCurrentOption().text) then
                g_game.attack(v.creature)

                local chaseMode = toboolean(g_game.getChaseMode())
                local follow = toboolean(settings.follow)
                if follow ~= chaseMode then
                   if follow then
                       g_game.setChaseMode(ChaseOpponent)
                   else
                       g_game.setChaseMode(DontChase)
                   end
                end
                break
            end
        end
    end
end

function targeting.useItemOrSpell(creature, settings)
    if settings.spell == '' then
    	return
    end

    local nowTime = g_clock.millis()
    
    if not (nowTime - m_spellTime > 2000) then
        return
    end
    
    m_spellTime = nowTime

    local spell = tonumber(settings.spell) or settings.spell
    
    if type(spell) == 'string' then
        g_game.talk(spell)
    elseif type(spell) == 'number' then
         g_game.useInventoryItemWith(spell, creature)
    end
end

local function getDistanceBetween(p1, p2)
    return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end
function targeting.filterByRange(TCreatures)
	local temp
    for i=1, #TCreatures do
       for j=i+1, #TCreatures do
          if TCreatures[i].danger < TCreatures[j].danger then
              temp = TCreatures[i]
              TCreatures[i]=TCreatures[j]
              TCreatures[j]=temp
          end
       end
    end
    return TCreatures
end

function targeting.getCreatureSettings(creature)
    for k,v in pairs(targeting.Targets) do
        if creature:getName():lower() == v.name:lower() then
            return v
        end
    end
end

function targeting.startEvent()
    if not targeting.event then
        targeting.event = cycleEvent(targeting.executeTargeting, m_delay)
    end
end

function targeting.stopEvent()
    removeEvent(targeting.event)
    targeting.event = nil
end