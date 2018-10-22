-- AddRandomClasses by SleepKiller
--
-- Adds random classes to the specified team, optionally loading the required lvls for them.
-- * `teamIndex` The index of the team to add the classes for. 
-- * `numberToPick` The number of classes to randomly pick and add.
-- * `possibleClasses` Table forming a list of classes to select from.
--    - `className` The classname of the unit. This should be the same as what you would pass to `AddUnitClass` or `SetupTeams`.
--    - `minUnits` The minimum number of AI for the unit. This should be the same as what you would pass to `AddUnitClass` or `SetupTeams`.
--    - `maxUnits` The maximum number of AI for the unit, or if it is an unlock class the maximum number of units overall. This should be 
--                       the same as what you would pass to `ReadDataFile` if you were only loading up a single (or no) child lvl. So
--                       "dc:SIDE\\test.lvl" or "dc:SIDE\\test.lvl;test_inf_engineer". The function will combine loading child lvls from the same
--                       lvl into the same `ReadDataFile` call and it will only load what classes are needed.
function AddRandomClasses(teamIndex, numberToPick, possibleClasses) end

-- Examples --

--[[
-- Randomly select between `rep_inf_ep3_rifleman` and `rep_inf_ep3_engineer`. In this case both classes will have been loaded from
-- their lvl before calling the function. This is what you would do for a map you wanted to work in multiplayer.
AddRandomClasses(REP, 1, {{className = "rep_inf_ep3_rifleman",  minUnits = 8, maxUnits = 32},
                                      {className = "rep_inf_ep3_engineer", minUnits = 8, maxUnits = 32})

-- Randomly select between `all_inf_rifleman` variations. In this case `AddRandomClasses` will handle loading the lvls for us and
-- as a result this won't work in multiplayer.
AddRandomClasses(ALL, 1, {{className = "all_inf_rifleman",  minUnits = 8, maxUnits = 32, lvlName = "SIDE\\alll.lvl;all_inf_rifleman"},
                                      {className = "all_inf_rifleman_desert", minUnits = 8, maxUnits = 32, lvlName = "SIDE\\alll.lvl;all_inf_rifleman_desert"},
                                      {className = "all_inf_rifleman_fleet", minUnits = 8, maxUnits = 32, lvlName = "SIDE\\alll.lvl;all_inf_rifleman_fleet"},
                                      {className = "all_inf_rifleman_jungle", minUnits = 8, maxUnits = 32, lvlName = "SIDE\\alll.lvl;all_inf_rifleman_jungle"},
                                      {className = "all_inf_rifleman_snow", minUnits = 8, maxUnits = 32, lvlName = "SIDE\\alll.lvl;all_inf_rifleman_snow"},
                                      {className = "all_inf_rifleman_urban", minUnits = 8, maxUnits = 32, lvlName = "SIDE\\alll.lvl;all_inf_rifleman_urban"})
                                   
-- Randomly select between each stock side's basic rifleman. In this case `AddRandomClasses` will handle loading for only two of the lvls for us and 
-- only when needed. Once again this won't work in multiplayer.
AddRandomClasses(CIS, 1, {{className = "rep_inf_ep3_rifleman",  minUnits = 8, maxUnits = 32,
                                      {className = "cis_inf_rifleman", minUnits = 8, maxUnits = 32,
                                      {className = "all_inf_rifleman", minUnits = 8, maxUnits = 32, lvlName = "SIDE\\alll.lvl;all_inf_rifleman"},
                                      {className = "imp_inf_rifleman", minUnits = 8, maxUnits = 32, lvlName = "SIDE\\imp.lvl;imp_inf_rifleman"})
]]--

-- Implementation Begins Here --

-- Forward declarations for our private helper functions.
local VerifyClassTableEntry
local AddPickedClassesToGame
local LoadPickedClassesLvls
local FindStringInList

AddRandomClasses = function(teamIndex, numberToPick, possibleClasses)
   assert(type(teamIndex) == "number", "AddRandomClasses - teamIndex must be a number.")
   assert(type(numberToPick) == "number", "AddRandomClasses - numberToPick must be a number.")
   assert(type(possibleClasses) == "table", "AddRandomClasses - possibleClasses must be a table.")
   
   assert(teamIndex > 0, "AddRandomClasses - teamIndex must be greater than zero.")
   assert(numberToPick > 0, "AddRandomClasses - numberToPick must be greater than zero.")
   assert(numberToPick >= possibleClasses:getn(), "AddRandomClasses - numberToPick must be less than or equal to the possible number of classes.")

   local pickedClasses = {}
   
   -- Perform a for loop to add each of our classes. This will count from the starting value of `i` and end on the value of `numberOfClasses`.
   for i = 1, numberToPick do
      -- When called like this with one argument `math.random` will return a number in the range 1 to `table.getn(possibleClasses)`.
      -- This is our random class to use.
      local classIndex = math.random(table.getn(possibleClasses))
      
      -- Verify the table entry containing the info on our unit class.
      VerifyClassTableEntry(possibleClasses[classIndex])
      
      -- Add to the table of picked classes.
      table.insert(pickedClasses, possibleClasses[classIndex])
      
      -- Remove the picked class from `possibleClasses`.
      table.remove(possibleClasses, classIndex)
   end
   
   AddPickedClassesToGame(teamIndex, pickedClasses)
end

-- Private cache for lvl's we've called ReadDataFile on
local loadedLvls = {}

VerifyClassTableEntry = function(tableEntry)
   assert(type(tableEntry.className) == "string", "AddRandomClasses - table entry className must be a string.")
   assert(type(tableEntry.minUnits) == "number", "AddRandomClasses - table entry minUnits must be a number.")
   assert(type(tableEntry.maxUnits) == "number", "AddRandomClasses - table entry maxUnits must be a number.")

   if (tableEntry.lvlName) then
      assert(type(tableEntry.lvlName) == "string", "AddRandomClasses - table entry lvlName (if present) must be a string.")
   end
end

AddPickedClassesToGame = function(pickedClasses)
   LoadPickedClassesLvls(pickedClasses)
   
   -- Add each class.
   for index, classEntry in ipairs(pickedClasses) do
      AddUnitClass(teamIndex, classEntry.className, className.minUnits, className.maxAi)
   end
end

LoadPickedClassesLvls = function(pickedClasses)
   local neededLvls = {}
   
   -- Build up a list of all needed lvls and needed children in them.
   for index, entry in ipairs(pickedClasses) do 
      if (entry.lvlName) then 
         -- Decompose the name of the lvl. 
         local matchStart, matchEnd, lvlPath, childName = string.find(entry.lvlName, "(.+);?(.*)")
         
         -- Add `lvlPath` to the list of lvls to load, if needed.
         if (not neededLvls[lvlPath]) then 
            neededLvls[lvlPath] = {} 
         end
         
         -- Add `childName` to the list of children to load, if needed.
         if (childName and not FindStringInList(neededLvls[lvlPath], childName)) then 
            table.insert(neededLvls[lvlPath], childName) = true 
         end
      end
   end
   
   -- Call ReadDataFile for each entry in `neededLvls`.
   for index, entry in ipairs(neededLvls) do 
      ReadDataFile(index, unpack(entry))
   end
end

FindStringInList = function(value, list)
   for listIndex, listValue in ipairs(list) do 
      if (value == listValue) then 
         return true
      end
   end
   
   return false
end
