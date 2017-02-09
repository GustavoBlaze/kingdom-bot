targeting = {}

dofile('extension.lua')

targeting.event = nil

local m_delay = 1000
local m_spellTime = 0
local attackMode = {
  ['Full Attack'] = FightOffensive or 1,
  ['Balance'] = FightBalanced or 2,
  ['Full Defensive'] = FightDefensive or 3
}

local function windowChild(id)
  return targeting.window:getChildById(id)
end

function targeting.setLastTargetId(id)
  if targeting.lastTargetId then
    if targeting.lastTargetId ~= id then
       targeting.lastTargetId = id
    end
  else
    targeting.lastTargetId = id
  end
end

function targeting.getLastTargetId()
  return targeting.lastTargetId
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
  
  targeting.installHookMenu()
end

function targeting.installHookMenu()
  modules.game_interface.addMenuHook("targeting", tr("Add Target"), 
    function(menuPosition, lookThing, useThing, creatureThing)
      targeting.createTargetFromName(creatureThing:getName())
    end,
    function(menuPosition, lookThing, useThing, creatureThing)
      return lookThing ~= nil and creatureThing ~= nil and creatureThing:isMonster() and creatureThing:getName() ~= nil
    end)
end

function targeting.removeHook()
  modules.game_interface.removeMenuHook("targeting", tr("Add Target"))
end

function targeting.createTargetFromName(name)
  if not name then
    return
  end

  if targeting.window:isVisible() then
    targeting.name:setText(name)
  else
    targeting.window:show()
    targeting.window:focus()
    targeting.name:setText(name)
  end
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
  targeting.removeHook()
  targeting.window:destroy()
  targeting.stopEvent()
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

  item:setId(target.id)

  targeting.newSettings()
end

function targeting.removeTargetFromList(name)
  if not name then
    local item = targeting.monsterList:getFocusedChild()
    if not item then
      return print("You need select the target on list to remove")
    end
    item:destroy()
  else

  end
end

function targeting.editTarget()
  local item = targeting.monsterList:getFocusedChild()

  if not item then
    return
  end
  

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

  local list = targeting.getTargetList()

  if table.size(list) == 0 then
    return
  end

  local player = g_game:getLocalPlayer()
  if player:hasState(PlayerStates.Pz) then
    return
  end

  local targetList = {}
  for k,v in pairs(list) do
    table.insert(targetList, v.name:lower())
  end
  
  local creatures = player:getTargetsInArea(targetList, true)

  if #creatures == 0 then
    return
  end

  local attackingCreature = g_game.getAttackingCreature()

  if attackingCreature then
    if attackingCreature:isDead() or attackingCreature:isRemoved() then
      g_game.cancelAttack()
    end
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
    
    targeting.chaseMode(settings)
    
    targeting.pvpMode(settings)

    targeting.useItemOrSpell(attackingCreature, settings)
    
    targeting.doMovement(player, attackingCreature, settings)

    targeting.setLastTargetId(attackingCreature:getId())
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
        targeting.chaseMode(settings)
        targeting.pvpMode(settings)
        targeting.doMovement(player, v.creature, settings)
        targeting.setLastTargetId(v.creature:getId())
        break
      end
    end
  end
end

function targeting.canLoot(creature)
  if not creature then
    return false
  end

  if not creature:isMonster() then
    return false
  end

  local list = targeting.getTargetList()
  local targetList = {}
  for k,v in pairs(list) do
    table.insert(targetList, v.name:lower())
  end

  if not table.contains(targetList, creature:getName():lower(), true) then
    print(1)
    return false
  end

  local settings = targeting.getCreatureSettings(creature)

  if toboolean(settings.loot) == true then
    return true
  end

  return false
end

function targeting.chaseMode(settings) -- follow creature
  local chaseMode = toboolean(g_game.getChaseMode())
  local follow = toboolean(settings.follow)
  if follow ~= chaseMode then
     if follow then
       g_game.setChaseMode(ChaseOpponent)
     else
       g_game.setChaseMode(DontChase)
     end
  end
end

function targeting.pvpMode(settings)
  local fightMode = g_game.getFightMode()
  local pvpMode = settings.attack
  if attackMode[pvpMode] ~= fightMode then
    g_game.setFightMode(attackMode[pvpMode])
  end
end

function targeting.getTargetList()
  local targets = {} 

  local list = targeting.monsterList:getChildren()
  if #list == 0 then
    return targets
  end

  for k,v in pairs(list) do
    local target = Target.create(v:getChildById('name'):getText(),
      v:getChildById('min'):getText(),
      v:getChildById('max'):getText(),
      v:getChildById('movement'):getText(),
      v:getChildById('danger'):getText(),
      v:getChildById('attack'):getText(),
      v:getChildById('spell'):getText(),
      v:getChildById('follow'):getText(),
      v:getChildById('loot'):getText())
    table.insert(targets, target)
  end
  
  return targets
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

function targeting.doMovement(player, creature, settings)
  if settings.movement == "No Movement" then
    return
  end

  if settings.movement == "Diagonal" then
    local diagonals, result = player:getDiagonals(creature)

    if #diagonals == 0 and result == true then
      return -- player position and creature position is the same
    elseif diagonals == 0 and result == false then
      return -- is not possible walk to diagonal
    elseif #diagonals > 0 and result == true then
      g_game.autoWalk(diagonals[1])
    end
  end
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
  for k,v in pairs(targeting.getTargetList()) do
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