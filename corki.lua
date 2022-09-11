local Corki = { }
function Corki.Load()

    function Corki:Boot()
        --[[for _, hero in pairs(objManager.heroes.list) do
			for _, buff in pairs(hero.buffs) do
				if buff and buff.valid then
					print(buff.name)
                end
            end
        end--]]

        self.handle = self.networkId

        self.q = {
            delay = 0.25,
            speed = 1000,
            range = 825,
            type = spellType.circular,
            radius = 250,
            boundingRadiusMod = false,
            collision = 
            {
                hero = SpellCollisionType.Soft,
                minion = SpellCollisionType.Soft,
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
        }

        self.w = {
            delay = 0,
            speed = 650,
            range = 600,
            type = spellType.linear,
            boundingRadiusMod = true,
            width = 100
        }

        self.wMega = {
            delay = 0,
            speed = 1500,
            range = 1800,
            type = spellType.linear,
            boundingRadiusMod = true,
            width = 100
        }

        self.e = {
            delay = 0.25,
            speed = math.huge,
            range = 600,
            angle = 35,
            collision = false,
            type = spellType.cone,
            rangeType = 0,
            boundingRadiusMod = false
        }

        self.r = {
            delay = 0.175,
            speed = 1950,
            range = 1300,
            type = spellType.linear,
            boundingRadiusMod = true,
            width = 40
        }

        self.rMega = {
            delay = 0.175,
            speed = 1950,
            range = 1500,
            type = spellType.linear,
            boundingRadiusMod = true,
            width = 40
        }

        self.menu = self:CreateMenu()
        self.callbacks = { { }, { } }

        -- all credits to torben for this callback handler
        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Corki:OnTick(...) end)
        --table.insert(self.callbacks[1], cb.create)
        --table.insert(self.callbacks[2], function(...) Caitlyn:OnCreate(...) end)
        --table.insert(self.callbacks[1], cb.delete)
        --table.insert(self.callbacks[2], function(...) Caitlyn:OnDelete(...) end)
        table.insert(self.callbacks[1], cb.draw)
        table.insert(self.callbacks[2], function(...) Corki:OnDraw(...) end)
    end

    function Corki:CreateMenu()
        local mm = menu.create("JRC", "JRC Corki")

        mm:header("combo", "Combo")
        mm.combo:boolean("useq", "Use Q in Combo", true)
        mm.combo:boolean("usee", "Use E in Combo", true)
        mm.combo:boolean("user", "Use R in Combo", true)
        --mm.combo:boolean("weave", "Weave Sheen Autos", true)

        mm:header("harass", "Harass")
        mm.harass:boolean("useq", "Use Q in Harass", true)
        mm.harass:boolean("usee", "Use E in Harass", true)
        mm.harass:boolean("user", "Use R in Harass", true)

        mm:header("killsteal", "KillSteal")
        mm.killsteal:boolean("useq", "KillSteal With Q", true)
        mm.killsteal:boolean("user", "KillSteal With R", true)

        mm:header("draws", "Drawings")
        mm.draws:boolean("drawq", "Draw Q Range", true)
        mm.draws:boolean("draww", "Draw W Range", true)
        mm.draws:boolean("drawe", "Draw E Range", true)
        mm.draws:boolean("drawr", "Draw R Range", true)
        
        return mm
    end

    function Corki:CastQ()
        if player.isWindingUp then return end
        if player.canAttack == false then return end
        local target = ts.getInRange(self.q.range)
        if target and target:isValidTarget(self.q.range, true, player.pos) and player:spellSlot(SpellSlot.Q).state == 0 then
            if self.menu.combo.useq:get() then
                local prediction = pred.getPrediction(target, self.q)
                if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                   -- print("pred go brr")
                    player:castSpell(SpellSlot.Q, prediction.castPosition, false, false)
                    --print("casted")
                end
            end
        end
    end

    function Corki:CastE()
        local target = ts.getInRange(self.e.range)
        if target and target:isValidTarget(self.e.range, true, player.pos) and player:spellSlot(SpellSlot.E).state == 0 then
            if self.menu.combo.usee:get() then
                local prediction = pred.getPrediction(target, self.e)
                if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                    -- print("pred go brr")
                    player:castSpell(SpellSlot.E, false, false)
                     --print("casted")
                end
            end
        end
    end

    function Corki:CastR()
        if player.isWindingUp then return end
        if player.canAttack == false then return end
        --print(player:spellSlot(SpellSlot.R).castRange)
        local target = ts.getInRange(self.rMega.range)
        if target and target:isValidTarget(self.rMega.range, true, player.pos) and player:spellSlot(SpellSlot.R).state == 0 and player:findBuff("mbcheck2") then
            --print("big Rocket")
            local prediction = pred.getPrediction(target, self.rMega)
            if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                --print("pred go brr")
                player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                 --print("casted")
            end
        elseif target and target:isValidTarget(self.r.range, true, player.pos) and player:spellSlot(SpellSlot.R).state == 0 then
            --print("name")
            local prediction = pred.getPrediction(target, self.r)
            if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                --print("pred go brr")
                player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                 --print("casted")
            end
        end
    end

    function Corki:QDmg(target)
        local spell = player:spellSlot(SpellSlot.Q)
        if spell.level == 0 then return 0 end
        local damage = (75 + 45 * spell.level) + (player.totalBonusAttackDamage * 2.0) + (player.totalAbilityPower * 0.5)
        --print(damageLib.magical(player, target, damage))
        return damageLib.magical(player, target, damage)
    end

    function Corki:RDmg(target)
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return 0 end
        local damage = (80 + 35 * spell.level) + (player.totalAttackDamage * 0.15 + 0.30 * spell.level) + (player.totalAbilityPower * 0.12)
        return damageLib.magical(player, target, damage)
    end

    function Corki:RDmg2(target)
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return 0 end
        local damage = (160 + 70 * spell.level) + (player.totalAttackDamage * 0.30 + 0.60 * spell.level) + (player.totalAbilityPower * 0.24)
        return damageLib.magical(player, target, damage)
    end



    function Corki:Combo()
        Corki:CastQ()
        Corki:CastE()
        Corki:CastR()
    end

    function Corki:Harass()
        Corki:CastQ()
        Corki:CastR()
    end

    function Corki:KillSteal()
        for _, enemy in pairs(ts.getTargets()) do
            if enemy and enemy:isValidTarget(self.q.range, true, player.pos) and self.menu.killsteal.useq:get() then
                --print("valid")
                if player:spellSlot(SpellSlot.Q).state == 0 and Corki:QDmg(enemy) > enemy.health then
                    local prediction = pred.getPrediction(target, self.q)
                    if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                        print("pred go brr")
                        player:castSpell(SpellSlot.Q, prediction.castPosition, false, false)
                        print("casted")
                    end
                end
            elseif enemy and enemy:isValidTarget(self.rMega.range, true, player.pos) and self.menu.killsteal.user:get() then
                --print("valid")
                if player:spellSlot(SpellSlot.R).state == 0 and player:findBuff("mbcheck2") and Corki:RDmg2(enemy) > enemy.health then
                    local prediction = pred.getPrediction(target, self.rMega)
                    if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                       -- print("pred go brr")
                        player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                        --print("casted")
                    end
                end
            elseif enemy and enemy:isValidTarget(self.r.range, true, player.pos) and self.menu.killsteal.user:get() then
                --print("valid")
                if player:spellSlot(SpellSlot.R).state == 0 and Corki:RDmg(enemy) > enemy.health then
                    local prediction = pred.getPrediction(target, self.r)
                    if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                       -- print("pred go brr")
                        player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                        --print("casted")
                    end
                end
            end
        end
    end

    function Corki:OnDraw()
        if player.isOnScreen then
            if self.menu.draws.drawq:get() then
                graphics.drawCircle(player.pos, self.q.range, 2, graphics.argb(255, 255, 255, 255))
            end
            if self.menu.draws.drawe:get() then
                graphics.drawCircle(player.pos, self.e.range, 2, graphics.argb(255, 255, 255, 255))
            end
            if self.menu.draws.drawr:get() then
                if player:findBuff("mbcheck2") then
                    graphics.drawCircle(player.pos, self.rMega.range, 2, graphics.argb(255, 255, 255, 255))
                else
                    graphics.drawCircle(player.pos, self.r.range, 2, graphics.argb(255, 255, 255, 255))
                end
            end
        end
    end

    function Corki:OnTick()
        if orb.isComboActive == true then
            Corki:Combo()
        end
        if orb.harassKeyDown == true then
            Corki:Harass()
        end
        Corki:KillSteal()
    end
    Corki:Boot()
end


function Corki.Unload()
    menu.delete("JRC")
end

return Corki



                


