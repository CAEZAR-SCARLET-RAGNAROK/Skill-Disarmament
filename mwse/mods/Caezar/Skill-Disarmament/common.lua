local logger = require("logging.logger")
local config = require("Caezar.Skill-Disarmament.config")

local this = {}

----------------------------------------

this.mod = "Skill-Disarmament"
this.version = "0.19.5"

this.skill = nil
this.skillModule = include("OtherSkills.skillModule")
this.skillId = "Caezar:Disarmament"

this.conlog = logger.new{
    name = this.mod,
    logLevel = "INFO",
    logToConsole = true,
    includeTimestamp = false,
}
this.log = logger.new{
    name = this.mod,
    logLevel = config.loggerLevel or "INFO",
    logToConsole = false,
    includeTimestamp = false,
}

----------------------------------------
-- this.__yesno = {
    -- [true] = "Yes",
    -- [false] = "No",
-- }
this.__yesno_attacking = {
    [true] = "attacking",
    [false] = "defending",
}
this.__yesno_enabled = {
    [true] = "Enabled",
    [false] = "Disabled",
}

--- wlog - WRITE LOG
function this.wlog(level, message)
    local levels = {
        ["TRACE"] = true,
        ["DEBUG"] = true,
        ["INFO"] = true,
        ["WARN"] = true,
        ["ERROR"] = true,
        ["NONE"] = true,
        ["QUIET"] = true,
    }
    local log = this.log
    if (log == nil or level == nil or config.loggerLevel == nil or not levels[level]) then
        --- throw error
        return
    elseif (config.loggerLevel == "QUIET") then
        return
    end
    levels = {
        ["TRACE"] = function() log:trace(message) end,
        ["DEBUG"] = function() log:debug(message) end,
        ["INFO"] = function() log:info(message) end,
        ["WARN"] =  function() log:warn(message) end,
        ["ERROR"] = function() log:error(message) end,
        ["NONE"] =  function() log:none(message) end,
        ["QUIET"] =  function() --[[ nop ]] end,
    }
    if (config.loggerLevel == level) then
        levels[level]()
    end
end

function this.getWeapons(mobile)
    local weapons = {
        id = nil,
        type = this.weaponType.handToHand,
        skill = mobile.handToHand.current,
        speed = 1.0,
        has = false,
    }
    if (mobile.readiedWeapon) then
        weapons.id =    mobile.readiedWeapon
        weapons.type =  weapons.id.object.type

        weapons.skill = mobile[this.skillMappings[weapons.type]].current
        weapons.speed = weapons.id.object.speed
        weapons.has = true
        if (this.weaponTypeBlacklist[weapons.type] == true) then
            this.wlog("DEBUG","weap type is blacklisted")
            return nil
        end
    end
    return weapons
end

-- @param mods { own = {...}, assailant = {...} }
-- @param weapons { own = { id, type, skill, speed, has }, assailant = { id, type, skill, speed, has } }
function this.new_disarmParty(mobile, mods, weapons)
    local p = {}

    --- validate our handle
    p.Mobile = tes3.makeSafeObjectHandle(mobile)
    if (p.Mobile:valid() == false) then
        this.log:error("invalid handle")
        return nil
    end

    p.isPlayer = false
    p.isGod = false

    if (mobile == tes3.mobilePlayer) then
        p.isPlayer = true
        if (config.enableGodMode == true) then
            p.isGod = true
        end
    end

    p.Skill = 0

    local skill = {
        own = weapons.own.skill,
        assailant = weapons.assailant.skill,
    }

    p.DisarmSkillBonus = 0
    if (p.isPlayer == true) then
        if (this.skill) then
            p.DisarmSkillBonus = this.skill.value * 0.667
            -- at level 5 your bonus is 3.335
            -- at level 25 your bonus is 16.67
            -- at level 75 your bonus is 50.02
        else
this.log:error(string.format("Couldn't access skill %s.", "Disarmament"))
        end
    end

    --- the party's skill with their own weapon + their skill with their assailant's weapon
    --- See "weaponChanceModifiers" table for more info.
    skill.own = skill.own - (skill.own * mods.own[weapons.own.type] * 0.01)
    -- maybe check for combat state or enemy detection, if the tgt party is unaware he is more vulnerable.
    skill.assailant = skill.assailant + (skill.assailant * mods.assailant[weapons.assailant.type] * 0.01)

    --- These chance modifiers add a small yet significant boost to each party's odds.
    p.Skill = (skill.own + skill.assailant) * 0.38

    --- Now we set up our luck bonuses. These are just like the <party>WeaponSkill modifiers.
    -- reward ppl leveling luck ;p
    p.LuckBonus = (math.random(-25.0,25.0) + p.Mobile.luck.current) / 2.15

    -- Put it all together
    p.Chance = (p.Skill + p.DisarmSkillBonus + p.LuckBonus) * 0.95

    return p
end

----------------------------------------

this.weaponType = {
    ["shortBladeOneHand"] = 0,
    ["longBladeOneHand"] = 1,
    ["longBladeTwoClose"] = 2,
    ["bluntOneHand"] = 3,
    ["bluntTwoClose"] = 4,
    ["bluntTwoWide"] = 5,
    ["spearTwoWide"] = 6,
    ["axeOneHand"] = 7,
    ["axeTwoHand"] = 8,
    ["marksmanBow"] = 9,
    ["marksmanCrossbow"] = 10,
    ["marksmanThrown"] = 11,
    ["arrow"] = 12,
    ["bolt"] = 13,
    ["handToHand"] = 14,
}

this.weaponClass = {
    [tes3.weaponType.shortBladeOneHand] = "shortBlade",
    [tes3.weaponType.longBladeOneHand]  = "longBlade",
    [tes3.weaponType.longBladeTwoClose] = "longBlade",
    [tes3.weaponType.bluntOneHand]      = "bluntWeapon",
    [tes3.weaponType.bluntTwoClose]     = "bluntWeapon",
    [tes3.weaponType.bluntTwoWide]      = "bluntWeapon",
    [tes3.weaponType.spearTwoWide]      = "spear",
    [tes3.weaponType.axeOneHand]        = "axe",
    [tes3.weaponType.axeTwoHand]        = "axe",
    [tes3.weaponType.marksmanBow]       = "marksman",
    [tes3.weaponType.marksmanCrossbow]  = "marksman",
    [tes3.weaponType.marksmanThrown]    = "marksman",
    [tes3.weaponType.arrow]             = "marksman",
    [tes3.weaponType.bolt]              = "marksman",
    [this.weaponType.handToHand]        = "fist",
}

this.skillMappings = this.weaponClass


----------------------------------------
--[[
    Weapon types' extra chance to be disarmed.
These are additional chance modifiers as percentages
since these are used in multiplication operations
we need to calc the value like this:
skill - (skill * mod * 0.01)

if an actor's weapon skill is 25.0
and the weapon's chance mod is 5.0
the actor's effective protection is 23.75

a range of +/- 7% should be balanced enough
]]--
this.weaponChanceModifiers = {
    [this.weaponType.shortBladeOneHand] = -5.5,
    [this.weaponType.longBladeOneHand] = 0.0,
    [this.weaponType.longBladeTwoClose] = 0.5,
    [this.weaponType.bluntOneHand] = 2.0,
    [this.weaponType.bluntTwoClose] = 2.0,
    [this.weaponType.bluntTwoWide] = 2.0,
    [this.weaponType.spearTwoWide] = -5.5,
    [this.weaponType.axeOneHand] = -2.0,
    [this.weaponType.axeTwoHand] = 5.5,
    [this.weaponType.marksmanBow] = -7.0,
    [this.weaponType.marksmanCrossbow] = 7.0,
    [this.weaponType.marksmanThrown] = -6.5,
    [this.weaponType.arrow] = 0.0,
    [this.weaponType.bolt] = 0.0,
    [this.weaponType.handToHand] = 0.0,
}
-- The weapon's natural quality for disarming a target:
-- very rough napkin scheme
-- keeping in mind a heavy 2h axe can stagger the party with just a dagger
this.weaponChanceModifiersAttack = {
    [this.weaponType.shortBladeOneHand] = 1.0,
    [this.weaponType.longBladeOneHand] = 2.0,
    [this.weaponType.longBladeTwoClose] = 5.0,
    [this.weaponType.bluntOneHand] = 1.0,
    [this.weaponType.bluntTwoClose] = 2.0,
    [this.weaponType.bluntTwoWide] = 2.0,
    [this.weaponType.spearTwoWide] = 1.0,
    [this.weaponType.axeOneHand] = 1.0,
    [this.weaponType.axeTwoHand] = 7.0,
    [this.weaponType.marksmanBow] = 1.0,
    [this.weaponType.marksmanCrossbow] = 5.0,
    [this.weaponType.marksmanThrown] = 1.0,
    [this.weaponType.arrow] = 1.0,
    [this.weaponType.bolt] = 1.0,
    [this.weaponType.handToHand] = 1.0,
}

----------------------------------------

this.weaponTypeBlacklist = {
    [tes3.weaponType.shortBladeOneHand] = false,
    [tes3.weaponType.longBladeOneHand] = false,
    [tes3.weaponType.longBladeTwoClose] = false,
    [tes3.weaponType.bluntOneHand] = false,
    [tes3.weaponType.bluntTwoClose] = false,
    [tes3.weaponType.bluntTwoWide] = false,
    [tes3.weaponType.spearTwoWide] = false,
    [tes3.weaponType.axeOneHand] = false,
    [tes3.weaponType.axeTwoHand] = false,
    [tes3.weaponType.marksmanBow] = false,
    [tes3.weaponType.marksmanCrossbow] = false,
    [tes3.weaponType.marksmanThrown] = false,
    [tes3.weaponType.arrow] = false,
    [tes3.weaponType.bolt] = false,
    [this.weaponType.handToHand] = false,
}

----------------------------------------


return this