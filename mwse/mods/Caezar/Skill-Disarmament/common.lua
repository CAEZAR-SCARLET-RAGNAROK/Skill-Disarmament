local config = require("Caezar.Skill-Disarmament.config")

local this = {}

----------------------------------------
this.__yesno = {
	[true] = "Yes",
	[false] = "No",
}
this.__yesno_playerattacking = {
	[true] = "attacking",
	[false] = "defending",
}
this.__yesno_enabled = {
	[true] = "Enabled",
	[false] = "Disabled",
}

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
	["shortBladeOneHand"]	= "shortBlade",
	["longBladeOneHand"]	= "longBlade",
	["longBladeTwoClose"]	= "longBlade",
	["bluntOneHand"]		= "bluntWeapon",
	["bluntTwoClose"]		= "bluntWeapon",
	["bluntTwoWide"]		= "bluntWeapon",
	["spearTwoWide"]		= "spear",
	["axeOneHand"]			= "axe",
	["axeTwoHand"]			= "axe",
	["marksmanBow"]			= "marksman",
	["marksmanCrossbow"]	= "marksman",
	["marksmanThrown"]		= "marksman",
	["arrow"]				= "marksman",
	["bolt"]				= "marksman",
	["handToHand"]			= "fists",
}

----------------------------------------

this.skillMappings = {
    [tes3.weaponType.shortBladeOneHand]	= "shortBlade",
    [tes3.weaponType.longBladeOneHand]	= "longBlade",
    [tes3.weaponType.longBladeTwoClose]	= "longBlade",
    [tes3.weaponType.bluntOneHand]		= "bluntWeapon",
    [tes3.weaponType.bluntTwoClose]		= "bluntWeapon",
    [tes3.weaponType.bluntTwoWide]		= "bluntWeapon",
    [tes3.weaponType.spearTwoWide]		= "spear",
    [tes3.weaponType.axeOneHand]		= "axe",
    [tes3.weaponType.axeTwoHand]		= "axe",
    [tes3.weaponType.marksmanBow]		= "marksman",
    [tes3.weaponType.marksmanCrossbow]	= "marksman",
    [tes3.weaponType.marksmanThrown]	= "marksman",
    [tes3.weaponType.arrow]				= "marksman",
    [tes3.weaponType.bolt]				= "marksman",
    [this.weaponType.handToHand]		= "fists",
}
this.skillMappingsExtended = {
    [this.weaponType.shortBladeOneHand]	= "shortBladeOneHand",
    [this.weaponType.longBladeOneHand]	= "longBladeOneHand",
    [this.weaponType.longBladeTwoClose]	= "longBladeTwoClose",
    [this.weaponType.bluntOneHand]		= "bluntOneHand",
    [this.weaponType.bluntTwoClose]		= "bluntTwoClose",
    [this.weaponType.bluntTwoWide]		= "bluntTwoWide",
    [this.weaponType.spearTwoWide]		= "spearTwoWide",
    [this.weaponType.axeOneHand]		= "axeOneHand",
    [this.weaponType.axeTwoHand]		= "axeTwoHand",
    [this.weaponType.marksmanBow]		= "marksmanBow",
    [this.weaponType.marksmanCrossbow]	= "marksmanCrossbow",
    [this.weaponType.marksmanThrown]	= "marksmanThrown",
    [this.weaponType.arrow]				= "arrow",
    [this.weaponType.bolt]				= "bolt",
    [this.weaponType.handToHand]		= "handToHand",
}

----------------------------------------

this.weaponChanceModifiers = { --[[
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
	[this.weaponType.shortBladeOneHand] = -5.5,
	[this.weaponType.longBladeOneHand] = 0.01,
	[this.weaponType.longBladeTwoClose] = 2.0,
	[this.weaponType.bluntOneHand] = 2.0,
	[this.weaponType.bluntTwoClose] = 2.0,
	[this.weaponType.bluntTwoWide] = 2.0,
	[this.weaponType.spearTwoWide] = -5.5,
	[this.weaponType.axeOneHand] = -2.0,
	[this.weaponType.axeTwoHand] = 5.5,
	[this.weaponType.marksmanBow] = -7.0,
	[this.weaponType.marksmanCrossbow] = 7.0,
	[this.weaponType.marksmanThrown] = -6.5,
	[this.weaponType.arrow] = 0.01,
	[this.weaponType.bolt] = 0.01,
	[this.weaponType.handToHand] = 0.01,
}

----------------------------------------

this.weaponType_disarmToEnvironment = {
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
    [this.weaponType.handToHand] = true,
}
this.weaponType_disarmToInventory = {
    [tes3.weaponType.shortBladeOneHand] = false,
    [tes3.weaponType.longBladeOneHand] = false,
    [tes3.weaponType.longBladeTwoClose] = false,
    [tes3.weaponType.bluntOneHand] = false,
    [tes3.weaponType.bluntTwoClose] = false,
    [tes3.weaponType.bluntTwoWide] = false,
    [tes3.weaponType.spearTwoWide] = false,
    [tes3.weaponType.axeOneHand] = false,
    [tes3.weaponType.axeTwoHand] = false,
    [tes3.weaponType.marksmanBow] = true,
    [tes3.weaponType.marksmanCrossbow] = true,
    [tes3.weaponType.marksmanThrown] = true,
    [tes3.weaponType.arrow] = true,
    [tes3.weaponType.bolt] = true,
    [this.weaponType.handToHand] = true,
}
this.weaponTypeBlacklist = {
    [tes3.weaponType.shortBladeOneHand] = true,
    [tes3.weaponType.longBladeOneHand] = true,
    [tes3.weaponType.longBladeTwoClose] = true,
    [tes3.weaponType.bluntOneHand] = true,
    [tes3.weaponType.bluntTwoClose] = true,
    [tes3.weaponType.bluntTwoWide] = true,
    [tes3.weaponType.spearTwoWide] = true,
    [tes3.weaponType.axeOneHand] = true,
    [tes3.weaponType.axeTwoHand] = true,
    [tes3.weaponType.marksmanBow] = true,
    [tes3.weaponType.marksmanCrossbow] = true,
    [tes3.weaponType.marksmanThrown] = true,
    [tes3.weaponType.arrow] = true,
    [tes3.weaponType.bolt] = true,
    [this.weaponType.handToHand] = true,
}

return this