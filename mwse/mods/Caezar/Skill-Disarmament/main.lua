--[[
    This is Skill-Disarmament. New ability to disarm your enemies. It is based on work by Operator Jack.
]]
local common = require("Caezar.Skill-Disarmament.common")
local config = require("Caezar.Skill-Disarmament.config")

----------------------------

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function() require("Caezar.Skill-Disarmament.mcm") end)

--------------------------------------

local function onSkillReady()
    if (not common.skillModule) then
        common.log:error("loading skill module.")
    end
    common.skillModule.registerSkill(
        common.skillId,
        {
            name            =    "Disarmament",
            value           =    5,
            progress        =    0,
            lvlCap          =    100,
            icon            =    "Icons/Caezar/Skills/Disarmament/skill.dds",
            attribute       =    tes3.attribute.agility,
            specialization  =    tes3.specialization.stealth,
            description     =    "Disarmament skill defines one's proficiency in which you are able to disarm assailaints and enemies. If using hand to hand, there is a chance to steal the target's weapon. If using a weapon, there is a chance to disarm the target, causing their weapon to fall to the ground.",
            active          =    "active",
        }
    )
    common.skill = common.skillModule.getSkill(common.skillId)
    if (not common.skill) then
        common.log:error("registering skill.")
    end
end
event.register("OtherSkills:Ready", onSkillReady)

----------------------------------------
require("Caezar.Skill-Disarmament.disarmament")

----------------------------------------
local function initialized()
    common.log:info("Initialized.")
    common.wlog("KELJF","Initialized.")
end

event.register("initialized", initialized)