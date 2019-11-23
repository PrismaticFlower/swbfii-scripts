
-- UnitClassRandomizer by SleepKiller
--
-- Enables randomizing unit class's properties. Each time a character spawns in as a randomized class
-- a new set of randomized properties will be chosen.
--
-- DOCUMENTATION --

-- Enables randomization of a class.
--
-- * `randomizedClassName` A string specifying the class name to randomize. I.e "rep_inf_ep3_engineer"
-- * `randomPropertiesList` An of array of tables containing the properties sets to pick from when 
--                          randomizing the class. Each time the class is randomized a property set
--                          will be chosen at random and then applied using SetClassProperty.
function RandomizeUnitClass(randomizedClassName, randomPropertiesList) end

-- USAGE INSTRUCTIONS & EXAMPLE --

--[[
Put this script into your Common\scripts folder. And then in your mission.req under it's "script" 
section add "UnitClassRandomizer".

Then at the top of your mission script just under "ScriptCB_DoFile("setup_teams")" add 
"ScriptCB_DoFile("UnitClassRandomizer")".

You can then use the script by calling "RandomizeUnitClass" from "ScriptPostLoad".

For instance to randomize "rep_inf_ep3_engineer" each time a unit spawned you would put the following
inside of your "ScriptPostLoad". All needed models, textures, etc must be **loaded** beforehand.
```
    RandomizeUnitClass("rep_inf_ep3_engineer", {
        -- Each entry here represents a set of properties. Whenever the class is randomized 
        -- a set of properties will be picked at random.
        {
            -- These are just listings of class properties. So provided you use quotes
            -- and remember the ',' at the end you can put anything that you can put 
            -- in an .odf file here.
            GeometryName = "rep_inf_ep3sniper",
            GeometryLowRes = "rep_inf_ep3sniper_low1",
            ClothODF = "rep_inf_ep3sniper_cape",
            FirstPerson = "REP\\reptroop;rep_1st_trooper",
        }, 
        {
            GeometryName = "rep_inf_ep3armoredpilot",
            GeometryLowRes = "rep_inf_ep3armoredpilot_low1",
            FirstPerson = "REP\\reptroop;rep_1st_trooper",
        },
        {
            GeometryName = "rep_inf_clonecommander",
            GeometryLowRes = "rep_inf_clonecommander_low1",
            FirstPerson = "REP\\repcomm;rep_1st_clonecommander",
            ClothODF = "rep_inf_clonecommander_cape",
        },
        {
            GeometryName = "rep_inf_ep3trooper",
            GeometryLowRes = "rep_inf_ep3trooper_low1",
            FirstPerson = "REP\\repcomm;rep_1st_clonecommander",
        },
    })
```

]]--

-- DANGER ZONE (Implementation Begins Here) --

local randomizedClasses = {}
local onCharacterSpawnHandle = nil

function RandomizeUnitClass(randomizedClassName, randomPropertiesList)
    print(string.format("RandomizeUnitClass - Randomizing Class %s", randomizedClassName))

    randomizedClasses[randomizedClassName] = randomPropertiesList

    if onCharacterSpawnHandle then
        return
    end

    onCharacterSpawnHandle = OnCharacterSpawn(function(player)
            local playerClass = GetEntityClass(GetCharacterUnit(player))

            for className, propertiesList in pairs(randomizedClasses) do
                if playerClass == FindEntityClass(randomizedClassName) then
                    local properties = propertiesList[math.random(table.getn(propertiesList))]

                    for k, v in pairs(properties) do
                        SetClassProperty(randomizedClassName, k, v)
                    end

                    break
                end
            end
        end)
end
