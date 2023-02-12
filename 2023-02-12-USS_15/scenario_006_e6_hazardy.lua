-- Name: Etapa 6 - Sběr dat
-- Description: hráči - 6 jednomístných lodí, létají kolem a sbírají datapody. 
--- Datapody (zelené tečky) je třeba najít a přivézt k Polaris (do dosahu dálkového radaru). 
---  
--- VYPNOUT BEAM/SHIELD FREQUENCIES!
-- Type: Hvězdná Loď

--- Scenario
-- @script scenario_006_e6_hazardy

require("lod-2023-02_common_functions.lua")
require("utils_customElements.lua")
require("utils.lua")

use_control_codes = true
polaris_pwd = "EQUADOR"
PLAYER_SHIELDS_ON_SPAWN = true

SIZE_COEFFICIENT=3.5

SHIP_DATA={
    {callsign="Alpha",   instance=nil},
    {callsign="Bravo",   instance=nil},
    {callsign="Charlie", instance=nil}, 
    {callsign="Delta",   instance=nil}, 
    {callsign="Echo",    instance=nil}, 
    {callsign="Foxtrot", instance=nil}, 
}

SHIP_DATA_LOCAL={
    {x=-89000/SIZE_COEFFICIENT, y=-11250/SIZE_COEFFICIENT},
    {x=-89000/SIZE_COEFFICIENT, y=-10750/SIZE_COEFFICIENT},
    {x=-89000/SIZE_COEFFICIENT, y=-10250/SIZE_COEFFICIENT},
    {x=-89000/SIZE_COEFFICIENT, y=-9750/SIZE_COEFFICIENT},
    {x=-89000/SIZE_COEFFICIENT, y=-9250/SIZE_COEFFICIENT},
    {x=-89000/SIZE_COEFFICIENT, y=-8750/SIZE_COEFFICIENT}
}

POLARIS_COORDS={x=-90000/SIZE_COEFFICIENT, y=-10000/SIZE_COEFFICIENT}

POD_COLOR = {r=0, g=255, b=0}

SPAWN_MULTIPLE_HAZARDS = false

datapods_picked = 0
datapods_delivered = 0

-- Spawns player shuttle (number can be up to the SHIP_DATA length)
function spawn_player(number)
    if SHIP_DATA[number].instance == nil then 
        local player = PlayerSpaceship():setFaction("Federation"):setTemplate("MP52 Hornet")
        hemmonds_toolkit_small_player_ship_setup(player)
        player:setCanScan(false)
        
        player:setShortRangeRadarRange(4000):setLongRangeRadarRange(4000)
        player:commandAddWaypoint(POLARIS_COORDS.x, POLARIS_COORDS.y)
        
        player:setCallSign(SHIP_DATA[number].callsign)
        player:setPosition(SHIP_DATA_LOCAL[number].x, SHIP_DATA_LOCAL[number].y)
        
        player:setImpulseMaxSpeed(200)
        player:setHullMax(1):setHull(1):setShieldsMax(50.00):setShields(50.00)
        
        player:commandSetShields(PLAYER_SHIELDS_ON_SPAWN)

        
        player:onDestroyed(function() 
            math.abs(0) 
            addGMMessage("SHIP "..SHIP_DATA[number].callsign.." DESTROYED\n\nDatapods lost: "..SHIP_DATA[number].instance._datapods)
            SHIP_DATA[number].instance=nil 
        end)
        SHIP_DATA[number].instance=player
        
        player._datapods = 0
    end
end

function init_base()
    polaris = immovableObjects:spawn(function() 
        polaris = PlayerSpaceship():setTemplate("Atlantis"):setFaction("Federation"):setCallSign("USS Polaris"):setPosition(POLARIS_COORDS.x, POLARIS_COORDS.y):setCanBeDestroyed(false):setCanScan(false):setLongRangeRadarRange(10000/SIZE_COEFFICIENT)
        if use_control_codes then polaris:setControlCode(polaris_pwd) end
        return polaris
     end)
    
    spawn_player(1)
    spawn_player(2)
    spawn_player(3)
    spawn_player(4)
    spawn_player(5)
    spawn_player(6)
end

function spawn_datapod(x, y)
    local pod = Artifact():setModel("artifact3"):setPosition(x, y)
    pod:setRadarTraceColor(0, 255, 0):setRadarTraceScale(0.7)
    
    pod:allowPickup(true):onPickUp(function(artifact, player) 
        math.abs(0)
        player._datapods = player._datapods+1
        datapods_picked = datapods_picked+1
    end)
end

function spawn_mine(x, y)
    local mine = Mine():setPosition(x, y):onDestruction(function()
        math.abs(0)
        scheduler_add_job(15, function() spawn_mine(x, y) end)
    end)
end

-- Spawns stationary (but movable) enemy on coordinates x, y. Diff can be: "easy"/"medium"/"hard"/"torpedo"
function spawn_enemy(x, y, diff)
    local diff_data = {}
    diff_data["easy"] = {t="Adder MK3", dmg=13}
    diff_data["medium"] = {t="Phobos T3", dmg=27}
    diff_data["hard"] = {t="Weapons platform", dmg=60}
    diff_data["torpedo"] = {t="Piranha F12", dmg=0}    -- Pouze 50x homing, ale dat torp.reload. 
    
    -- Instances stored here for future reference (aka missile reloading)
    enemies = {}
    enemies["easy"] = {}
    enemies["medium"] = {}
    enemies["hard"] = {}
    enemies["torpedo"] = {}
    
    local enemy = CpuShip():setTemplate(diff_data[diff].t):setFaction("Environment"):setCallSign(""):setPosition(x, y):orderRoaming():setCanBeDestroyed(false):setWarpDrive(false):setJumpDrive(false)
    enemy:setImpulseMaxSpeed(0)
    
    --TODO rozhodnout jak moc hraci uvidi. 
    enemy:setScanState("friendorfoeidentified")
    --enemy:setScanState("simplescan")
    --enemy:setScanState("fullscan")
    
    if diff == "torpedo" then 
        enemy:setWeaponStorageMax("Homing", 50):setWeaponStorage("Homing", 50):setWeaponStorage("HVLI", 0):setWeaponStorageMax("HVLI", 0)
        
        for i,j in ipairs({0,1,2,3,4,5}) do
            enemy:setWeaponTubeExclusiveFor(j, "Homing"):setTubeLoadTime(j, 10):setTubeSize(j, "medium")
        end

    else
        for i, txt in ipairs({"Homing", "Nuke", "Mine", "EMP", "HVLI"}) do
            enemy:setWeaponStorage(txt, 0):setWeaponStorageMax(txt, 0)
        end
                        -- id arc dir  rng   cyc  dps
        enemy:setBeamWeapon(1, 90,   0, 2500, 6.0, diff_data[diff].dmg)
        enemy:setBeamWeapon(0, 90, -90, 2500, 6.0, diff_data[diff].dmg)
        enemy:setBeamWeapon(2, 90,  90, 2500, 6.0, diff_data[diff].dmg)
        enemy:setBeamWeapon(3, 90, 180, 2500, 6.0, diff_data[diff].dmg)
        
        enemy:setBeamWeapon(4, 0, 0, 0, 0, 0)
        enemy:setBeamWeapon(5, 0, 0, 0, 0, 0)
    end
    
--    immovableObjects:add(enemy)
    table.insert(enemies[diff], enemy)
    --:
end

function spawn_mine_resized(x, y) 
    spawn_mine(x/SIZE_COEFFICIENT, y/SIZE_COEFFICIENT)
end

function init_hostile_map()
    -- Four corners of hostile area
    --[[ Mine():setPosition(20000, 40000)
    Mine():setPosition(-80000, 40000)
    Mine():setPosition(-80000, -60000)
    Mine():setPosition(20000, -60000) --]]

    local asteroids = {}
    table.insert(asteroids, {-18030, -43449, 113})
    table.insert(asteroids, {-18030, -43449, 113})
    table.insert(asteroids, {-19447, -50250, 125})
    table.insert(asteroids, {-17605, -55209, 125})
    table.insert(asteroids, {-23981, -54359, 115})
    table.insert(asteroids, {-23698, -43590, 114})
    table.insert(asteroids, {-21431, -39056, 123})
    table.insert(asteroids, {-17747, -30130, 124})
    table.insert(asteroids, {-16188, -26587, 128})
    table.insert(asteroids, {-22423, -32397, 127})
    table.insert(asteroids, {-25682, -28996, 127})
    table.insert(asteroids, {-26390, -40898, 124})
    table.insert(asteroids, {-10662, -52942, 117})
    table.insert(asteroids, {-8679, -56201, 115})
    table.insert(asteroids, {-13638, -47699, 125})
    table.insert(asteroids, {-11937, -42882, 129})
    table.insert(asteroids, {-6553, -47841, 122})
    table.insert(asteroids, {-10379, -38631, 113})
    table.insert(asteroids, {-12504, -36081, 123})
    table.insert(asteroids, {-6978, -36647, 116})
    table.insert(asteroids, {-6837, -35939, 129})
    table.insert(asteroids, {-9245, -35372, 112})
    table.insert(asteroids, {-4003, -42740, 115})
    table.insert(asteroids, {-2869, -50250, 117})
    table.insert(asteroids, {-4003, -55492, 122})
    table.insert(asteroids, {7049, -43732, 121})
    table.insert(asteroids, {5632, -39623, 122})
    table.insert(asteroids, {2373, -55492, 124})
    table.insert(asteroids, {2373, -46707, 130})
    table.insert(asteroids, {3224, -29279, 114})
    table.insert(asteroids, {-3578, -30980, 129})
    table.insert(asteroids, {-744, -28571, 124})
    table.insert(asteroids, {3790, -39765, 114})
    table.insert(asteroids, {-602, -35656, 118})
    table.insert(asteroids, {9316, -47558, 129})
    table.insert(asteroids, {8750, -53792, 115})
    table.insert(asteroids, {9316, -40331, 127})
    table.insert(asteroids, {11017, -40190, 117})
    table.insert(asteroids, {-1452, -39765, 112})
    table.insert(asteroids, {-43251, -37639, 114})
    table.insert(asteroids, {-48352, -39056, 118})
    table.insert(asteroids, {-49911, -43307, 123})
    table.insert(asteroids, {-43393, -45716, 123})
    table.insert(asteroids, {-47502, -47416, 128})
    table.insert(asteroids, {-48777, -31830, 125})
    table.insert(asteroids, {-43110, -32397, 123})
    table.insert(asteroids, {-33616, -38489, 117})
    table.insert(asteroids, {-34750, -42740, 120})
    table.insert(asteroids, {-32341, -44015, 119})
    table.insert(asteroids, {-36308, -32680, 120})
    table.insert(asteroids, {-41551, -35797, 130})
    table.insert(asteroids, {-61104, -31263, 126})
    table.insert(asteroids, {-55012, -30838, 113})
    table.insert(asteroids, {-66205, -44299, 114})
    table.insert(asteroids, {-63938, -36222, 117})
    table.insert(asteroids, {-68047, -35656, 129})
    table.insert(asteroids, {-57846, -41607, 125})
    table.insert(asteroids, {-56570, -44865, 120})
    table.insert(asteroids, {-56429, -50250, 121})
    table.insert(asteroids, {-63230, -53792, 123})
    table.insert(asteroids, {-28657, -52233, 128})
    table.insert(asteroids, {-29932, -52375, 126})
    table.insert(asteroids, {-29365, -37356, 124})
    table.insert(asteroids, {-27949, -45716, 111})
    table.insert(asteroids, {-45377, -52659, 114})
    table.insert(asteroids, {-43818, -52517, 126})
    table.insert(asteroids, {-37017, -52942, 125})
    table.insert(asteroids, {9883, -18227, 111})
    table.insert(asteroids, {12717, -15535, 112})
    table.insert(asteroids, {9458, -11993, 130})
    table.insert(asteroids, {-16330, -13127, 128})
    table.insert(asteroids, {-18880, -8167, 126})
    table.insert(asteroids, {-18739, -22053, 115})
    table.insert(asteroids, {-10804, -22620, 122})
    table.insert(asteroids, {-9670, -11143, 113})
    table.insert(asteroids, {-9670, -11851, 115})
    table.insert(asteroids, {-32766, -24037, 120})
    table.insert(asteroids, {-38434, -24179, 117})
    table.insert(asteroids, {-29082, -24604, 117})
    table.insert(asteroids, {-31349, -6609, 118})
    table.insert(asteroids, {-50478, -25737, 112})
    table.insert(asteroids, {-56570, -21628, 124})
    table.insert(asteroids, {-45093, -23895, 115})
    table.insert(asteroids, {-48919, -23187, 117})
    table.insert(asteroids, {-39001, -16385, 129})
    table.insert(asteroids, {-34325, -17236, 116})
    table.insert(asteroids, {-52320, -18794, 127})
    table.insert(asteroids, {-45802, -19361, 123})
    table.insert(asteroids, {-4569, -25879, 125})
    table.insert(asteroids, {-5136, -18227, 130})
    table.insert(asteroids, {5349, -26162, 122})
    table.insert(asteroids, {390, -18227, 113})
    table.insert(asteroids, {-10804, -25170, 117})
    table.insert(asteroids, {-8112, -19786, 120})
    table.insert(asteroids, {2373, -11851, 117})
    table.insert(asteroids, {-5561, -9868, 121})
    table.insert(asteroids, {-27524, -17802, 122})
    table.insert(asteroids, {-22139, -17377, 125})
    table.insert(asteroids, {-28657, -10718, 120})
    table.insert(asteroids, {-24690, -9159, 124})
    table.insert(asteroids, {-46935, -9159, 117})
    table.insert(asteroids, {-57846, -8026, 117})
    table.insert(asteroids, {-38434, -8451, 115})
    table.insert(asteroids, {-41551, -8734, 119})
    table.insert(asteroids, {-64363, -17236, 117})
    table.insert(asteroids, {-66064, -22903, 127})
    table.insert(asteroids, {-64222, -8592, 112})
    table.insert(asteroids, {-62663, -12418, 111})
    table.insert(asteroids, {-72298, -50817, 124})
    table.insert(asteroids, {-74423, -44724, 129})
    table.insert(asteroids, {-69323, -29138, 128})
    table.insert(asteroids, {-69039, -32255, 118})
    table.insert(asteroids, {-37300, 25980, 114})
    table.insert(asteroids, {-38575, 34057, 126})
    table.insert(asteroids, {-35883, 30373, 123})
    table.insert(asteroids, {-36025, 15212, 124})
    table.insert(asteroids, {-32908, -799, 124})
    table.insert(asteroids, {-31633, 18187, 115})
    table.insert(asteroids, {-29507, 4727, 116})
    table.insert(asteroids, {-18172, 759, 122})
    table.insert(asteroids, {-26532, 334, 111})
    table.insert(asteroids, {-18172, 18896, 128})
    table.insert(asteroids, {-17747, 22155, 115})
    table.insert(asteroids, {-19022, 15212, 126})
    table.insert(asteroids, {-22281, 12945, 116})
    table.insert(asteroids, {-18597, 7277, 111})
    table.insert(asteroids, {-17888, 34482, 114})
    table.insert(asteroids, {-24123, 32640, 125})
    table.insert(asteroids, {-26957, 11244, 112})
    table.insert(asteroids, {-26248, 7419, 122})
    table.insert(asteroids, {-25256, 18612, 119})
    table.insert(asteroids, {-50903, 16204, 122})
    table.insert(asteroids, {-58554, 10253, 117})
    table.insert(asteroids, {-51469, 3451, 123})
    table.insert(asteroids, {-58837, 476, 114})
    table.insert(asteroids, {-61388, 20738, 126})
    table.insert(asteroids, {-56854, 3310, 118})
    table.insert(asteroids, {-61671, 5152, 120})
    table.insert(asteroids, {-45943, -4058, 115})
    table.insert(asteroids, {-43676, -2783, 119})
    table.insert(asteroids, {-39851, 192, 125})
    table.insert(asteroids, {-46794, 1893, 128})
    table.insert(asteroids, {-40134, 9827, 129})
    table.insert(asteroids, {-41976, 4727, 128})
    table.insert(asteroids, {-42401, 7135, 118})
    table.insert(asteroids, {-49486, 9261, 125})
    table.insert(asteroids, {-46935, 21021, 115})
    table.insert(asteroids, {-40417, 16770, 112})
    table.insert(asteroids, {-39426, 30231, 111})
    table.insert(asteroids, {-54162, 26547, 125})
    table.insert(asteroids, {-50478, 29098, 127})
    table.insert(asteroids, {-54587, 29381, 118})
    table.insert(asteroids, {-45518, 32073, 116})
    table.insert(asteroids, {-2019, -2641, 115})
    table.insert(asteroids, {13142, -5475, 116})
    table.insert(asteroids, {15834, -941, 125})
    table.insert(asteroids, {6341, 3310, 112})
    table.insert(asteroids, {6624, -3917, 111})
    table.insert(asteroids, {-11087, -1366, 120})
    table.insert(asteroids, {-10237, 7560, 113})
    table.insert(asteroids, {2515, 2743, 121})
    table.insert(asteroids, {-6128, 5293, 116})
    table.insert(asteroids, {-7828, 5293, 112})
    table.insert(asteroids, {-71590, -2358, 130})
    table.insert(asteroids, {-69181, -1933, 116})
    table.insert(asteroids, {-63088, -3066, 118})
    table.insert(asteroids, {-66489, 4868, 128})
    table.insert(asteroids, {-70173, 10111, 127})
    table.insert(asteroids, {-74848, 27114, 120})
    table.insert(asteroids, {-75274, 19179, 113})
    table.insert(asteroids, {-70173, 33348, 111})
    table.insert(asteroids, {-66205, 29664, 119})
    table.insert(asteroids, {-64222, 21446, 115})
    table.insert(asteroids, {-72865, 28956, 121})
    table.insert(asteroids, {-4711, 13370, 122})
    table.insert(asteroids, {673, 9119, 124})
    table.insert(asteroids, {8750, 8694, 123})
    table.insert(asteroids, {11867, 10819, 126})
    table.insert(asteroids, {13709, 17195, 111})
    table.insert(asteroids, {-15055, 8694, 114})
    table.insert(asteroids, {-10946, 18471, 128})
    table.insert(asteroids, {-29507, 37316, 111})
    table.insert(asteroids, {9600, 31223, 117})
    table.insert(asteroids, {13567, 23572, 122})
    table.insert(asteroids, {1098, 31506, 127})
    table.insert(asteroids, {16826, 31506, 121})
    table.insert(asteroids, {6624, 18329, 119})
    table.insert(asteroids, {5066, 23005, 124})
    table.insert(asteroids, {2090, 23430, 119})
    table.insert(asteroids, {-4995, 28106, 129})
    table.insert(asteroids, {-13213, 23855, 116})
    table.insert(asteroids, {-7687, 24847, 121})
    table.insert(asteroids, {-12363, 33773, 120})
    
    foreach(asteroids, function(item)
        Asteroid():setPosition(item[1]/SIZE_COEFFICIENT, item[2]/SIZE_COEFFICIENT):setSize(item[3])
    end)
    
    spawn_mine_resized(-21920, -45627)
    spawn_mine_resized(-16493, -35922)
    spawn_mine_resized(-22370, -38387)
    spawn_mine_resized(-10617, -46539)
    spawn_mine_resized(-11375, -27202)
    spawn_mine_resized(-7067, -32979)
    spawn_mine_resized(6256, -32700)
    spawn_mine_resized(-2086, -39714)
    spawn_mine_resized(13838, -45401)
    spawn_mine_resized(-40190, -39714)
    spawn_mine_resized(-41178, -28245)
    spawn_mine_resized(-31470, -31373)
    spawn_mine_resized(-57826, -37630)
    spawn_mine_resized(-47394, -38387)
    spawn_mine_resized(-52133, -31183)
    spawn_mine_resized(-63697, -42747)
    spawn_mine_resized(-30143, -49951)
    spawn_mine_resized(-54029, -50520)
    spawn_mine_resized(-39709, -47912)
    spawn_mine_resized(-28693, -15515)
    spawn_mine_resized(-70556, -20575)
    spawn_mine_resized(-14738, -19106)
    spawn_mine_resized(-3640, -10292)
    spawn_mine_resized(-50400, -11108)
    spawn_mine_resized(-39242, -17534)
    spawn_mine_resized(-66966, -7844)
    spawn_mine_resized(-73739, -10456)
    spawn_mine_resized(-4550, -22273)
    spawn_mine_resized(-759, -22463)
    spawn_mine_resized(-25403, -7297)
    spawn_mine_resized(-39053, -7107)
    spawn_mine_resized(-58958, -12984)
    spawn_mine_resized(-14598, -14501)
    spawn_mine_resized(-49479, -16775)
    spawn_mine_resized(-61801, -25306)
    spawn_mine_resized(-22749, -25117)
    spawn_mine_resized(-37833, 26267)
    spawn_mine_resized(-34160, 14189)
    spawn_mine_resized(-36778, 1803)
    spawn_mine_resized(-21022, 1296)
    spawn_mine_resized(-15925, -5970)
    spawn_mine_resized(-24455, 36495)
    spawn_mine_resized(-23307, 16801)
    spawn_mine_resized(-55704, 17127)
    spawn_mine_resized(-51564, -4643)
    spawn_mine_resized(-53827, 24716)
    spawn_mine_resized(-39811, 20570)
    spawn_mine_resized(-51564, 33272)
    spawn_mine_resized(3412, -2178)
    spawn_mine_resized(-13081, 12040)
    spawn_mine_resized(2843, 10713)
    spawn_mine_resized(-7312, 2846)
    spawn_mine_resized(-40190, 8627)
    spawn_mine_resized(-26730, 7869)
    spawn_mine_resized(-69384, 14504)
    spawn_mine_resized(-55735, 9196)
    spawn_mine_resized(-51564, 12040)
    spawn_mine_resized(-74882, 26637)
    spawn_mine_resized(-65024, 25879)
    spawn_mine_resized(-5109, 30021)
    spawn_mine_resized(-6415, 35080)
    spawn_mine_resized(-10427, 27964)
    spawn_mine_resized(-4048, 19412)

    Nebula():setPosition(-18880/SIZE_COEFFICIENT, -34522/SIZE_COEFFICIENT)
    Nebula():setPosition(3412/SIZE_COEFFICIENT, -45401/SIZE_COEFFICIENT)
    Nebula():setPosition(12701/SIZE_COEFFICIENT, -26254/SIZE_COEFFICIENT)
    Nebula():setPosition(-66920/SIZE_COEFFICIENT, -28150/SIZE_COEFFICIENT)
    Nebula():setPosition(-68247/SIZE_COEFFICIENT, -49193/SIZE_COEFFICIENT)
    Nebula():setPosition(9289/SIZE_COEFFICIENT, -6159/SIZE_COEFFICIENT)
    Nebula():setPosition(-37157/SIZE_COEFFICIENT, -21325/SIZE_COEFFICIENT)
    Nebula():setPosition(-31280/SIZE_COEFFICIENT, -52036/SIZE_COEFFICIENT)
    Nebula():setPosition(-14977/SIZE_COEFFICIENT, -8434/SIZE_COEFFICIENT)
    Nebula():setPosition(-62180/SIZE_COEFFICIENT, 97/SIZE_COEFFICIENT)
    Nebula():setPosition(-35640/SIZE_COEFFICIENT, 7490/SIZE_COEFFICIENT)
    Nebula():setPosition(-73934/SIZE_COEFFICIENT, 24931/SIZE_COEFFICIENT)
    Nebula():setPosition(-26541/SIZE_COEFFICIENT, 26826/SIZE_COEFFICIENT)
    Nebula():setPosition(7772/SIZE_COEFFICIENT, 25499/SIZE_COEFFICIENT)
    

    -- Put datapods there
    -- Put autospawning mines there (use scheduler to put mine back after N seconds.
    -- Put nebulas there
    -- Put asteroids there - And also visual asteroids if possible
    -- Put enemy ships there (3 tiers. Low: 5 hits, Mid: 1-2 hits, High: Instant kill) - cannot be destroyed
    -- Put enemy torpedo ships there - cannot be destroyed and their torpedo supplies will be periodically replenished. 
end

function gm_main_menu()
    clearGMFunctions()
    reset_scenario_button("scenario_006_e6_hazardy.lua")
    addGMFunction("Spawn player", function() gm_spawn_menu() end)
    addGMFunction("Add hazards", function() gm_hazards_menu() end)
    addGMFunction("Statistics", function() 
        math.abs(0)
        local text = "STATISTICS\n"
        local endline=0
        foreach(SHIP_DATA, function(obj) 
            if obj.instance ~= nil then
                text = text..obj.callsign..":    "..obj.instance._datapods
            else
                text = text..obj.callsign..": DEAD"
            end
            if endline == 2 then text = text.."\n" endline=0 else text = text.." \t      " endline=endline+1 end 
        end)
        text = text.."\nSum retrieved: "..datapods_picked.."\nSum delivered: "..datapods_delivered
                  
        addGMMessage(text)
    end)
    
    immovableObjects:gm_button(gm_main_menu)
end

function gm_spawn_menu()
    clearGMFunctions()
    addGMFunction("-From spawn", gm_main_menu)
    
    if PLAYER_SHIELDS_ON_SPAWN then 
        addGMFunction("shields on spawn ON", function() 
            PLAYER_SHIELDS_ON_SPAWN=false 
            gm_spawn_menu()
        end)
    else
        addGMFunction("shields on spawn OFF", function() 
            PLAYER_SHIELDS_ON_SPAWN=true 
            gm_spawn_menu()
        end)
    end

    for i, object in ipairs(SHIP_DATA) do
        addGMFunction(" Spawn "..object.callsign, function() spawn_player(i) end)
    end
end

function gm_hazards_menu()
    clearGMFunctions()
    addGMFunction("-From hazards", gm_main_menu)
    
    if SPAWN_MULTIPLE_HAZARDS then 
        addGMFunction("in MULTI mode", function() 
            SPAWN_MULTIPLE_HAZARDS=false 
            gm_hazards_menu()
        end)
    else
        addGMFunction("in SINGLE mode", function() 
            SPAWN_MULTIPLE_HAZARDS=true 
            gm_hazards_menu()
        end)
    end
    
    gm_exec_on_gm_click_button(" Add datapod", function(x,y) math.abs(0) spawn_datapod(x,y) end, SPAWN_MULTIPLE_HAZARDS)
    gm_exec_on_gm_click_button(" Add mine", function(x,y) math.abs(0) spawn_mine(x,y) end, SPAWN_MULTIPLE_HAZARDS)
    gm_exec_on_gm_click_button(" Add nebula", function(x, y) math.abs(0) Nebula():setPosition(x, y) end, SPAWN_MULTIPLE_HAZARDS)
    gm_exec_on_gm_click_button(" Add asteroid", function(x, y) math.abs(0) Asteroid():setPosition(x, y) end, SPAWN_MULTIPLE_HAZARDS)
    
    for i, txt in ipairs({"easy", "medium", "hard", "torpedo"}) do
        gm_exec_on_gm_click_button(" Add "..txt.." foe", function(x, y) math.abs(0) spawn_enemy(x, y, txt) end, SPAWN_MULTIPLE_HAZARDS)
    end
end

function init()
    init_factions()
    init_base()
    
    gm_main_menu()    
    init_hostile_map()
    
--     unpauseGame()
end

function update(delta)
    hemmonds_toolkit_update(delta)
    -- No victory condition
    
    foreach(SHIP_DATA, function(row)     
        if row.instance ~= nil then
            if distance(row.instance, polaris) <= polaris:getLongRangeRadarRange() and row.instance._datapods > 0 then
                datapods_delivered = datapods_delivered+row.instance._datapods
                customElements:addCustomMessage(row.instance, "Helms", "pods_delivered", "DATA PŘENESENA\nPřeneseno dat: "..row.instance._datapods)
                row.instance._datapods=0
            end
            customElements:addCustomInfo(row.instance, "Helms", "pod_counter", "Získaných dat: "..row.instance._datapods)
            customElements:addCustomInfo(row.instance, "Helms", "position", "Pozice: "..getSectorName(row.instance:getPosition()))
            refill_energy(row.instance)
        end
    end)
    
    foreach(enemies["torpedo"], function(enemy)
        if enemy ~= nil then
            enemy:setWeaponStorage("Homing", 50)
        end
    end)
end
