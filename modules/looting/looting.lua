looting = {}
dofile("extension.lua")


local function windowChild(id)
  return looting.window:getChildById(id)
end

looting.running = false

function looting.isRunning()
  return looting.running
end

function looting.init()
  looting.running = false
  looting.window = g_ui.displayUI("looting.otui")
  looting.window:hide()

  looting.list = windowChild('itemList')
  looting.itemText = windowChild('itemText')

  looting.stack = Stack.create()

  connect(Creature, {onDeath = looting.onTargetDeath})
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

function looting.onTargetDeath(creature)
  if not creature then
    return
  end

  if not creature:isMonster() then
    return
  end

  if not modules.kingdom_bot.targeting.canLoot(creature) then
    return
  end

  local creatureId = creature:getId()
  local creaturePos = creature:getPosition()

  local deadCreature = {
    id = creatureId,
    position = creaturePos,
    corpse = nil
  }

  local tile = g_map.getTile(creaturePos)
  if tile then
    local topThing = tile:getTopThing()
    if topThing and topThing:isContainer() then
       local lastTarget = modules.kingdom_bot.targeting.getLastTargetId()
      deadCreature.corpse = topThing
    end
  end

  local lastTarget = modules.kingdom_bot.targeting.getLastTargetId()
  if lastTarget and lastTarget == creatureId then
    looting.stack:pushFront(deadCreature)
  else
    looting.stack:push(deadCreature)
  end
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

function looting.terminate()
  disconnect(Creature, {onDeath = looting.onTargetDeath})

  looting.stack:clear()
  looting.window:destroy()
end
