-- Singleton Class
-- Source: https://github.com/floydawong/lua-patterns/blob/master/singleton.lua
-- implementa un pattern di progettazione Singleton per creare una classe 
-- con un'unica istanza disponibile in un'intera applicazione. 
-- La classe singleton eredita dalla classe padre super se viene specificata,
-- il costruttore constructor può essere definito per inizializzare l'istanza della classe singleton.

local function ClassSingleton(super)
    local obj = {}
    obj.__index = obj
    setmetatable(obj, super)
  
    function obj.new(...)
      if obj._instance then
        return obj._instance
      end
  
      local instance = setmetatable({}, obj)
      if instance.constructor then
        instance:constructor(...)
      end
  
      obj._instance = instance
      return obj._instance
    end
  
    return obj
  end
  
return ClassSingleton

