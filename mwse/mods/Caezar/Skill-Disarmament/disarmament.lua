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

    local attackerIsPlayer
    local targetIsPlayer

    if (attackerMobile == tes3.mobilePlayer) then
        attackerIsPlayer = true
        targetIsPlayer = false
    elseif (targetMobile == tes3.mobilePlayer) then
        targetIsPlayer = true
        attackerIsPlayer = false
    end

    local attackerMobile = e.mobile
    local targetMobile = e.targetMobile
    local speed = 0
    local targetSpeed = 0

    local attackerHasWeapon = true
    local attackerWeapon
    local attackerWeaponType
    local attackerSkill
    if (attackerMobile.readiedWeapon == nil) then
        attackerHasWeapon = false
        attackerWeapon = nil
        attackerWeaponType = common.weaponType.handToHand
        attackerSkill = attackerMobile.handToHand.current
        speed = 1
    else
        if (common.weaponTypeBlacklist[attackerWeaponType]) then
            return
        end
        attackerWeapon = attackerMobile.readiedWeapon
        attackerWeaponType = attackerWeapon.object.type
        attackerSkill = attackerMobile[common.skillMappings[attackerWeaponType]].current
        speed = attackerWeapon.object.speed
    end

    local targetHasWeapon = true
    local targetWeapon
    local targetWeaponType
    local targetSkill
    if (e.targetMobile.readiedWeapon == nil) then
        -- if (attackerHasWeapon == false) then
            -- return --- h2h vs. h2h
        -- end
        targetHasWeapon = false
        targetWeapon = nil
        targetWeaponType = common.weaponType.handToHand
        targetSkill = targetMobile.handToHand.current
        targetSpeed = 1
    else
        targetWeapon = targetMobile.readiedWeapon
        targetWeaponType = targetWeapon and targetWeapon.object.type
        targetSkill = targetMobile[common.skillMappings[targetWeaponType]].current
        targetSpeed = targetWeapon.object.speed
    end


    -- the original blacklist prevents archery/marksman weapon
    -- if (common.weaponTypeBlacklist_disarmToInventory[targetWeaponType]) then
        -- return
    -- end

    local attackerDisarmSkillBonus = 0
    local targetDisarmSkillBonus = 0

    if (attackerMobile == tes3.mobilePlayer) then
        if common.skill ~= nil then
            attackerDisarmSkillBonus = common.skill.value * 0.667
            -- at level 5 your bonus is 3.335
            -- at level 25 your bonus is 16.67
            -- at level 75 your bonus is 50.02
        else
common.logDebug(string.format("Couldn't access skill %s.", "Disarmament"))
        end
    elseif (targetMobile == tes3.mobilePlayer) then
        if common.skill ~= nil then
            targetDisarmSkillBonus = common.skill.value * 0.667
        else
common.logDebug(string.format("Couldn't access skill %s.", "Disarmament"))
        end
    end

    -- attacker --- --------------------
    --- the attacker's skill with their own weapon + their skill with the target's weapon
    --- See "common.lua" for more info.
    attackerSkill = attackerSkill - (attackerSkill * common.targetWeaponChanceModifiers[attackerWeaponType] * 0.01)
    local attackerWeaponSkill_ownWeapon = attackerSkill

    local attackerWeaponSkill_assailant
    if (targetHasWeapon) then
        attackerWeaponSkill_assailant = attackerMobile[common.skillMappings[targetWeaponType]].current
    else
        attackerWeaponSkill_assailant = attackerMobile.handToHand.current
    end
    -- Attackers dealing with their targets weapons:
    --  bonus from attacker's own skill (or knowledge) with the target's weapon
    --  and the weapons intrinsic character for being disarmed, being that the weapon is held by the target.
    attackerWeaponSkill_assailant = attackerWeaponSkill_assailant + (attackerWeaponSkill_assailant * common.weaponChanceModifiers[targetWeaponType] * 0.01)

    -- target --- ----------------------
    --- the target's skill with their own weapon + their skill with the attacker's weapon
    targetSkill = targetSkill - (targetSkill * common.weaponChanceModifiers[targetWeaponType] * 0.01)
    local targetWeaponSkill_ownWeapon = targetSkill

    local targetWeaponSkill_assailant
    if (attackerHasWeapon) then
        targetWeaponSkill_assailant = targetMobile[common.skillMappings[attackerWeaponType]].current
    else
        targetWeaponSkill_assailant = targetMobile.handToHand.current
    end
    -- Targets dealing with their attackers weapons:
    --  target's own skill with the attacker's weapon
    --  and the attacker's weapons character for disarming targets, being that the weapon is held by the attacker.
    targetWeaponSkill_assailant = targetWeaponSkill_assailant - (targetWeaponSkill_assailant * common.targetWeaponChanceModifiers[attackerWeaponType] * 0.01)

    --- These chance modifiers add a small yet significant boost to each party's odds.
    local attackerWeaponSkill = (attackerWeaponSkill_ownWeapon + attackerWeaponSkill_assailant) * 0.38
    local targetWeaponSkill = (targetWeaponSkill_ownWeapon + targetWeaponSkill_assailant) * 0.38

    --- Now we set up our luck bonuses. These are just like the <party>WeaponSkill modifiers.
    -- The attacker's luck bonus
    local attackerLuckBonus = math.random(math.random(-3.0,-18.0),math.random(3.0,18.0)) + (attackerMobile.luck.current * 1.0)
    attackerLuckBonus = attackerLuckBonus * 0.25
    -- with 35 luck the bonus is 7.35

    -- The target's luck bonus
    local targetLuckBonus = math.random(math.random(-3.0,-18.0),math.random(3.0,18.0)) + (targetMobile.luck.current * 1.0)
    targetLuckBonus = targetLuckBonus * 0.25

    -- Put it all together
    local attackerChance = (attackerSkill + attackerDisarmSkillBonus + attackerLuckBonus + attackerWeaponSkill) * 0.95
    local targetChance = ( targetSkill +  targetDisarmSkillBonus +  targetLuckBonus + targetWeaponSkill) * 0.95

    -- Base chance of 5% used for example below.
    local baseChance = config.disarmamentBaseChance or 5.0
    -- Skill ration based on attacker vs target skill levels.
    -- Ex: Target with 100 long blade vs Attacker with 25 axe = 4.0 ratio.

    local skillRatio = (attackerChance) / (targetChance) * 1.0


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

    attackerIsPlayer = false
    targetIsPlayer = false
    if (attackerMobile == tes3.mobilePlayer) then
        attackerIsPlayer = true
    else
        targetIsPlayer = true
    end

    if (config.enableGodMode) then
        if (attackerIsPlayer) then
            chance = 100
        else
            chance = 0
        end
    end

common.logDebug(string.format("--- CURRENT STATE ---\n\t[God mode is %s! player is %s!]\n\t[Overall Judgement] Ratio: %s, Disarm Chance: %s\n\t[Attacker Stats] Weapon Skill: %s, Disarm Chance: %s, Skill-Disarm Bonus: %s, Luck Bonus: %s\n\t[Target Stats] Weapon Skill: %s, Block Chance: %s, Skill-Disarm Bonus: %s, Luck Bonus: %s\n\t[Attacker: Weapon Skill stats] own weapon class: %s, own weapon: %s, enemy's weapon class: %s, enemy's weapon: %s\n\t[Target: Weapon Skill stats] own weapon class: %s, own weapon: %s, enemy's weapon class: %s, enemy's weapon: %s", common.__yesno_enabled[config.enableGodMode], common.__yesno_attacking[attackerIsPlayer], skillRatio, chance, attackerWeaponSkill, attackerChance, attackerDisarmSkillBonus, attackerLuckBonus, targetWeaponSkill, targetChance, targetDisarmSkillBonus, targetLuckBonus, common.weaponClass[attackerWeaponType], attackerWeaponSkill_ownWeapon, common.weaponClass[targetWeaponType], attackerWeaponSkill_assailant, common.weaponClass[targetWeaponType], targetWeaponSkill_ownWeapon, common.weaponClass[attackerWeaponType], targetWeaponSkill_assailant))

    if (math.random(100) > chance) then
        return
    end

    -- We hit someone!
    -- local duration = 2 * speed
    speed = (speed + targetSpeed) / 3
    local duration = speed
    timer.start({
        duration = duration,
        callback = function()
            disarm(attackerMobile, targetMobile, attackerHasWeapon)
        end
    })
end
event.register("attack", onAttack)