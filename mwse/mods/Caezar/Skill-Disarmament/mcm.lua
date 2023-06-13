local common = require("Caezar.Skill-Disarmament.common")
local config = require("Caezar.Skill-Disarmament.config")

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    page:createDropdown{
        label = "Logger",
        description = "Keep on INFO unless you wish to see extra data in the log.",
        options = {
            { label = "TRACE",  value = "TRACE" }, -- 1
            { label = "DEBUG",  value = "DEBUG" }, -- 2
            { label = "INFO",   value = "INFO" }, -- 3
            { label = "WARN",   value = "WARN" }, -- 4
            { label = "ERROR",  value = "ERROR" }, -- 5
            { label = "NONE",   value = "NONE" }, -- 6 quiet mode
        },
        variable =  mwse.mcm.createTableVariable{
            id = "loggerLevel",
            table = config
        }
    }

    return category
end

local function createDisarmamentCategory(page)
    local category = page:createCategory{
        label = "Disarmament Settings"
    }

if (not common.skillModule) then
    local category = page:createCategory{
        label = "--- WARNING ---\nskill module not loaded. features may not work as expected."
    }
end

    category:createOnOffButton{
        label = "Enable Skill-Disarmament",
        description = "Activate or deactivate the mod.",
        variable = mwse.mcm.createTableVariable{
            id = "enableDisarmament",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable God Mode",
        description = "Enables God Mode - you will always disarm your targets and be protected attackers from disarming you.",
        variable = mwse.mcm.createTableVariable{
            id = "enableGodMode",
            table = config
        }
    }

    category:createSlider{
        label = "Base Chance",
        description = "Use this option to configure the base chance at which disarmament will happen.",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "disarmamentBaseChance",
            table = config
        }
    }

    category:createSlider{
        label = "Max Chance",
        description = "Use this option to configure the maximum chance at which disarmament will happen. Calcualted chance will be cut-off to this value if higher.",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "disarmamentMaxChance",
            table = config
        }
    }

    category:createSlider{
        label = "Search Distance",
        description = "Use this option to configure the distance at which a strike can trigger a disarmament.",
        min = 0,
        max = 500,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "disarmamentSearchDistance",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Skill-Disarmament by Caezar")
template:saveOnClose("Skill-Disarmament-Caezar", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "This is Skill-Disarmament. New ability to disarm your enemies. (From Operator Jack's Simple Combat Mechanics - Disarmament features.)",
}

createGeneralCategory(page)
createDisarmamentCategory(page)

mwse.mcm.register(template)