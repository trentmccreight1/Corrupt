local Draven = { }
function Draven.Load()

    function Draven:Boot()
        --[[for _, hero in pairs(objManager.heroes.list) do
			for _, buff in pairs(hero.buffs) do
				if buff and buff.valid then
					print(buff.name)
                end
            end
        end--]]

        self.handle = self.networkId

        self.eData = {
            delay = 0.25,
            speed = 1400,
            range = 1050,
            boundingRadiusMod = false,
            collision = false,
            type = spellType.linear
        }
    
        self.rData = {
            delay = 0.4,
            speed = 2000,
            range = 99999,
            boundingRadiusMod = 1,
            collision = false,
            type = spellType.linear
        }

        self.menu = self:CreateMenu()
        self.callbacks = { { }, { } }

        -- all credits to torben for this callback handler
        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Draven:OnTick(...) end)
        table.insert(self.callbacks[1], cb.create)
        table.insert(self.callbacks[2], function(...) Draven:OnCreate(...) end)
        table.insert(self.callbacks[1], cb.delete)
        table.insert(self.callbacks[2], function(...) Draven:OnDelete(...) end)
        table.insert(self.callbacks[1], cb.draw)
        table.insert(self.callbacks[2], function(...) Draven:OnDraw(...) end)
        table.insert(self.callbacks[1], cb.buff)
        table.insert(self.callbacks[2], function(...) Draven:OnBuff(...) end)
    end

    function Draven:CreateMenu()
        local mm = menu.create("JRC", "JRC Draven")

        mm:header("combo", "Combo Settings")
        mm.combo:boolean("comboQ", "Use Q", true)
        mm.combo:boolean("comboW", "Use W", true)
        mm.combo:slider("wmana", "Don't Use W if Mana % < ", 1, 1, 100, 1)
        mm.combo:boolean("comboE", "Use E", true)
        mm.combo:slider("erange", "^- Range to Cast E", 1000, 100, 1050, 50)
        mm.combo:boolean("comboR", "Use R", true)
        mm.combo:slider("Rrange", "R Range Modifier", 5000, 1000, 10000, 500)
    
        mm:header("axe", "Axe Settings")
        mm.axe:list("catchMode", "Catch Axe\'s", {'Combo', 'Always', 'Never'}, 1)
        mm.axe:slider("catchRange", "Catch Range", 600, 100, 1500, 10)
        mm.axe:slider("max", "Max Axe\'s to Juggle", 3, 1, 7, 1)
        mm.axe:boolean("turret", "Dont Catch Axe\'s Under Turret", true)
    
        mm:header("drawing", "Draw Settings")
        mm.drawing:boolean("drawAxe", "Draw Axe Drop Location", true)
        mm.drawing:boolean("drawLine", "Draw Line to Axe Location", true)
        mm.drawing:boolean("drawBuff", "Draw Q Buff Timer", true)
    
        mm:header("misc", "Miscellaneous Settings")
        mm.misc:boolean("QNotCombo", "Use Q During Farm/Harass", true)
        mm.misc:boolean("qalive", "Keep Q Alive", true)
        mm.misc:boolean("wifslowed", "Use W if slowed", true)
        mm.misc:boolean("GapA", "Use E for Anti-Gapclose", true)
        mm.misc:keybind("ekey", "E Semi Key", "T", false, false)
        mm.misc:keybind("rkey", "R Semi Key", "G", false, false)

        return mm
    end

    local AxePositions = {}
    local LatestAxeCreateTick = 0
    local Qpause = 0

    function Draven:OnBuff(sender, buff, gain)
        if sender.handle ~= player.handle then return end
    
        if not buff then return end
    
        if buff.name == "DravenSpinningAttack" then
            if gain then
                Draven.QBuff = buff
            else
                Draven.QBuff = nil
            end
        elseif buff.name == "DravenFury" then -- this buffname is for the speed for the attackspeed buff use "dravenfurybuff"
            if gain then
                Draven.FuryBuff = buff
            else
                Draven.FuryBuff = nil
            end
        end
    end

    function Draven:DamageR(target)
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return 0 end
        local time = time or 0
        if spell.state ~= 0 and spell.cooldown > time then return 0 end
        local damage = 175 + 100 * spell.level + player.totalAttackDamage * 1.1
        return damageLib.physical(player, target, damage)
    end
    
    function Draven:CountQs()
        local count = 0
    
    
        if Draven.QBuff then
            if Draven.QBuff.stacks == 0 then count = count + 1
            else count = count + Draven.QBuff.stacks end
        end
        if AxePositions ~= nil then
            count = count + #AxePositions
        end
    
        return count
    end

    function Draven:OnCreate(unit)
        if player.pos:dist(unit.pos) > 2000 then return end
        if string.find(unit.name, "reticle_self") then
            LatestAxeCreateTick = LatestAxeCreateTick + 1
            table.insert(AxePositions, unit)
        end 
    end
    
    function Draven:OnDelete(unit)
    
        if AxePositions == nil then return end
        if string.find(unit.name, "reticle_self") then
            table.remove(AxePositions, 1)
        end
    end 

    function Draven:EGapcloser()
        if self.menu.misc.GapA:get() then
            for _, dasher in pairs(ts.getTargets()) do
                if dasher and dasher.path.isActive and dasher.path.isDashing and
                    player.pos:dist(dasher.pos) < 550 then
                    local prediction = pred.getPrediction(target, self.eData)
                    if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                    --print("pred go brr")
                        player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
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

    function Draven:OnDraw()
        if player.isOnScreen then
            if AxePositions ~= nil then
                for k, axe in pairs(AxePositions) do
                    if self.menu.drawing.drawAxe:get() then
                        graphics.drawCircle(axe.pos, 110, 2, graphics.argb(255, 0, 255, 0))
                    end
                    if self.menu.drawing.drawLine:get() then
                        graphics.drawLine(player.pos, axe.pos, 2, graphics.argb(255, 255, 255, 0))
                    end
                end
            end
            if self.menu.drawing.drawBuff:get() then
                local buff = player:getBuff("DravenSpinningAttack")
                if buff then
                    local buffTime = math.max(0, math.abs(math.ceil(buff.remainingTime*10)/10))
                    local pos = vec2(player.healthBarPosition.x - 15, player.healthBarPosition.y + 180)
                    if buffTime > 0 then
                        graphics.drawText2D(buffTime, 24, pos, graphics.argb(250, 255, 0, 0))
                    end
                end
            end
        end
    end

    function Draven:BestAxe()
        local best = false
        local distance = 10000
        for k, axe in pairs(AxePositions) do
            if axe then
                --print("Axe")
                local axePos = vec3(axe.x, axe.y, axe.z)
                if game.cursorPos:dist(axePos) < self.menu.axe.catchRange:get() then
                    --print("good axe")
                    best = axe
                    distance = axePos:dist(player)
                end
            end
        end
        if(best ~= true) then -- if we don't have a best axe return false
            return best
        else
            return false
        end
    end

    function Draven:GoFetch()
        local method = self.menu.axe.catchMode:get()
        if (method == 0 and orb.isComboActive == true) or (method == 1) then
            local axe = Draven:BestAxe()
            --if axe and axe.pos:dist(player) >= 0 then return end
            if axe and axe.pos:dist(player) > 85 then
                print("axe in range")
                local walked = false
                if not walked then
                    --print("still")
                    if orb.canAction == true and orb.canAttack == false then
                        orb.setPause((1/30)*2)
                        player:move(axe.pos, false, false, false)
                        --print("Moved")
                        walked = true
                        --print("walking")
                    end
                    walk = false
                end
            end
        end
    end

    function Draven:KeepQAlive()
        if self.menu.misc.qalive:get() and player:spellSlot(SpellSlot.Q).state == 0 then
            local buff = player:getBuff("DravenSpinningAttack")
            if buff then
                local buffTime = math.max(0, math.abs(math.ceil(buff.remainingTime*10)/10))
                if buffTime < 0.2 then
                    player:castSpell(SpellSlot.Q)
                end
            end
        end
    end

    function Draven:ESemiKey(target)
        if self.menu.misc.ekey:get() then
            local c_target = ts.getInRange(self.menu.combo.erange:get())
            if c_target and c_target:isValidTarget(self.eData.range, true, player.pos) then
                target = c_target
            end
            local seg = pred.getPrediction(target, self.eData)
            if seg then
                player:castSpell(SpellSlot.E, seg.castPosition)
            end
        end
    end

    function Draven:RSemiKey(target)
        if self.menu.misc.rkey:get() then
            local c_target = ts.getInRange(self.menu.combo.erange:get())
            if c_target and c_target:isValidTarget(self.menu.combo.erange:get(), true, player.pos) then
                target = c_target
            end
            local seg = pred.getPrediction(target, self.rData)
            if seg then
                player:castSpell(SpellSlot.R, seg.castPosition)
            end
        end
    end

    function Draven:UseQOutsideCombo()
        if self.menu.misc.QNotCombo:get() and player:spellSlot(SpellSlot.Q).state == 0 and player.canAttack == true and player.isWindingUp == false and Draven:CountQs() < 1 then
            player:castSpell(SpellSlot.Q)
        end
    end

    function Draven:IsCombo(target)
        if target.pos:dist(player.pos) <= 1200 then
    
            if self.menu.combo.comboQ:get() and player:spellSlot(SpellSlot.Q).state == 0 and player.canAttack == true and player.isWindingUp == false and Draven:CountQs() < self.menu.axe.max:get() then
                if (self.QBuff and self.QBuff.stacks ~= 2) or self.QBuff == nil then
                player:castSpell(SpellSlot.Q)
                end
            end
            
            if self.menu.combo.comboW:get() and player:spellSlot(SpellSlot.W).state == 0 and self.FuryBuff == nil and (player.mana / player.maxMana) * 100  > self.menu.combo.wmana:get() then
                player:castSpell(SpellSlot.W)
            end
    
            if self.menu.combo.comboE:get() and player:spellSlot(SpellSlot.E).state == 0 then
                local c_target = orb.comboTarget
                if c_target and c_target:isValidTarget(self.eData.range, true, player.pos) then
                    target = c_target
                end
                local seg = pred.getPrediction(target, self.eData)
                if seg then
                    player:castSpell(SpellSlot.E, seg.castPosition)
                end
            end
    
            if self.menu.combo.comboR:get() and player:spellSlot(SpellSlot.R).state == 0 then
                if Draven:DamageR(target) >= target.health then
                    local seg2 = pred.getPrediction(target, self.rData)
                    if seg2 then
                        player:castSpell(SpellSlot.R, seg2.castPosition)
                    end
                end
            end
        end
    end

    function Draven:OnTick()
        if player.isDead or player.teleportType ~= TeleportType.Null then return end
        Draven:GoFetch()
        Draven:KeepQAlive()
        Draven:ESemiKey(target)
        Draven:RSemiKey(target)
        if player:spellSlot(SpellSlot.W).state == 0 and self.menu.misc.wifslowed:get() and player:hasBuffOfType(BuffType.Slow) then
            player:castSpell(SpellSlot.W, player)
        end
    
        if (orb.isComboActive == true) then
            local target = ts.getInRange(1000)
            if target and target:isValidTarget(1000, true, player.pos) then
                Draven:IsCombo(target)
            end
        end
    
        if (orb.harassKeyDown == true or orb.laneClearKeyDown == true or orb.lastHitKeyDown == true) then
            Draven:UseQOutsideCombo()
        end
    
        if self.menu.misc.GapA:get() then
            Draven:EGapcloser()
        end
    end
    Draven:Boot()
end

function Draven.Unload()
    menu.delete("JRC")
end

return Draven
