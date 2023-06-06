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

local function createSkillDisarmamentCategory(page)
    local category = page:createCategory{
        label = "Configure Meta Settings"
    }

    local category = page:createCategory{
        label = "You can set values for the skill register call on this page."
    }

    category:createTextField{
        label = "Name",
        description = "The name to display.",
        defaultSetting = config.skillDisarmament_Name or "Disarmament",
        variable = mwse.mcm.createTableVariable{
            id = "skillDisarmament_Name",
            table = config
        }
    }
    -- config.skillDisarmament_Name = ""

    category:createSlider{
        label = "Value",
        description = "The base or current level of the skill.",
        min = 0,
        max = 1000,
        step = 1,
        jump = 5,
        defaultSetting = config.skillDisarmament_Value or 5,
        variable = mwse.mcm.createTableVariable{
            id = "skillDisarmament_Value",
            table = config
        }
    }

    category:createSlider{
        label = "Progress",
        description = "The progress of the skill.",
        min = 0,
        max = 1000,
        step = 1,
        jump = 5,
        defaultSetting = config.skillDisarmament_Progress or 0,
        variable = mwse.mcm.createTableVariable{
            id = "skillDisarmament_Progress",
            table = config
        }
    }

    category:createSlider{
        label = "Progress/Experience",
        description = "The amount of experience increase per use.",
        min = 0,
        max = 1000,
        step = 1,
        jump = 5,
        defaultSetting = config.skillDisarmament_ProgressExp or 10,
        variable = mwse.mcm.createTableVariable{
            id = "skillDisarmament_ProgressExp",
            table = config
        }
    }

    category:createSlider{
        label = "Level Cap",
        description = "The highest attainable level of the skill.",
        min = 0,
        max = 1000,
        step = 1,
        jump = 5,
        defaultSetting = config.skillDisarmament_LvlCap or 100,
        variable = mwse.mcm.createTableVariable{
            id = "skillDisarmament_LvlCap",
            table = config
        }
    }

    category:createTextField{
        label = "Icon",
        description = "The path to a DDS graphic for the skill.",
        defaultSetting = config.skillDisarmament_Icon or "Icons\\Caezar\\Skills\\Disarmament\\skill.dds",
        variable = mwse.mcm.createTableVariable{
            id = "skillDisarmament_Icon",
            table = config
        }
    }

    page:createDropdown{
        label = "Attribute",
        description = "The governing attribute.",
        defaultSetting = config.skillDisarmament_Attribute or tes3.attribute.agility,
        options = {
            { label = "Strength", value = tes3.attribute.strength },
            { label = "Intelligence", value = tes3.attribute.intelligence },
            { label = "Willpower", value = tes3.attribute.willpower },
            { label = "Agility", value = tes3.attribute.agility },
            { label = "Speed", value = tes3.attribute.speed },
            { label = "Endurance", value = tes3.attribute.endurance },
            { label = "Personality", value = tes3.attribute.personality },
            { label = "Luck", value = tes3.attribute.luck },
            { label = "NONE", value = nil },
        },
        variable =  mwse.mcm.createTableVariable{
            id = "skillDisarmament_Attribute",
            table = config
        },
    }

    page:createDropdown{
        label = "Specialization",
        description = "The speciality class.",
        defaultSetting = config.skillDisarmament_Specialization or tes3.attribute.stealth,
        options = {
            { label = "Combat", value = "tes3.attribute.combat" },
            { label = "Magic", value = "tes3.attribute.magic" },
            { label = "Stealth", value = "tes3.attribute.stealth" },
            { label = "NONE", value = "" },
        },
        variable =  mwse.mcm.createTableVariable{
            id = "skillDisarmament_Specialization",
            table = config
        },
    }

    page:createDropdown{
        label = "Active",
        description = "Use this to switch on/off the skill.",
        defaultSetting = config.skillDisarmament_Active or "active",
        options = {
            { label = "Active", value = "active" },
            { label = "Inactive", value = "inactive" },
        },
        variable =  mwse.mcm.createTableVariable{
            id = "skillDisarmament_Active",
            table = config
        },
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Skill-Disarmament by Caezar")
template:saveOnClose("Skill-Disarmament-Caezar", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "This is Operator Jack's Simple Combat Mechanics - Disarmament features. I added a Skill Module skill for it plus a settings page to control its details and some more features and improvements."
}
local page1 = template:createSideBarPage{
    label = "Skilled Disarmament Meta Settings",
    description = "Hover over a setting to learn more about it."
}

createGeneralCategory(page)
createDisarmamentCategory(page)
createSkillDisarmamentCategory(page1)

mwse.mcm.register(template)