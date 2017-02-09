Stack = {}
Stack.__index = Stack

function Stack.create() -- constructor returns the stack class
  local ret = {}
  setmetatable(ret, Stack)
  ret.stack = {}
  return ret
end

function Stack:push(value) -- push value to top of stack
  table.insert(self.stack, value)
end

function Stack:pop() -- pull value from top of stack
  if #self.stack == 0 then
    return nil
  elseif #self.stack > 0 then
    local ret = self.stack[#self.stack]
    self.stack[#self.stack] = nil
    return ret
  end
end

function Stack:popFront() -- pull value from front of stack
  if #self.stack == 0 then
    return nil
  elseif #self.stack == 1 then
    local ret = self.stack[1]
    self.stack[1] = nil
    return ret
  elseif #self.stack > 1 then
    local ret = self.stack[1]
    for i=1, #self.stack do
      if i == #self.stack then
        self.stack[i] = nil
        break
      end
      self.stack[i] = self.stack[i+1]
    end
    return ret
  end
end

function Stack:pushFront(value) -- push value to front of stack
  local newStack = {}
  table.insert(newStack, value)

  for i=1, #self.stack do
    table.insert(newStack, self.stack[i])
  end
  self.stack = newStack
end

function Stack:size() -- returns size of stack
  return #self.stack
end

function Stack:clear() -- clear the stack
  table.clear(self.stack)
end

function Stack:last() -- returns the top of stack without pull the value
  return self.stack[#self.stack]
end

function Stack:first() -- returns the front of stack without pull the value
  return self.stack[i]
end
function Stack:get() -- returns the stack table
  return self.stack
end