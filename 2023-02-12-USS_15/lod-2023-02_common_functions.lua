require("hemmonds_toolkit.lua")

function init_factions()
    -- Federace - hraci - Modra barva
    local fed = FactionInfo():setName("Federation"):setLocaleName("Federace"):setGMColor(100, 100, 255)
    
    -- Romulani - zelena barva
    local rom = FactionInfo():setName("Romulans"):setLocaleName("Neznámá"):setGMColor(50, 255, 175)

    fed:setEnemy(rom)
    
    -- Prostredi - cervena
    local env = FactionInfo():setName("Environment"):setLocaleName("Prostředí"):setGMColor(255, 0, 0)
    fed:setEnemy(env)
end

function base_ship()
    
end
