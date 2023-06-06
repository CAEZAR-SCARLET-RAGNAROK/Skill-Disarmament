local common = require("Caezar.Skill-Disarmament.common")
local config = require("Caezar.Skill-Disarmament.config")

----------------------------

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("Caezar.Skill-Disarmament.mcm")
end)

--------------------------------------
-- skillModule = require("OtherSkills.skillModule")
if (common.skill.module == nil) then
    common.logError("error loading skill module.")
else
    common.logInfo("loaded skill module.")
end

local function onSkillReady()
    common.skill.module.registerSkill(
        common.skill.id,
        {
            name            =   config.skillDisarmament_Name or "Disarmament",
            value           =   config.skillDisarmament_Value or 5,
            progress        =   config.skillDisarmament_Progress or 0,
            lvlCap          =   config.skillDisarmament_LvlCap or 100,
            icon            =   config.skillDisarmament_Icon or "Icons/Caezar/Skills/Disarmament/skill.dds",
            attribute       =   config.skillDisarmament_Attribute or tes3.attribute.agility,
            description     =   config.skillDisarmament_Specialization or tes3.specialization.stealth,
            specialization  =   config.skillDisarmament_Description or "Disarmament skill defines one's proficiency in which you are able to disarm assailaints and enemies. If using hand to hand, there is a chance to steal the target's weapon. If using a weapon, there is a chance to disarm the target, causing their weapon to fall to the ground.",
            active          =   config.skillDisarmament_Active or "active",
        }
    )
    common.Skill = common.skill.module.getSkill("Caezar:Disarmament")
end
event.register("OtherSkills:Ready", onSkillReady)

----------------------------------------
require("Caezar.Skill-Disarmament.disarmament")

----------------------------------------
local function initialized()
    mwse.log("[" .. common.mod .." " .. common.version .. "] Initialized.")
end

event.register("initialized", initialized)