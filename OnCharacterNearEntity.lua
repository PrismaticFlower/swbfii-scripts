-- OnCharacterNearEntity by SleepKiller
--
-- This script contains a basic pseudo event for when a character is within a certain range of an entity. The event is implemented 
-- using timers and looping trrough a team's characters. With thanks to Marth8880 for his collection of SWBFII Lua documentation.
--
-- Feel free use this in your mod, modify it, etc. Just put my name in your credits :)

-- DOCUMENTATION --

-- Custom event triggered when a character is near the specified entity. This is implemented using a looping timer.
--
-- * `callback` Function to call when the event triggers. The callback will be passed the following arguments. 
--    - `entity` The entity pointer of the character that triggered the event.
--    - `distance` The distance of the character from the reference entity.
--    - `referenceEntity` Same as what was passed through for `referenceEntity` when registering the callback.
-- * `referenceEntity` The entity to check for characters being near. Should be an entity pointer or the name of an entity.
-- * `team` Index of the team whose characters will trigger the event. 
-- * `range` Distance within which to consider a character being "near". 
-- * `timerValue` Optional argument specifying how often the event will trigger in seconds. If ommitted defaults to `1`.
--
-- Returns a handle that can be passed to `ReleaseCharacterNearEntity` to free up resources associated with the event.
-- If the event will live the duration of the map you can throw the handle away and forget about it.
function OnCharacterNearEntity(callback, referenceEntity, team, range, timerValue) end

-- Same as `OnCharacterNearEntity` only uses pessimistic implemention that spreads the performance cost of the event 
-- out across multiple frames. As such the callback for some characters may be delayed but this version will scale to greater
-- character counts and has less chance of causing performance hitching overall. If you also plan to make a lot of these events
-- it may be better to use staggered events in that situation as well.
function OnCharacterNearEntityStaggered(callback, referenceEntity, team, range, timerValue) end

-- Destroys the event and frees it's associated resources.
--
-- * `handle` A handle returned by `OnCharacterNearEntity` or `OnCharacterNearEntityStaggered`.
function ReleaseCharacterNearEntity(handle) end

-- USAGE INSTRUCTIONS & EXAMPLE --
--[[

First put this file into "data_MOD/Common/scripts".

Then open up "data_MOD/Common/mission.req" and look for something that looks like this.

"
   REQN
   {
      "script"
"

Right under that add an entry for "OnCharacterNearEntity".

Then open up your mission script and at the top section where the calls to "ScriptCB_DoFile" are. Add one 
that to "OnCharacterNearEntity" like so "ScriptCB_DoFile("OnCharacterNearEntity")".


After that you can use it just like any other event. So as an example in "ScriptPostLoad" we could put the below for instance.

-- Event to kill any CIS unit that gets within 16 units of "cp1".
OnCharacterNearEntity(function (entity, distance, referenceEntity)
   KillObject(entity)
end, "cp1", CIS, 16)

]]--


-- DANGER ZONE (Implementation Begins Here) --

-- PRIVATE FUNCTIONS --
local Sqrt = math.sqrt
local Distance

-- PRIVATE VARIABLES --
local timerCount = 0

OnCharacterNearEntity = function(callback, referenceEntity, team, range, timerValue)
   -- Optional Arguments
   timerValue = timerValue or 1
   
   -- Error Checking
   assert(type(callback) == "function", "OnCharacterNearEntity - callback must be a function" )
   assert(type(referenceEntity) == "function" or type(referenceEntity) == "string", 
            "OnCharacterNearEntity - referenceEntity must be userdata (an entity pointer) or a string (name of an entity)" )
   assert(type(team) == "number", "OnCharacterNearEntity - team must be a number")
   assert(type(range) == "number", "OnCharacterNearEntity - range must be a number")
   assert(type(timerValue) == "number", "OnCharacterNearEntity - timerValue (when supplied) must be a number")
   
   assert(team >= 0, "OnCharacterNearEntity - team must be greater than or equal to 0")
   assert(range >= 1, "OnCharacterNearEntity - range must be greater than or equal to 1")
   assert(timerValue >= 0.95, "OnCharacterNearEntity - timerValue (when supplied) must be greater than or equal to 0.95")
   
   timerCount = timerCount + 1

   local timer = CreateTimer("CharacterNearEntityTimer" .. timerCount)
   SetTimerValue(timer, timerValue)
   StartTimer(timer)
   
   local timerEvent = OnTimerElapse(function ()
      SetTimerValue(timer, timerValue)
      StartTimer(timer)
      
      local refEntityX, refEntityY, refEntityZ = GetWorldPosition(referenceEntity)
      local teamSizeMinusOne = GetTeamSize(team) - 1
      
      for character = 0, teamSizeMinusOne do
         local characterUnit = GetCharacterUnit(GetTeamMember(team, character))
         
         if characterUnit ~= nil then
            local entity = GetEntityPtr(characterUnit)
            local entityX, entityY, entityZ = GetWorldPosition(entity)
      
            local distance = Distance(entityX, entityY, entityZ, refEntityX, refEntityY, refEntityZ)
   
            if distance <= range then
               callback(entity, distance, referenceEntity)
            end
         end
      end
   end, timer)

   local handle = {}
   
   handle.timer = timer
   handle.timerEvent = timerEvent
   
   return handle
end

OnCharacterNearEntityStaggered = function(callback, referenceEntity, team, range, timerValue)
   -- Optional Arguments
   timerValue = timerValue or 1
   
   -- Error Checking
   assert(type(callback) == "function", "OnCharacterNearEntity - callback must be a function" )
   assert(type(referenceEntity) == "function" or type(referenceEntity) == "string", 
            "OnCharacterNearEntity - referenceEntity must be userdata (an entity pointer) or a string (name of an entity)" )
   assert(type(team) == "number", "OnCharacterNearEntity - team must be a number")
   assert(type(range) == "number", "OnCharacterNearEntity - range must be a number")
   assert(type(timerValue) == "number", "OnCharacterNearEntity - timerValue (when supplied) must be a number")
   
   assert(team >= 0, "OnCharacterNearEntity - team must be greater than or equal to 0")
   assert(range >= 1, "OnCharacterNearEntity - range must be greater than or equal to 1")
   assert(timerValue >= 0.95, "OnCharacterNearEntity - timerValue (when supplied) must be greater than or equal to 0.95")
   
   timerCount = timerCount + 1

   local timer = CreateTimer("CharacterNearEntityTimer" .. timerCount)
   SetTimerValue(timer, timerValue)
   StartTimer(timer)
   
   local timerEvent = OnTimerElapse(function ()
      SetTimerValue(timer, timerValue)
      StartTimer(timer)

      local processTimer
      local processTimerEvent
      
      local currentCharacter = 0
      local refEntityX, refEntityY, refEntityZ = GetWorldPosition(referenceEntity)
      local teamSize = GetTeamSize(team)
         
      timerCount = timerCount + 1
   
      processTimer = CreateTimer("CharacterNearEntityTimer" .. timerCount)
      processTimerEvent = OnTimerElapse(function ()   
         local characterUnit = GetCharacterUnit(GetTeamMember(team, currentCharacter))
            
         if characterUnit ~= nil then
            local entity = GetEntityPtr(characterUnit)
            local entityX, entityY, entityZ = GetWorldPosition(entity)
         
            local distance = Distance(entityX, entityY, entityZ, refEntityX, refEntityY, refEntityZ)

            if distance <= range then
               callback(entity, distance, referenceEntity)
            end
         end

         currentCharacter = currentCharacter + 1

         if currentCharacter < teamSize then
            SetTimerValue(processTimer, 0.000001)
            StartTimer(processTimer)
         else
            ReleaseTimerElapse(processTimerEvent)
            DestroyTimer(processTimer)
         end
      end, processTimer)
      
      SetTimerValue(processTimer, 0.000001)
      StartTimer(processTimer)
   end, timer)

   local handle = {}
   
   handle.timer = timer
   handle.timerEvent = timerEvent
   
   return handle
end

ReleaseCharacterNearEntity = function(handle)
   assert(type(handle) == "table", "Invalid OnCharacterNearEntity handle.")
   assert(type(handle.timer) == "userdata", "Invalid OnCharacterNearEntity handle.")
   assert(type(handle.timerEvent) == "userdata", "Invalid OnCharacterNearEntity handle.")

   ReleaseTimerElapse(handle.timerEvent)
   DestroyTimer(handle.timer)
end

Distance = function(aX, aY, aZ, bX, bY, bZ)
   local x = aX - bX
   local y = aY - bY
   local z = aZ - bZ

   return Sqrt(x * x + y * y + z * z)
end