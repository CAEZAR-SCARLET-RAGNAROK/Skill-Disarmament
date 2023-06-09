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

local function disarmHandToHand(attackerMobile, targetMobile)
    local weapon = targetMobile.readiedWeapon

    local weaponObject = weapon.object
    local weaponItemData = weapon.itemData

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

common.log:debug(string.format("[Luck Stats] randombit: %s, randomhalf: %s, luckModifier: %s", randombit, randomhalf, luckModifier))
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
        if (weapon.object.type == tes3.weaponType.shortBladeOneHand) then
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

local function disarmWeapon(targetMobile)
    local weaponObject = weapon.object
    local weaponItemData = weapon.itemData
    local isShortWeapon = false
    if (weapon.object.type == tes3.weaponType.shortBladeOneHand) then
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

local function disarm(atk, tgt)
    if (tgt.Mobile.readiedWeapon == nil) then
        if (tgt.Mobile.fatigue.current >= 0.0) then
            tgt.Mobile.fatigue.current = 0.0
        else
            -- double if they're already down
            tgt.Mobile.fatigue.current = tgt.Mobile.fatigue.current - 100.0
        end
        tgt.Mobile.fatigue.current = tgt.Mobile.fatigue.current - 100.0
    elseif (atk.HasWeapon) then
        disarmWeapon(tgt.Mobile)
    else
        disarmHandToHand(atk.Mobile, tgt.Mobile)
    end

    -- Progress skill
    if (atk.Mobile == tes3.mobilePlayer) then
        common.skill:progressSkill(config.skillDisarmament_ProgressExp or 10)
        common.wlog("DEBUG",string.format("Skill progression! (current: %s)", common.skill.progress))
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
    if (common.weaponClass[atk.WeaponType] ~= "marksman") then
        if (e.targetReference.position:distance(e.reference.position) > config.disarmamentSearchDistance) then
            return
        end
    end

    -- the original blacklist prevents archery/marksman weapon
    -- if (common.weaponTypeBlacklist[atk.WeaponType]) then
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

-- common.wlog("DEBUG",string.format("--- CURRENT STATE ---\n\t[God mode is %s! player is %s!]\n\t[Overall Judgement] Ratio: %s, Disarm Chance: %s\n\t[Attacker Stats] Weapon Skill: %s, Weap speed: %s, Disarm Chance: %s, Skill-Disarm Bonus: %s, Luck Bonus: %s\n\t[Target Stats] Weapon Skill: %s, Weap speed: %s, Block Chance: %s, Skill-Disarm Bonus: %s, Luck Bonus: %s\n\t[Attacker: Weapon Skill stats] own weapon class: %s, own weapon: %s, enemy's weapon class: %s, enemy's weapon: %s\n\t[Target: Weapon Skill stats] own weapon class: %s, own weapon: %s, enemy's weapon class: %s, enemy's weapon: %s", common.__yesno_enabled[config.enableGodMode], common.__yesno_attacking[atk.isPlayer], skillRatio, chance, atk.WeaponSkill, weapons.atk.speed, atk.Chance, atk.DisarmSkillBonus, atk.LuckBonus, tgt.WeaponSkill, weapons.tgt.speed, tgt.Chance, tgt.DisarmSkillBonus, tgt.LuckBonus, common.weaponClass[atk.WeaponType], atk.WeaponSkill_ownWeapon, common.weaponClass[tgt.WeaponType], atk.WeaponSkill_assailant, common.weaponClass[tgt.WeaponType], tgt.WeaponSkill_ownWeapon, common.weaponClass[atk.WeaponType], tgt.WeaponSkill_assailant))
common.wlog("DEBUG",string.format("--- CURRENT STATE ---\t[God mode is %s! player is %s!]\t[Overall Judgement] Ratio: %s, Disarm Chance: %s", common.__yesno_enabled[config.enableGodMode], common.__yesno_attacking[atk.isPlayer], skillRatio, chance))

    if (math.random(100) > chance) then
        return
    end

    -- atk.Mobile = tes3.makeSafeObjectHandle(atk.Mobile)
    -- tgt.Mobile = tes3.makeSafeObjectHandle(tgt.Mobile)

    if (atk.Mobile:valid() == true and tgt.Mobile:valid() == true) then

        -- We hit someone!
        -- local duration = 2 * speed
        local duration = (2 * weapons.atk.speed) * 0.667
        timer.start({
            duration = duration,
            callback = function()
                disarm(atk, tgt)
            end
        })

    else
        -- throw error
        common.log:error("invalid handle")
        return
    end
end
event.register("attack", onAttack)