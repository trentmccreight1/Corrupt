local Caitlyn = { }
function Caitlyn.Load()

    function Caitlyn:Boot()

        self.handle = self.networkId

        self.q = {
            delay = 0.625,
            speed = 2200,
            range = 1250,
            type = spellType.linear,
            boundingRadiusMod = true,
            width = 60,
            collision = 
            {
                hero = SpellCollisionType.Soft,
                minion = SpellCollisionType.Soft,
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
        }

        self.e = {
            delay = 0.125,
            speed = 1600,
            range = 750,
            type = spellType.linear,
            boundingRadiusMod = true,
            width = 70,
            collision = 
            {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.Hard,
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
        }

        self.w = {
            delay = 1.5,
            speed = math.huge,
            range = 800,
            type = spellType.circular,
            radius = 67.5,
            boundingRadiusMod = false
        }


        self.menu = self:CreateMenu()
        self.callbacks = { { }, { } }

        -- all credits to torben for this callback handler
        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Caitlyn:OnTick(...) end)
        table.insert(self.callbacks[1], cb.create)
        table.insert(self.callbacks[2], function(...) Caitlyn:OnCreate(...) end)
        table.insert(self.callbacks[1], cb.delete)
        table.insert(self.callbacks[2], function(...) Caitlyn:OnDelete(...) end)
        table.insert(self.callbacks[1], cb.draw)
        table.insert(self.callbacks[2], function(...) Caitlyn:OnDraw(...) end)
    end

    local r = {range = 2000}

    function Caitlyn:RDmg(target)
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return 0 end
        local damage = (300 + 225 * spell.level + player.totalBonusAttackDamage * 2.0)
        return damageLib.physical(player, target, damage)
    end

    local particleHeadshotList = { }

    function Caitlyn:CreateMenu()
        local mm = menu.create("JRC", "JRC Caitlyn")

        mm:header("c", "Combo")
        mm.c:boolean("qcombo", "Use Q in Combo", true)
        mm.c:boolean("ecombo", "Use E in Combo", true)
        mm.c:boolean("wcombo", "W After E in Combo", true)

        mm:header("h", "Harass")
        mm.h:boolean("qharass", "Use Q in Harass", true)
        mm.h:slider("manaq", "Q Mana", 80, 1, 100, 1)

        mm:header("k", "KillSteal")
        mm.k:boolean("ksr", "KillSteal With R", false)

        mm:header("draws", "Draw Settings")
        mm.draws:boolean("drawaa", "Draw AA Trapped Range", true)
        mm.draws:boolean("drawq", "Draw Q Range", true)
        mm.draws:boolean("draww", "Draw W Range", true)
        mm.draws:boolean("drawe", "Draw E Range", true)

        mm:header("misc", "Misc.")
        mm.misc:header("setq", "Q Settings")
        mm.misc.setq:boolean("logicalq" , "On Trappped/Netted enemy", true)
        mm.misc.setq:boolean("logicalq2", "Only out of AA range", false)
        mm.misc:header("setw", "W Settings")
        mm.misc.setw:boolean("logicalw" , "On Hard CC'ed", true)

        return mm
    end

    --Gets all buff that the unit has and prints them to the console.

    function Caitlyn:CastE(target)
        if self.menu.c.ecombo:get() then
            local target = ts.getInRange(750)
            if target and target:isValidTarget(self.e.range, true, player.pos) then
                local prediction = pred.getPrediction(target, self.e)
                if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                   -- print("pred is aquired and valid")
                    player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
                end
            end
        end
    end
    
    function Caitlyn:CastQ()
        if player.isWindingUp then return end
        if player.canAttack == false then return end
        if self.menu.c.qcombo:get() then
            --print("alloed")
            local target = ts.getInRange(1250)
            if target and target:isValidTarget(self.q.range, true, player.pos) then
                --print("target aquired and valid")
                local prediction = pred.getPrediction(target, self.q)
                if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                    --print("pred is aquired and valid")
                    player:castSpell(SpellSlot.Q, prediction.castPosition, false, false)
                end
            end
        end
    end

    function Caitlyn:Harass()
        local target = ts.getInRange(1250)
        if target and target:isValidTarget(self.q.range, true, player.pos) then
            local prediction = pred.getPrediction(target, self.q)
            if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
             --print("pred is aquired and valid")
                player:castSpell(SpellSlot.Q, prediction.castPosition, false, false)
            end
        end
    end

    function Caitlyn:AutoCC()
        for _, enemy in pairs(ts.getTargets()) do
            if enemy then
                if self.menu.misc.setw.logicalw:get() and player:spellSlot(SpellSlot.W).state == 0 and enemy.pos:dist(player.pos) <= self.w.range then
                    local prediction = pred.getPrediction(enemy, self.w)
                    if enemy:hasBuffOfType(BuffType.Snare) or
                       enemy:hasBuffOfType(BuffType.Slow) or
                       enemy:hasBuffOfType(BuffType.Stun) or
                       enemy:hasBuffOfType(BuffType.Charm) or
                       enemy:hasBuffOfType(BuffType.Taunt) or
                       enemy:hasBuffOfType(BuffType.Suppression) or
                       enemy:hasBuffOfType(BuffType.Knockup) or
                       enemy:hasBuffOfType(BuffType.Grounded) or
                       enemy:hasBuffOfType(BuffType.Asleep) or
                       enemy:findBuff("zhonyasringshield") or
                       enemy:findBuff("bardrstasis") then
                        print("cc")
                        if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                            if player:spellSlot(SpellSlot.W).stacks > 1 then
                                player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
                            end
                        end
                    end
                end
            end
        end
    end

    local gameObject = _G.gameObject
    function gameObject:getBuff(name)
        for _, buff in pairs(self.buffs) do
            if buff and buff.valid and buff.name == name then
                return buff
            end 
        end
    end

    function Caitlyn:GetHeadshot()
        local targets = {}
        local distance = math.huge
        for key,value in ipairs(particleHeadshotList) do
            for _, enemy in pairs(ts.getTargets()) do
                -- Get distance from object and enemy and get the lowest distance
                local distance, target = false
                if value.pos:dist(enemy.pos) < 1300 then
                    --print("distance")
                    distance = value.pos:dist(enemy.pos)
                    target = enemy
                end
                if target then
                    table.insert(targets, target)
                    --print("inserted")
                end
            end
        end
        return targets
    end


    function Caitlyn:AutoTrapped()
        for _, enemy in pairs(self:GetHeadshot()) do
            if enemy and enemy:isValidTarget(self.q.range, true, player.pos) then
               -- print("target found")
                --print("valid target")
                if self.menu.misc.setq.logicalq:get() and not self.menu.misc.setq.logicalq2:get() and player:spellSlot(SpellSlot.Q).state == 0 and enemy.pos:dist(player.pos) <= self.q.range then
                   -- print("we good")
                    local prediction = pred.getPrediction(enemy, self.q)
                    if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                       -- print("pred go brr")
                        player:castSpell(SpellSlot.Q, prediction.castPosition, false, false)
                        --print("casted")
                    end
                end
            end
        end
    end

    function Caitlyn:AATrapped()
        for _, enemy in pairs(self:GetHeadshot()) do
            if enemy and enemy:isValidTarget(1300, true, player.pos) then
                orb.setPause(0.1)
                player:attack(enemy)
            end
        end
    end
    

    function Caitlyn:OnCreate(object)
        if string.find(object.name, "_W_E_Tar_Headshot_Beam") and string.find(object.name, "Caitlyn_") then
            table.insert(particleHeadshotList, object)
            --print("wcreate")
        end
    end
    function Caitlyn:OnDelete(object)
        if string.find(object.name, "_W_E_Tar_Headshot_Beam") and string.find(object.name, "Caitlyn_") then
            for key,value in ipairs(particleHeadshotList) do
                if value.networkId == object.networkId then
                    table.remove(particleHeadshotList, key)
                    break
                end
            end
            --print("wdelete")
        end
    end

    function Caitlyn:KillSteal()
        for _, enemy in pairs(ts.getTargets()) do
            if enemy and enemy:isValidTarget(r.range, true, player.pos) and self.menu.k.ksr:get() then
                --print("valid")
                if player:spellSlot(SpellSlot.R).state == 0 and player.pos:dist(enemy.pos) >= 1000 and player.pos:dist(enemy.pos) <= 2500 and Caitlyn:RDmg(enemy) > enemy.health then
                    --print("damage")
                    player:castSpell(SpellSlot.R, enemy, false, false)
                    --print("cast")
                end
            end
        end
    end

    function Caitlyn:OnDraw()
        if player.isOnScreen then
            if self.menu.draws.drawaa:get() then
                graphics.drawCircle(player.pos, 1300, 2, graphics.argb(255, 255, 255, 255))
            end
            if self.menu.draws.drawq:get() then
                graphics.drawCircle(player.pos, self.q.range, 2, graphics.argb(255, 255, 255, 255))
            end
            if self.menu.draws.draww:get() then
                graphics.drawCircle(player.pos, self.w.range, 2, graphics.argb(255, 255, 255, 255))
            end
            if self.menu.draws.drawe:get() then
                graphics.drawCircle(player.pos, self.e.range, 2, graphics.argb(255, 255, 255, 255))
            end
        end
    end



    function Caitlyn:Combo()
        self:CastQ()
        Caitlyn:CastE()
    end

    function Caitlyn:OnTick()
        if player:spellSlot(SpellSlot.R).level == 1 then
            r.range = 2000
        elseif player:spellSlot(SpellSlot.R).level == 2 then
            r.range = 2500
        elseif player:spellSlot(SpellSlot.R).level == 3 then
            r.range = 3000
        end
        Caitlyn:KillSteal()
        Caitlyn:AATrapped()
        Caitlyn:AutoTrapped()
        Caitlyn:AutoCC()
        if orb.isComboActive == true then
            Caitlyn:Combo()
        end
        if orb.harassKeyDown == true then
            Caitlyn:Harass()
        end
    end
    Caitlyn:Boot()
end

function Caitlyn.Unload()
    menu.delete("JRC")
end

return Caitlyn













    
