local common = require("Caezar.Skill-Disarmament.common")
local config = require("Caezar.Skill-Disarmament.config")

----------------------------------------

local function getOrientation()
    local x = math.rad(math.random(75, 100))
    local y = math.rad(math.random(0, 360))
    local z = math.rad(math.random(0, 15))
    if (math.random() > 0.5) then
        z = math.rad(math.random(350, 360))
    end
    return tes3vector3.new(x,y,z)
end

local function getRandomizedPosition(position, isShort)
    local x = math.random(position.x - 20, position.x + 20)
    local y = math.random(position.y - 20, position.y + 20)
    local z = math.random(position.z + 25, position.z + 40)
    if (isShort == true) then
        z = math.random(position.z + 5, position.z + 10)
    end
    return tes3vector3.new(x,y,z)
end

local function disarmHandToHand(attackerMobile, targetMobile, weapons)
    local weaponObject = weapons.id.object
    local weaponItemData = weapons.id.itemData

    local attackerLuckBonus = math.random(-20,20) + (attackerMobile.luck.current)
    local targetLuckBonus = math.random(-20,20) + (targetMobile.luck.current)
    local luckModifier = attackerLuckBonus - targetLuckBonus

    local randombit = bit.band(math.random(100),1)
    local randomhalf = math.random(512)

    if (luckModifier > randomhalf) then
        randomhalf = 0
        if (randombit == 0 and (attackerLuckBonus > 45)) then
            -- lucky 2nd chance
            randombit = bit.band(math.random(100),1)
        end
    else
        randomhalf = randomhalf - luckModifier
    end

common.log:debug("[Luck Stats] randombit: %s, randomhalf: %s, luckModifier: %s", randombit, randomhalf, luckModifier)
    --- decide to take the weapon using luck, we are still disarming so
    --- if this falls through, the weapon will just fall to the ground
    if (randombit == 1 and randomhalf <= 255) then
        -- Add reference to target.
        tes3.addItem({
            reference = attackerMobile,
            item = weaponObject,
            itemData = weaponItemData,
            count = 1,
            playSound = false
        })
    else
        local isShortWeapon = false
        if (weapons.object.type == tes3.weaponType.shortBladeOneHand) then
            isShortWeapon = true
        end
        -- Spawn reference nearby.
        local ref = tes3.createReference({
            object  = weaponObject,
            position = getRandomizedPosition(targetMobile.reference.position, isShortWeapon),
            orientation  = getOrientation(),
            cell  = targetMobile.reference.cell,
        })
        ref.itemData = weaponItemData
    end

    targetMobile:unequip(weaponObject)

    -- Remove weapon.
    tes3.removeItem({
        reference = targetMobile,
        item = weaponObject,
        itemData = weaponItemData,
        count = 1,
        playSound = false
    })

    -- Redraw equipment.
    if (attackerMobile ~= tes3.mobilePlayer) then
        attackerMobile.reference:updateEquipment()
    end
    if (targetMobile ~= tes3.mobilePlayer) then
        targetMobile.reference:updateEquipment()
    end
end

local function disarmWeapon(targetMobile, weapons)
    local weaponObject = weapons.id.object
    local weaponItemData = weapons.id.itemData

    local isShortWeapon = false
    if (weapons.type == tes3.weaponType.shortBladeOneHand) then
        isShortWeapon = true
    end

    -- Spawn reference nearby.
    local ref = tes3.createReference({
        object  = weaponObject,
        position = getRandomizedPosition(targetMobile.reference.position, isShortWeapon),
        orientation  = getOrientation(),
        cell  = targetMobile.reference.cell,
    })
    ref.itemData = weaponItemData

    targetMobile:unequip(weaponObject)

    -- Remove weapon.
    tes3.removeItem({
        reference = targetMobile,
        item = weaponObject,
        itemData = weaponItemData,
        count = 1,
        playSound = false,
        deleteItemData = false,
    })

    -- Redraw equipment.
    if (targetMobile ~= tes3.mobilePlayer) then
        targetMobile.reference:updateEquipment()
    end
end

local function disarm(atk, tgt, weapons)
    if (weapons.tgt.has == false) then
        if (tgt.Mobile.fatigue.current > 0.0) then
            tgt.Mobile.fatigue.current = -150.0
        else
            tgt.Mobile.fatigue.current = tgt.Mobile.fatigue.current - 150.0
        end
common.log:debug("[disarm - h2h] target's current fatigue: %s", tgt.Mobile.fatigue.current)
    elseif (weapons.atk.has) then
        disarmWeapon(tgt.Mobile, weapons.tgt)
common.log:debug("[disarm - weapon] target's current weapon: %s", tostring(weapons.tgt.id))
    else
        disarmHandToHand(atk.Mobile, tgt.Mobile, weapons.tgt)
common.log:debug("[disarm - weapon] target's current weapon: %s", tostring(weapons.tgt.id))
    end

    -- Progress skill
    if (atk.isPlayer) then
        common.skill:progressSkill(10)
common.log:debug("Skill progression! (current: %s)", common.skill.progress)
    end
end

local function onAttack(e)
    if (config.enableDisarmament == false) then
        return

    -- Ignore swings with no target.
    elseif (e.targetReference == nil) then
        return

    -- Uncomment to prevent creatures from disarming the player
    elseif (e.mobile.actorType == tes3.actorType.creature) then
        return

    elseif (e.targetMobile.actorType == tes3.actorType.creature) then
        return
    end

    -- Setup our structs
    local mods = {
        atk = common.weaponChanceModifiersAttack,
        tgt = common.weaponChanceModifiers,
    }

    local weapons = {
        atk = common.getWeapons(e.mobile),
        tgt = common.getWeapons(e.targetMobile),
    }

    local atk = common.new_disarmParty(e.mobile, { own = mods.atk, assailant = mods.tgt }, { own = weapons.atk, assailant = weapons.tgt })
    local tgt = common.new_disarmParty(e.targetMobile, { own = mods.tgt, assailant = mods.atk }, { own = weapons.tgt, assailant = weapons.atk })
    if (not atk or not tgt) then return --[[ throw error ]] end

    -- Ignore proximity bounds for marksman weapons
    if (common.weaponClass[weapons.atk.type] ~= "marksman") then
        if (e.targetReference.position:distance(e.reference.position) > config.disarmamentSearchDistance) then
            return
        end
    end

    -- blacklist class of weapon
    -- if (common.weaponClass[weapons.atk.type]) then
        -- return
    -- end

    -- Base chance of 5% used for example below.
    local baseChance = config.disarmamentBaseChance or 5.0
    -- Skill ration based on attacker vs target skill levels.
    -- Ex: Target with 100 long blade vs Attacker with 25 axe = 4.0 ratio.

    local skillRatio = (atk.Chance) / (tgt.Chance) * 1.0


    -- Calculate modified base chance of disarm. 5% * 4.0 = 20% chance. Possible scenarios:
    -- Attacker | Target | Ratio | Chance
    -- 100    | 5        | 20    | 100
    -- 75     | 25       | 3     | 15
    -- 50     | 50       | 1     | 5
    -- 25     | 75       | .33   | 5 * .33 ~= 1
    -- 20     | 100      | .2    | 1
    local modifiedBaseChance = math.floor(baseChance * skillRatio)

    -- Calculate chance. Caps at 60%.
    local chance = math.min(modifiedBaseChance, config.disarmamentMaxChance or 50.0)

    if (atk.isGod == true) then
        chance = 100
    elseif (tgt.isGod == true) then
        chance = 0
    end

common.log:debug("--- CURRENT STATE ---\t[God mode is %s! player is %s!]\t[Overall Judgement] Ratio: %s, Disarm Chance: %s", common.__yesno_enabled[config.enableGodMode], common.__yesno_attacking[atk.isPlayer], skillRatio, chance)

    if (math.random(100) > chance) then
        return
    end

    local atkMobile = tes3.makeSafeObjectHandle(atk.Mobile)
    local tgtMobile = tes3.makeSafeObjectHandle(tgt.Mobile)
    if (not atkMobile:valid() or not tgtMobile:valid()) then
common.log:error("invalid handle")
        return
    end

    -- We hit someone!
    -- local duration = 2 * speed
    -- timer.start({
        -- duration = duration,
        -- callback = function()
            disarm(atk, tgt, weapons)
        -- end
    -- })

end
event.register("attack", onAttack)