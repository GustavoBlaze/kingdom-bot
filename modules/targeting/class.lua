Target = {}
Target.__index = Target

function Target.create(name, min, max, movement, danger, attack, spell, follow, loot) -- Constructor
    local ret = {}
    setmetatable(ret, Target)
    ret.name = name
    ret.min = min
    ret.max = max
    ret.movement = movement
    ret.danger = danger
    ret.attack = attack
    ret.spell = spell
    ret.follow = follow
    ret.loot = loot
    return ret
end

function Target:setId(id)
	self.id = id
end


TCreature = {}
TCreature.__index = TCreature

function TCreature.create(creature, danger)
	local ret = {}
	setmetatable(ret, TCreature)
	ret.creature = creature
	ret.danger = tonumber(danger)

	return ret
end

-- Creature Extensions imported from candybot
function Creature:getTargetsInArea(targetList, pathableOnly)
    local targets = {}
    if g_game.isOnline() then
        creatures = g_map.getSpectators(self:getPosition(), false)
        for i, creature in ipairs(creatures) do
            if creature:isMonster() then
                if table.contains(targetList, creature:getName():lower(), true) then
                    if not pathableOnly or creature:canStandBy(self) then
                        table.insert(targets, creature)
                    end
                end
            end
        end
    end
    return targets
end

function Creature:canStandBy(creature)
    if not creature then
        return false
    end
    local myPos = self:getPosition()
    local otherPos = creature:getPosition()

    local neighbours = {
        {x = 0, y = -1, z = 0},
        {x = -1, y = -1, z = 0},
        {x = -1, y = 0, z = 0},
        {x = -1, y = 1, z = 0},
        {x = 0, y = 1, z = 0},
        {x = 1, y = 1, z = 0},
        {x = 1, y = 0, z = 0},
        {x = 1, y = -1, z = 0}
    }

    for k,v in pairs(neighbours) do
        local checkPos = {x = myPos.x + v.x, y = myPos.y + v.y, z = myPos.z + v.z}
        if postostring(otherPos) == postostring(checkPos) then
            return true
        end

        -- Check if there is a path
        local steps, result = g_map.findPath(otherPos, checkPos, 40000, 0)
        if result == PathFindResults.Ok then
                return true
        end
    end
    return false
end

local function getDistanceBetween(p1, p2)
    return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

function Creature:getCreatureDistance(creature)
	if not creature then
		return 1000
	end

	local p1 = self:getPosition()
	local p2 = creature:getPosition()
    
    if not p2 then
    	return 1000
    end

    if p1.z ~= p2.z then
    	return 1000
    end

    return getDistanceBetween(p1, p2)
end

function filterPaths(paths)
	local temp
    for i=1, #paths do
       for j=i+1, #paths do
          if #paths[i] > #paths[j] then
              temp = paths[i]
              paths[i]=paths[j]
              paths[j]=temp
          end
       end
    end
    return paths
end



function Creature:getDiagonals(creature)
	local diagonals = {}
    
    if not creature then
    	return diagonals, false
    end

    local myPos = self:getPosition()
    local otherPos = creature:getPosition()

    local neighbours = {
        {x = -1, y = -1, z = 0},
        {x = 1, y = -1, z = 0},
        {x = -1, y = 1, z = 0},
        {x = 1, y = 1, z = 0}
    }

   
    for k,v in pairs(neighbours) do
        local checkPos = {x = (otherPos.x + v.x), y = (otherPos.y + v.y), z = (otherPos.z + v.z)}

        if postostring(myPos) == postostring(checkPos) then
        	local arr = {}
            return arr, true
        end

        -- Check if there is a path
        local steps, result = g_map.findPath(myPos, checkPos, 40000, 0)
        if result == PathFindResults.Ok then
            table.insert(diagonals, steps)
        end
    end

    if #diagonals == 0 then
        return diagonals, false
    else
        return filterPaths(diagonals), true
    end
end