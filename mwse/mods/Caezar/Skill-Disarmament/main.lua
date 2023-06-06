
local config = require("Caezar.Skill-Disarmament.config")

mod = "Skill-Disarmament"
version = "0.18"

function ECHO(level, where, message)
	local levels = {
		["DEBUG"] = true,
		["ERROR"] = true,
		["INFO"] = true,
		["WARNING"] = true,
	}
	local prepend = mod --.. " " .. version
	if levels[level] == true then
		prepend = prepend .. ": " .. level
	end
	if (bit.band(where,1) == 1) then
		mwse.log(string.format("[%s] %s",prepend, message))
	end
	-- if (bit.bor(places[where],places["messagebox"])) then
	if (bit.band(where,2) == 2) then
		tes3.messageBox(string.format("[%s] %s",prepend, message))
	end
end

function echoDebug(message)
	if (config.debugMode == true) then
		ECHO("DEBUG",3,message)
	end
end
function logDebug(message)
	if (config.debugMode == true) then
		ECHO("DEBUG",1,message)
	end
end
function messageboxDebug(message)
	if (config.debugMode == true) then
		ECHO("DEBUG",2,message)
	end
end
function echoInfo(message)
		ECHO("INFO",3,message)
end
function logInfo(message)
		ECHO("INFO",1,message)
end
function messageboxInfo(message)
		ECHO("INFO",2,message)
end

----------------------------

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("Caezar.Skill-Disarmament.mcm")
end)

----------------------------------------
skillModule = require("OtherSkills.skillModule")

if not skillModule then
    local function warningSkill()
        tes3.messageBox(
            "[" .. mod .. " " .. version .. "] " .. "You need to install Skills Module to use this mod!"
        )
    end
    event.register("initialized", warningSkill)
    -- event.register("loaded", warningSkill)
    return
end

local function onSkillReady()
	skillModule.registerSkill(
		"Caezar:Disarmament",
		{
			name 			=	config.skillDisarmament_Name or "Disarmament",
			value			=	config.skillDisarmament_Value or 5,
			progress		=	config.skillDisarmament_Progress or 0,
			lvlCap			=	config.skillDisarmament_LvlCap or 100,
			icon 			=	config.skillDisarmament_Icon or "Icons/Caezar/Skills/Disarmament/skill.dds",
			attribute 		=	config.skillDisarmament_Attribute or tes3.attribute.agility,
			description 	=	config.skillDisarmament_Specialization or tes3.specialization.stealth,
			specialization	=	config.skillDisarmament_Description or "Disarmament skill defines one's proficiency in which you are able to disarm assailaints and enemies. If using hand to hand, there is a chance to steal the target's weapon. If using a weapon, there is a chance to disarm the target, causing their weapon to fall to the ground.",
			active			=	config.skillDisarmament_Active or "active",
		}
	)
end
event.register("OtherSkills:Ready", onSkillReady)

----------------------------------------
require("Caezar.Skill-Disarmament.disarmament")

----------------------------------------
local function initialized()
	mwse.log("[" .. mod .." " .. version .. "] Initialized.")
end

event.register("initialized", initialized)