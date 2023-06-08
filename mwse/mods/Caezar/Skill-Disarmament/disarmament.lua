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

    if (weapon == nil) then
        -- same concept. it drops their weapon to the ground.
        if (targetMobile.fatigue.current >= 0.0) then
            targetMobile.fatigue.current = 0.0
        else
            targetMobile.fatigue.current = targetMobile.fatigue.current - 100.0
        end
        targetMobile.fatigue.current = targetMobile.fatigue.current - 100.0
        return
    end

    local weaponObject = weapon.object
    local weaponItemData = weapon.itemData

    local attackerLuckBonus = math.random(-20.0,20.0) + (attackerMobile.luck.current)
    local targetLuckBonus = math.random(-20.0,20.0) + (targetMobile.luck.current)
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

common.logDebug(string.format("[Luck Stats] randombit: %s, randomhalf: %s, luckModifier: %s", randombit, randomhalf, luckModifier))
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
    local weapon = targetMobile.readiedWeapon

    if (weapon == nil) then
        if (targetMobile.fatigue.current >= 0.0) then
            targetMobile.fatigue.current = 0.0
        else
            -- double if they're already down
            targetMobile.fatigue.current = targetMobile.fatigue.current - 100.0
        end
        targetMobile.fatigue.current = targetMobile.fatigue.current - 100.0
        return
    end

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

local function disarm(attackerMobile, targetMobile, attackerHasWeapon)
    if (attackerHasWeapon) then
        disarmWeapon(targetMobile)
    else
        disarmHandToHand(attackerMobile, targetMobile)
    end

    -- Progress skill
    if (attackerMobile == tes3.mobilePlayer) then
        common.skill:progressSkill(config.skillDisarmament_ProgressExp or 10)
        common.logDebug(string.format("Skill progression! (current: %s)", common.skill.progress))
    end
end

local function onAttack(e)
    if (config.enableDisarmament == false) then
        return
    end

    -- Ignore swings with no target.
    if (e.targetReference == nil) then
        return
    end

    -- Ignore proximity bounds for marksman weapons
    if (common.weaponClass[attackerWeaponType] ~= "marksman") then
        if (e.targetReference.position:distance(e.reference.position) > config.disarmamentSearchDistance) then
            return
        end
    end

    -- uncomment to prevent creatures from disarming the player
    if (e.mobile.actorType == tes3.actorType.creature) then
        return
    end

    if (e.targetMobile.actorType == tes3.actorType.creature) then
        return
    end

    local atk = common.new_disarmParty(e.mobile)
    local tgt = common.new_disarmParty(e.targetMobile)

    -- the original blacklist prevents archery/marksman weapon
    -- if (common.weaponTypeBlacklist_disarmToInventory[targetWeaponType]) then
        -- return
    -- end

    -- attacker --- --------------------
    --- the attacker's skill with their own weapon + their skill with the target's weapon
    --- See "common.lua" for more info.
    atk.Skill = atk.Skill - (atk.Skill * common.weaponChanceModifiersAttack[atk.WeaponType] * 0.01)
    atk.WeaponSkill_ownWeapon = atk.Skill

    if (targetHasWeapon) then
        atk.WeaponSkill_assailant = atk.Mobile[common.skillMappings[tgt.WeaponType]].current
    else
        atk.WeaponSkill_assailant = atk.Mobile.handToHand.current
    end
    -- Attackers dealing with their targets weapons:
    --  bonus from atk.'s own skill (or knowledge) with the target's weapon
    --  and the weapons intrinsic character for being disarmed, being that the weapon is held by the target.
    atk.WeaponSkill_assailant = atk.WeaponSkill_assailant + (atk.WeaponSkill_assailant * common.weaponChanceModifiers[tgt.WeaponType] * 0.01)

    -- target --- ----------------------
    --- the target's skill with their own weapon + their skill with the attacker's weapon
    tgt.Skill = tgt.Skill - (tgt.Skill * common.weaponChanceModifiers[tgt.WeaponType] * 0.01)
    tgt.WeaponSkill_ownWeapon = tgt.Skill

    if (attackerHasWeapon) then
        tgt.WeaponSkill_assailant = tgt.Mobile[common.skillMappings[atk.WeaponType]].current
    else
        tgt.WeaponSkill_assailant = tgt.Mobile.handToHand.current
    end
    -- Targets dealing with their attackers weapons:
    --  tgt.'s own skill with the attacker's weapon
    --  and the attacker's weapons character for disarming tgt.s, being that the weapon is held by the attacker.
    tgt.WeaponSkill_assailant = tgt.WeaponSkill_assailant - (tgt.WeaponSkill_assailant * common.weaponChanceModifiersAttack[atk.WeaponType] * 0.01)

    --- These chance modifiers add a small yet significant boost to each party's odds.
    atk.WeaponSkill = (atk.WeaponSkill_ownWeapon + atk.WeaponSkill_assailant) * 0.38
    tgt.WeaponSkill = (tgt.WeaponSkill_ownWeapon + tgt.WeaponSkill_assailant) * 0.38

    --- Now we set up our luck bonuses. These are just like the <party>WeaponSkill modifiers.
    atk.LuckBonus = (math.random(math.random(-3.0,-18.0),math.random(3.0,18.0)) + (atk.Mobile.luck.current * 1.0)) / 3
    tgt.LuckBonus = (math.random(math.random(-3.0,-18.0),math.random(3.0,18.0)) + (tgt.Mobile.luck.current * 1.0)) / 3

    -- Put it all together
    atk.Chance = (atk.Skill + atk.DisarmSkillBonus + atk.LuckBonus + atk.WeaponSkill) * 0.95
    tgt.Chance = (tgt.Skill + tgt.DisarmSkillBonus + tgt.LuckBonus + tgt.WeaponSkill) * 0.95

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

common.logDebug(string.format("--- CURRENT STATE ---\n\t[God mode is %s! player is %s!]\n\t[Overall Judgement] Ratio: %s, Disarm Chance: %s\n\t[Attacker Stats] Weapon Skill: %s, Weap speed: %s, Disarm Chance: %s, Skill-Disarm Bonus: %s, Luck Bonus: %s\n\t[Target Stats] Weapon Skill: %s, Weap speed: %s, Block Chance: %s, Skill-Disarm Bonus: %s, Luck Bonus: %s\n\t[Attacker: Weapon Skill stats] own weapon class: %s, own weapon: %s, enemy's weapon class: %s, enemy's weapon: %s\n\t[Target: Weapon Skill stats] own weapon class: %s, own weapon: %s, enemy's weapon class: %s, enemy's weapon: %s", common.__yesno_enabled[config.enableGodMode], common.__yesno_attacking[atk.isPlayer], skillRatio, chance, atk.WeaponSkill, atk.Speed, atk.Chance, atk.DisarmSkillBonus, atk.LuckBonus, tgt.WeaponSkill, tgt.Speed, tgt.Chance, tgt.DisarmSkillBonus, tgt.LuckBonus, common.weaponClass[atk.WeaponType], atk.WeaponSkill_ownWeapon, common.weaponClass[tgt.WeaponType], atk.WeaponSkill_assailant, common.weaponClass[tgt.WeaponType], tgt.WeaponSkill_ownWeapon, common.weaponClass[atk.WeaponType], tgt.WeaponSkill_assailant))

    if (math.random(100) > chance) then
        return
    end

    -- We hit someone!
    -- local duration = 2 * speed
    local duration = (atk.Speed + tgt.Speed) / 3
    timer.start({
        duration = duration,
        callback = function()
            disarm(atk.Mobile, tgt.Mobile, atk.HasWeapon)
        end
    })
end
event.register("attack", onAttack)