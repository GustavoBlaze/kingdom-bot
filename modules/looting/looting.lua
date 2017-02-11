looting = {}

local arrayOfItems = require("/kingdom-bot/data/items.lua")

dofile("extension.lua")

local running = false
local millis = 0
local lootEvent = nil

local creatureContainer
local radioItems = {}

function looting.isRunning()
  return running
end

function looting.stop()
  running = false
end

function looting.runCatch()
  millis = g_clock.millis()
  looting.catching = true
end

function looting.stopCatch()
  millis = g_clock.millis()
  looting.catching = false
end

function looting.getCatch()
  return millis, looting.catching
end

function looting.start()
  running = true
end

local function windowChild(id)
  return looting.window:getChildById(id)
end

function looting.init()
  looting.stop()
  looting.window = g_ui.displayUI("looting.otui")
  looting.window:hide()

  looting.searchItems = looting.window:recursiveGetChildById('searchItems')
  looting.catchItems = looting.window:recursiveGetChildById('catchItems')

  looting.itemText = windowChild('itemText')

  looting.stack = Stack.create()

 
  looting.catching = false

  connect(Creature, {onDeath = looting.onTargetDeath})
  connect(Container, {onOpen = looting.onContainerOpen})
end

function looting.onTargetDeath(creature)
  if not creature then
    return
  end

  if not creature:isMonster() then
    return
  end

  if not modules.kingdom_bot.targeting.canLoot(creature) or not modules.kingdom_bot.targeting.run:isChecked() then
    return
  end

  local creatureId = creature:getId()
  local creaturePos = creature:getPosition()

  local deadCreature = {
    id = creatureId,
    position = creaturePos,
    corpse = nil
  }

  scheduleEvent(function()
    local lastTarget = modules.kingdom_bot.targeting.getLastTargetId()
    if lastTarget and lastTarget == creatureId then
    	if table.size(looting.getLootList()) > 0 then
        looting.stack:pushFront(deadCreature)
      end
    else
    	if table.size(looting.getLootList()) > 0 then
        looting.stack:push(deadCreature)
      end
    end
  end, g_game.getPing())
end

function looting.run()
  local m_millis, catching = looting.getCatch()

  if catching and g_clock.millis() - m_millis > 20000 then
    looting.stop()
    looting.stopCatch()
    return
  elseif catch and g_clock.millis() - m_millis < 20000 then
  	return
  end

  if looting.isRunning() or not g_game.isOnline() then
      return
  end

  g_game.cancelAttackAndFollow()

  looting.start()

  if looting.stack:size() > 0 and not catching then
    return looting.nextLoot(looting.stack:popFront())
  else
    looting.stop()
  end
end

function looting.nextLoot(deadCreature, try)
  local try = try or 10
  if not g_game.isOnline() then
    looting.stop()
    return
  end

  g_game.cancelAttackAndFollow()

  local player = g_game.getLocalPlayer()
  local position = deadCreature.position

  if player:canStandBy2(nil, position) then
    local tile = g_map.getTile(position)
    if tile then
      for k,v in pairs(tile:getItems()) do
      	if v:getId() == 1948 then -- it's stair
          looting.stop()
          return
        end
      end
      local topThing = tile:getTopThing()
      if topThing and topThing:isContainer() then
        deadCreature.corpse = topThing
      end
    end
  end

  if deadCreature.corpse then
    lootEvent = scheduleEvent(looting.lootProcess(deadCreature), 100)
  else
    if looting.stack:size() > 0 then
      looting.nextLoot(looting.stack:popFront())
    else

      removeEvent(lootEvent)
      if try > 0 then
        lootEvent = scheduleEvent(function()
        	try = try -1
        	looting.nextLoot(deadCreature, try)
        	end, 200)
      end
      looting.stop()
    end
  end
end

function looting.lootProcess(deadCreature, try)
  local try = try or 10
  local player = g_game.getLocalPlayer()
  local distance = player:getCreatureDistance(nil, deadCreature.position)

  if distance <= 1 and not looting.catching then
    g_game.open(deadCreature.corpse)
    looting.runCatch()
  else
    if player:canStandBy2(nil, deadCreature.position) and try > 0 then
      try = try - 1
      player:autoWalk(deadCreature.position)
      scheduleEvent(function() looting.lootProcess(deadCreature, try) end, 500)
    else
      looting.stop()
    end
  end
end

function looting.moveToBackpack(m_item, refuseContainerId)
  local backpacks = g_game.getContainers()
  for k,bp in pairs(backpacks) do
  	if bp:getId() ~= refuseContainerId then
  	  if bp:getSize() == 0 and bp:getCapacity() > 0 then
        local toPos = {y = 64 + bp:getId(), x = 65535, z = 0}
        g_game.move(m_item, toPos, m_item:getCount())
        break
  	  end
      if (bp:getCapacity() - bp:getSize() > 0) then
        for i=0, bp:getSize()-1 do
          local item = bp:getItem(i)
          if item and not item:isContainer() then
            local toPos = item:getPosition()
            g_game.move(m_item, toPos, m_item:getCount())
            break
          end
        end
      end
    end
  end
end

function looting.onContainerOpen(container, parentContainer)
  if table.size(looting.getLootList()) > 0 then
  	
    if container:getName():lower():match("dead") then
      creatureContainer = {
        id = container:getId(),
        name = container:getName(),
        container = container
      }
      
      scheduleEvent(looting.moveLoot(creatureContainer.container), g_game.getPing())

    elseif parentContainer and creatureContainer and creatureContainer.id == container:getId() then
        creatureContainer = {
          id = container:getId(),
          name = container:getName(),
          container = container
        }
        scheduleEvent(looting.moveLoot(creatureContainer.container), g_game.getPing())
    end
  end
end

function looting.moveLoot(container, try)
  
  local try = try or 20
  local nextCycle = false
  local nextBp = false
  if g_game.isOnline() and table.size(g_game.getContainers()) > 1 then
  	
    if container then
      local list = looting.getLootList()
      local items = container:getItems()
      for k,v in pairs(items) do
        if looting.lootFind(list, v:getId()) then
        	nextCycle = true
        	
        	looting.moveToBackpack(v, container:getId())
        	break
        else
          if v:isContainer() then
            g_game.open(v, v:getParentContainer())
            nextBp = true
            break
          end
        end
      end
    end
  end
  if (not nextCycle and not nextBp) or try <= 0 then
  	g_game.close(container)
    looting.catching = false
    creatureContainer = nil
    looting.stop()
  else
  	if try > 0 then
      scheduleEvent(function()
      	try = try - 1
      	looting.moveLoot(container, try) 
      end, 50)
    end
  end
end

function looting.getLootList()
  local list = {}
  for k,v in pairs(looting.catchItems:getChildren()) do
    local id = tonumber(v:getChildById('item'):getItemId())
    local name = v:getChildById('name'):getText()
    if id then
      table.insert(list, {id = id, name = name})
    end
  end
  return list
end

function looting.lootFind(list, id)
  local list = list or looting.getLootList()

  if table.size(list) == 0 then
    return false
  end

  for k,v in pairs(list) do
    if v.id == id then
      return true
    end
  end
  return false 
end
function looting.toggle()
  if looting.window then
    if looting.window:isVisible() then
      looting:hide()
    else
      looting.window:show()
      looting.window:focus(true)
      looting.itemText:focus(true)
    end
  end
end

function looting.lookArrayOfItems(str, limit)
  local ret = {}
  local limit = limit or 20
  if not str then
    return ret
  end
  if str == '' or str == " " then
    return ret
  end

  for k,v in pairs(arrayOfItems) do
    if v:lower():match(str:lower()) then
      table.insert(ret, {id = k, name = v})
    end
    if table.size(ret) > (limit - 1) then
    	break
    end
  end

  local tmp
  for i=1, #ret do
    for j=i+1, #ret do
      if ret[i] and ret[j] then
        if #ret[i].name > #ret[j].name then
          tmp = ret[i]
          ret[i] = ret[j]
          ret[j] = tmp
        end
      end
    end
  end

  return ret
end

function looting.searching(str, limit)
  looting.searchItems:destroyChildren()

  if radioItems[1] then
    radioItems[1]:destroy()
  end
  
  if not str then
  	return
  end
  if str == '' or str == ' ' then
  	return
  end
  radioItems[1] = UIRadioGroup.create()

  local items = looting.lookArrayOfItems(str, limit)
  for i=1, #items do
    local widget = g_ui.createWidget('LootWidget', looting.searchItems)
    widget:getChildById("item"):setItemId(items[i].id)
    widget:getChildById("name"):setText(items[i].name)
    radioItems[1]:addWidget(widget)
  end

end

function looting.addItemToList(id, name)
  if not radioItems[1] then
  	return
  end

  local selected = radioItems[1]:getSelectedWidget()
  
  if not selected then
  	return
  end

  local id = id or selected:getChildById('item'):getItemId()
  local name = name or selected:getChildById('name'):getText()

  if not name then
  	return
  end

  if name == '' then
  	return
  end

  radioItems[2] = radioItems[2] or UIRadioGroup.create()

  local widget = g_ui.createWidget('LootWidget', looting.catchItems)
  widget:getChildById("item"):setItemId(id)
  widget:getChildById("name"):setText(name)
  radioItems[2]:addWidget(widget)

  radioItems[2]:selectWidget(nil)

  radioItems[1]:selectWidget(nil)

end

function looting.removeItemFromList()
  if not radioItems[2] then
  	return
  end
  local selected = radioItems[2]:getSelectedWidget()
  if not selected then
  	return
  end
  local id = selected:getChildById('item'):getItemId()

  radioItems[2]:removeWidget(selected)
  radioItems[2]:selectWidget(nil)
  selected:destroy()

end
function looting.terminate()
  disconnect(Creature, {onDeath = looting.onTargetDeath})
  disconnect(Container, {onOpen = looting.onContainerOpen})
  arrayOfItems = nil
  looting.stack:clear()
  looting.window:destroy()
end