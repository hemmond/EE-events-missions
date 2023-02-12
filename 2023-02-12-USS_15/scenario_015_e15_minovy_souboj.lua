-- Name: Etapa 15a - Stíhač.bitvy + capital
-- Description: hráči - 3 dvojmístné lodě, stíhačkový souboj. 
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
rom_pwd = "EQUADOR"
PLAYER_SHIELDS_ON_SPAWN = true

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

POLARIS_COORDS={x=-90000, y=-10000}
POLARIS_CALL_SIGN="USS Polaris"

romulans = nil

function spawn_player(number)
    if SHIP_DATA[number].instance == nil then 
        local player = PlayerSpaceship():setFaction("Federation"):setTemplate("Phobos M3P"):setCallSign(SHIP_DATA[number].callsign)
        hemmonds_toolkit_small_player_ship_setup(player)
        
        player:setPosition(SHIP_DATA_LOCAL[number].x, SHIP_DATA_LOCAL[number].y):setRotation(SHIP_DATA_LOCAL[number].rot):commandTargetRotation(SHIP_DATA_LOCAL[number].rot)
                
        player:commandSetShields(PLAYER_SHIELDS_ON_SPAWN)
        
        player:setLongRangeRadarRange(10000):setShortRangeRadarRange(4000)

        player:onDestroyed(function() 
            math.abs(0) 
            addGMMessage("SHIP "..SHIP_DATA[number].callsign.." DESTROYED")
            SHIP_DATA[number].instance=nil 
        end)
        
        SHIP_DATA[number].instance=player
    end
end

function spawn_polaris()
    local p = PlayerSpaceship():setTemplate("Atlantis"):setFaction("Federation"):setCallSign(POLARIS_CALL_SIGN):setPosition(-1000, -1000):setCanBeDestroyed(false)
                                :setRotation(0):commandTargetRotation(0):commandSetShields(true):setCanHack(false):setWarpDrive(false):setJumpDrive(false)
    
    local beam_range=0  --original was 1500
    p:setBeamWeapon(0, 100, -20, 0, 6, 1)
    p:setBeamWeapon(1, 100,  20, 0, 6, 1)
    p:setWeaponTubeCount(2)
    p:setWeaponTubeExclusiveFor(0, "Mine"):setWeaponTubeDirection(0, 179)
    p:setWeaponTubeExclusiveFor(1, "Mine"):setWeaponTubeDirection(1, 181)
    
    p:setWeaponStorageMax("Nuke", 0):setWeaponStorage("Nuke", 0)
    p:setWeaponStorageMax("EMP", 0):setWeaponStorage("EMP", 0)
    p:setWeaponStorageMax("Homing", 0):setWeaponStorage("Homing", 0)
    p:setWeaponStorageMax("HVLI", 0):setWeaponStorage("HVLI", 0)
    
    p:setWeaponStorageMax("Mine", 20):setWeaponStorage("Mine", 20)
    
    if use_control_codes then p:setControlCode(polaris_pwd) end
    polaris = p
end

function spawn_romulan()
    local r = CpuShip():setTemplate("Atlantis X23"):setFaction("Romulans"):setPosition(1000, -1000):setCanBeDestroyed(false):setRotation(180)

        --if use_control_codes then r:setControlCode(rom_pwd) end
        romulans = r
        
        r:onTakingDamage(function(object, instigator)
            if instigator ~= nil and instigator.typeName == "PlayerSpaceship" and instigator:getCallSign() == POLARIS_CALL_SIGN then
                print("Romulans took damage from Polaris")
            else print("damage ignored")
            end
        end)
end

function init()
    init_factions()
    
    spawn_polaris()
    spawn_player(1)
    spawn_player(2)
    spawn_player(3)
    
    gm_main_menu()
    
    --spawn_romulan()
end

function gm_main_menu()
    clearGMFunctions()
    addGMFunction("Spawn player", function() gm_spawn_menu() end)
    gm_spawn_enemy_button(gm_main_menu, "Romulans")
    addGMLabel()
    gm_refil_torpedoes_button()
    gm_refill_energy_button()
    addGMLabel()
    immovableObjects:gm_button(gm_main_menu)
    --gmVictoryButton(gm_main_menu)
    addGMFunction("Reseet scenario?", gm_reset_submenu)
end

function gm_reset_submenu()
    clearGMFunctions()
    addGMFunction("-From reset", gm_main_menu)
    addGMLabel()
    reset_scenario_button("scenario_015_e15_minovy_souboj.lua")
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
    
    addGMLabel()
    addGMFunction("Spawn enemy BASE ship", function() 
        if romulans == nil then
            spawn_romulan()
        end
    end)
end

function update(delta)
    -- No victory condition
    hemmonds_toolkit_update(delta)
end
