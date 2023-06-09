-- Load configuration.
local defaultConfig = {
    -- Disarmament Settings
    enableDisarmament = true,
    disarmamentBaseChance = 1,
    disarmamentMaxChance = 50 + 25,
    disarmamentSearchDistance = 256 + 50,

    -- General Settings
    loggerLevel = "INFO",
    enableGodMode = false,
}

return mwse.loadConfig("Skill-Disarmament-Caezar") or defaultConfig