-- TrackFunctionCalls by SleepKiller
--
-- Enables tracking calls to a function. Prints the functions arguments, 
-- return values and callsite (if debug symbols are available).
--
--
-- DOCUMENTATION --

-- Enables tracking a global function. The function will remain tracked until the Lua state is reset.
--
-- * `name` A string specifying the name of the global variable whose function to track.
function TrackFunctionCalls(name) end

-- USAGE INSTRUCTIONS & EXAMPLE --
--[[

Put this script into the scripts folder for the .lvl your munging and add a reference to it
in the .lvl's .req file like any other script.

Then load it using ScriptCB_DoFile like any other script "ScriptCB_DoFile("TrackFunctionCalls")". 

Using it is then as simple as below.

-- 
TrackFunctionCalls("ReadDataFile")

--

Messages will be of the below form in bfront2.log

Message Severity: 0
.\scripts\TSTc_con.lua(40)
TrackedFunc called
  args:
    "arg1"
    500.0
    {
      key = "Value",
      nestedTable = {
        life = 42,
      },
    }

  ret:
    false,
    "Cake"
]]--

-- DANGER ZONE (Implementation Begins Here) --

local printEx

TrackFunctionCalls = function (name)
   if type(_G[name]) ~= "function" then
      error(string.format("Supplied name %q is not a global function!", name))
   end

   local trueFunc = _G[name]

   -- Hook the function.
   _G[name] = function (...)
      local info = debug.getinfo(2)
   
      print("Message Severity: 0")
      
      if info then
         print(string.format("%s(%i)", info.short_src, info.currentline))
      else     
         print("Unknown Callsite")
      end
       
      print(name .. " called")
      
      if arg.n > 0 then
         print("  args:")
   
         for i,v in ipairs(arg) do      
            printEx(v, 2)      
         end
      end

      local results = {trueFunc(unpack(arg))}
      
      if table.getn(results) > 0 then
         print("  results:")
         
         for i,v in ipairs(results) do      
            printEx(v, 2)      
         end
      end
      
      print("")
      
      return unpack(results)
   end
end

printEx = function(value, level)
   level = level or 0
   local indention = string.rep("  ", level)
   
   if type(value) == "table" then
      print(indention .. "{")
      
      for k,v in pairs(value) do
         if type(v) == "string" then
            print("  " .. indention .. k .. " = " .. string.format("%q", v) .. ",")
         elseif type(v) == "table" then
            print("  " .. indention .. k .. " = ")
            printEx(v, level + 1)
         elseif type(v) == "function" then
            print("  " .. indention .. k .. " = LUA_FUNCTION,")
         elseif type(v) == "thread" then
            print("  " .. indention .. k .. " = LUA_THREAD,")
         elseif type(v) == "userdata" then
            print("  " .. indention .. k .. " = LUA_USERDATA,")
         elseif type(v) == "nil" then
            print("  " .. indention .. k .. " = nil,")
         else
            print("  " .. indention .. k .. " = " .. tostring(v) .. ",")
         end
      end
 
      print(indention .. "}")
   elseif type(value) == "string" then
      print(indention .. string.format("%q", value))
   elseif type(value) == "function" then
      print(indention .. "LUA_FUNCTION")
   elseif type(value) == "thread" then
      print(indention .. "LUA_THREAD")
   elseif type(value) == "userdata" then
      print(indention .. "LUA_USERDATA")
   elseif type(value) == "nil" then
      print(indention .. "nil")
   else
      print(indention .. tostring(value))
   end 
end
