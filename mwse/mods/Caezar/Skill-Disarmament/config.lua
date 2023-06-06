-- Load configuration.
local defaultConfig = {
    -- Disarmament Settings
    enableDisarmament = true,
    disarmamentBaseChance = 1,
    disarmamentMaxChance = 50 + 25,
    disarmamentSearchDistance = 256 + 50,

    -- Skilled Disarmament - advanced configuration
    skillDisarmament_Name = nil,
    skillDisarmament_Value = nil,
    skillDisarmament_Progress = nil,
    skillDisarmament_ProgressExp = nil,	-- the amount of experience increase per use
    skillDisarmament_LvlCap = nil,
    skillDisarmament_Icon = nil,
    skillDisarmament_Attribute = nil,
    skillDisarmament_Specialization = nil,
    skillDisarmament_Description = nil,
    skillDisarmament_Active = nil,

    -- General Settings
    debugMode = false,
    enableGodMode = nil,
}

return mwse.loadConfig("Skill-Disarmament-Caezar") or defaultConfig