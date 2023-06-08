local config = require("Caezar.Skill-Disarmament.config")

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Debug Mode",
        description = "Use this option to enable debug mode.",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable God Mode (for player)",
        description = "Enables God Mode - you will always disarm your targets and be protected attackers from disarming you.",
        defaultSetting = config.enableGodMode or false,
        variable = mwse.mcm.createTableVariable{
            id = "enableGodMode",
            table = config
        }
    }

    return category
end

local function createDisarmamentCategory(page)
    local category = page:createCategory{
        label = "Disarmament Settings"
    }

    category:createOnOffButton{
        label = "Enable Disarmament",
        description = "Use this option to enable disarmament. This will add a disarming mechanic which allows the PC and NPCs to disarm each other. If using hand to hand, there is a chance to steal the target's weapon. If using a weapon, there is a chance to disarm the target, causing them to drop their weapon to the ground. Chances are based on the attacker and target's skills in their respective weapon.",
        variable = mwse.mcm.createTableVariable{
            id = "enableDisarmament",
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
    description = "This is Skill-Disarmament. (From Operator Jack's Simple Combat Mechanics - Disarmament features. I added a Skill Module skill for it plus a settings page to control its details and some more features and improvements.)",
}

createGeneralCategory(page)
createDisarmamentCategory(page)

mwse.mcm.register(template)