-- Name: Etapa 2 - skenování
-- Description: Pouze vědecká konzole na mustku, skenuje artefakty kolem planety, každá dává nějaké údaje
-- Type: Hvězdná Loď

--- Scenario
-- @script scenario_002_e2_skenovani

require("lod-2023-02_common_functions.lua")

-- Spustit: EmptyEpsilon autoconnect="4" autoconnect_address=127.0.0.1 autoconnectship=faction=Federation

--[[ # Calculate position of artifacts in python
from math import sin, cos, radians

step=360/17
radius=10000

for i in range(0,17):
    x=radius*sin(radians(i*step))+5000
    y=radius*cos(radians(i*step))+5000
    print(f'Artifact():setPosition({int(x)}, {int(y)}):setModel("artifact3")')
--]]

difficulty = {
    easy = {c=2, d=2},
    medium = {c=3, d=3},
    hard = {c=5, d=5}
}

function create_artifact_data(diff, scanned_text, unscanned_text)
    local ut = unscanned_text
    if unscanned_text == nil then ut="Nutno oskenovat." end
    return {c=diff.c, d=diff.d, st=scanned_text, ut=ut}
end

function init_artifacts()
    local artifact_data = {}
    -- Pro zmenu poradi jednotlivych velicin na jednotlivych artefaktech zmen poradi artifact_data radku. 
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Dusík: 78%", "Dusík"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Kyslík: 18,750%", "Kyslík"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Argon: 0,12%", "Argon"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "CO2: 0,42%", "CO2"))
    table.insert(artifact_data, create_artifact_data(difficulty.easy, "Neon: 0,05%", "Neon"))
    table.insert(artifact_data, create_artifact_data(difficulty.easy, "Helium: 0,10%", "Helium"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Metan: 0,10%", "Metan"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Krypton 0,10%", "Krypton"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Síra: 2,250%", "Síra"))
    
    table.insert(artifact_data, create_artifact_data(difficulty.hard, "Průměrný atmosferický tlak: 901hPa", "Průměrný atmosferický tlak"))
    table.insert(artifact_data, create_artifact_data(difficulty.easy, "Průměrná teplota: 20°C", "Průměrná teplota"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Minimální teplota na planetě: -71,1˚C", "Minimální teplota na planetě"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Maximální teplota na planetě: 53,8˚C ", "Maximální teplota na planetě"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Vlhkost vzduchu: 60,000%", "Vlhkost vzduchu"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Rychlost pohybu vzduchu: 12 km/h", "Rychlost pohybu vzduchu"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Aktuální srážky: 0,2 mm", "Aktuální srážky"))
    table.insert(artifact_data, create_artifact_data(difficulty.medium, "Radioaktivita: 0,07 mSv/h", "Radioaktivita"))

    local artifacts = {}
    table.insert(artifacts, Artifact():setPosition(5000, 14000):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(8251, 13392):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(11063, 11651):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(13056, 9011):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(13961, 5830):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(13656, 2537):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(12182, -423):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(9737, -2651):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(6653, -3846):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(3346, -3846):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(262, -2651):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(-2182, -423):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(-3656, 2537):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(-3961, 5830):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(-3056, 9011):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(-1063, 11651):setModel("artifact3"))
    table.insert(artifacts, Artifact():setPosition(1748, 13392):setModel("artifact3"))
    
    for i, artifact in ipairs(artifacts) do
        artifact:setScanningParameters(artifact_data[i].c, artifact_data[i].d):setDescriptions(artifact_data[i].ut, artifact_data[i].st)
    end
end


function init()
    init_factions()
    
    --reset_scenario_button("scenario_002_e2_skenovani.lua")
    
    local player = PlayerSpaceship():setTemplate("Atlantis"):setPosition(-7000, -3500):setFaction("Federation"):setCallSign("USS Polaris")
    
    local planet = Planet():setPosition(5000, 5000):setPlanetRadius(11000):setDistanceFromMovementPlane(-2000):setPlanetSurfaceTexture("planets/planet-1.png"):setPlanetCloudTexture("planets/clouds-1.png"):setPlanetAtmosphereTexture("planets/atmosphere.png"):setPlanetAtmosphereColor(0.2, 0.2, 1.0):setCallSign("Starton A")
    
    immovableObjects:add(player)
    immovableObjects:add(planet)
    
    init_artifacts()
    
    unpauseGame()
end

function update(delta)
    hemmonds_toolkit_update(delta)
    -- No victory condition
end
