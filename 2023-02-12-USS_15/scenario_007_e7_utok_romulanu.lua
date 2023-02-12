-- Name: Etapa 7 - Utok romulanu[Kamil]
-- Description: Utok romulanu na Polaris. 3 lode po 2 clenech posadky.
-- Type: Hvězdná Loď

--- Scenario
-- @script scenario_007_e7_utok_romulanu

require("lod-2023-02_common_functions.lua")

ROM_SHIP_NAME = "Vagram"

use_control_codes = false
polaris_pwd = "EQUADOR"
rom_pwd = "EQUADOR"

SHIP_DATA={
    {callsign="Alpha",   instance=nil},
    {callsign="Bravo",   instance=nil},
    {callsign="Charlie", instance=nil} 
}

SHIP_DATA_LOCAL={
    {x=-2000, y=-2000, rot=225},
    {x=-3000, y=-1000, rot=180},
    {x=-2000, y=-0, rot=135}
}

polaris = nil
romulans = nil
PLAYER_SHIELDS_ON_SPAWN = false

UPGRADE_STAGE=0  -- 0   1   2   3    4    5
UPGRADE_IMPULSE  = {60, 60, 80, 80, 110, 110}
UPGRADE_ROTATION = {10, 10, 10, 20,  20,  40}


function spawn_player(number)
    if SHIP_DATA[number].instance == nil then 
        local player = PlayerSpaceship():setFaction("Federation"):setTemplate("Phobos M3P"):setCallSign(SHIP_DATA[number].callsign)
        hemmonds_toolkit_small_player_ship_setup(player)
        
        player:setPosition(SHIP_DATA_LOCAL[number].x, SHIP_DATA_LOCAL[number].y):setRotation(SHIP_DATA_LOCAL[number].rot):commandTargetRotation(SHIP_DATA_LOCAL[number].rot)

        apply_upgrades(player)
        
        -- Fastest enemies: MT52/MU52: i: 125, trn:32
        -- Midle type foes: Adder MK5: i: 80, trn: 28
        -- Slowest enemies: Q7/T3 i 60-70, trn:10-12
        
        --players: i: 80, trn: 10
        
        player:commandSetShields(PLAYER_SHIELDS_ON_SPAWN)

        player:onDestroyed(function() 
            math.abs(0) 
            addGMMessage("SHIP "..SHIP_DATA[number].callsign.." DESTROYED")
            SHIP_DATA[number].instance=nil 
        end)
        
        SHIP_DATA[number].instance=player
    end
end

function big_ships_commnad_target()
    if polaris ~= nil and romulans ~= nil then
        polaris:commandSetTarget(romulans)
        romulans:commandSetTarget(polaris)
    end
end

function init()
    init_factions()

    polaris = immovableObjects:spawn(function() 
        local p = PlayerSpaceship():setTemplate("Atlantis"):setFaction("Federation"):setCallSign("USS Polaris"):setPosition(-1000, -1000):setCanBeDestroyed(false):setCanScan(false)
                                    :setRotation(0):commandTargetRotation(0):commandSetShields(true):setCanHack(false)
        
                        -- id arc   dir  rng   cyc  dps
        p:setBeamWeapon(0, 100, -20, 3000, 6.1, 1)
        p:setBeamWeapon(1, 100,  20, 3000, 5.8, 1)
        p:setBeamWeapon(2, 180, -180, 2500, 5.0, 4)
        
        if use_control_codes then p:setControlCode(polaris_pwd) end
        polaris = p
        big_ships_commnad_target()
        return p
     end)

    romulans = immovableObjects:spawn(function() 
        local r = PlayerSpaceship():setTemplate("Atlantis"):setFaction("Romulans"):setCallSign(ROM_SHIP_NAME):setPosition(1000, -1000):setCanBeDestroyed(false):setCanScan(false)
                                     :setRotation(180):commandTargetRotation(180):commandSetShields(true)
                        -- id arc   dir  rng   cyc  dps
        r:setBeamWeapon(0, 100, -20, 3000, 6.2, 1)
        r:setBeamWeapon(1, 100,  20, 3000, 5.9, 1)
        r:setBeamWeapon(2, 180, -180, 2500, 5.0, 4)

        if use_control_codes then r:setControlCode(rom_pwd) end
        romulans = r
        big_ships_commnad_target()
        return r
     end)
    
    spawn_player(1)
    spawn_player(2)
    spawn_player(3)

    gm_main_menu()
end

function gm_main_menu()
    clearGMFunctions()
    addGMFunction("Spawn player", function() gm_spawn_menu() end)
    gm_spawn_enemy_button(gm_main_menu, "Romulans")
    addGMFunction("Upgrades", gm_upgrade_menu)
    addGMLabel()
    gm_refil_torpedoes_button()
    gm_refill_energy_button()
    addGMLabel()
    immovableObjects:gm_button(gm_main_menu)
    --gmVictoryButton(gm_main_menu)
    --reset_scenario_button("scenario_007_e7_utok_romulanu.lua")
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

function gm_upgrade_menu()
    clearGMFunctions()
    addGMFunction("-From upgrades", gm_main_menu)
    addGMFunction("Current stage: "..UPGRADE_STAGE, function() 
        UPGRADE_STAGE = (UPGRADE_STAGE+1)%6
        apply_upgrades_on_all_ships()
        gm_upgrade_menu()
    end)
    
    if UPGRADE_STAGE >= 1 then
        addGMLabel()
        addGMLabel("Combat maneuvers")
    end
    
    local n=0
    if UPGRADE_STAGE >= 2 then
        if UPGRADE_STAGE >= 4 then n=2 else n=1 end
        addGMLabel("Impulse "..n.."x")
    end
    
    if UPGRADE_STAGE >= 3 then
        if UPGRADE_STAGE >= 5 then n=2 else n=1 end
        addGMLabel("Rotation "..n.."x")
    end
end

function apply_upgrades_on_all_ships()
    foreach(SHIP_DATA, function(row)
        if row.instance ~= nil then
            apply_upgrades(row.instance)
        end
    end)
end

function apply_upgrades(ship)
    ship:setCanCombatManeuver(UPGRADE_STAGE >= 1)
        :setImpulseMaxSpeed(UPGRADE_IMPULSE[UPGRADE_STAGE+1])
        :setRotationMaxSpeed(UPGRADE_ROTATION[UPGRADE_STAGE+1])
end

function update(delta)
    -- No victory condition
    hemmonds_toolkit_update(delta)
end


