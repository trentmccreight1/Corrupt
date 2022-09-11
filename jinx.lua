local Jinx = { }
function Jinx.Load()

    function Jinx:Boot()

        self.handle = self.networkId

        self.qData = {
            type = spellType.self
        }
        self.wData = {
            delay = 0.6 - (0.02 * math.min(2.50, myHero.characterIntermediate.attackSpeedMod * 0.625) * 100 / 25),
            type = spellType.linear,
            range = 1440,
            speed = 3300,
            width = 120,
            radius = 60,
            collision = {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.Hard,
                tower = SpellCollisionType.None,
    
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
            
        }
        self.eData = {
            delay = 0.25,
            type = spellType.circular,
            range = 900,
            speed = 1750,
            radius = 60,
            boundingRadiusMod = false
        }
        self.rData = {
            delay = 0.6,
            type = spellType.linear,
            range = 99999,
            speed = 1700,
            width = 140,
            collision = {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.None,
                tower = SpellCollisionType.None,
    
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
        }

        self.menu = self:CreateMenu()
        self.callbacks = { { }, { } }

        -- all credits to torben for this callback handler
        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Jinx:OnTick(...) end)
        table.insert(self.callbacks[1], cb.buff)
        table.insert(self.callbacks[2], function(...) Jinx:OnBuff(...) end)
        table.insert(self.callbacks[1], cb.draw)
        table.insert(self.callbacks[2], function(...) Jinx:OnDraw(...) end)
    end

    local MiniGun = true
    local EnemyCC = false
    local QRange = {80, 110, 140, 170, 200}
    --local RB = {0.25, 0.3, 0.35}
    --local RB1 = RB[player:spellSlot(SpellSlot.R).level]

    function Jinx:CreateMenu()
        local mm = menu.create("JRC", "JRC Jinx")
        mm:header("combo", "Combo Settings")
        mm.combo:spacer("xd", "Q Settings")
        mm.combo:boolean("q", "Use Q", true)
        mm.combo:boolean("qr", "Swap Q for Range?", true)
        mm.combo:boolean("qe", "Swap to Minigun if no target?", true)
        mm.combo:boolean("qm", "Swap to Minigun on Low mana?", true)
        mm.combo:slider("Mana", "Min. Mana Percent: ", 20, 0, 100, 10)

        mm.combo:spacer("xd", "W Settings")
        mm.combo:boolean("w", "Use W", true)

        mm.combo:spacer("xd", "E Settings")
        mm.combo:boolean("usee", "Auto E on CC", true)

        mm.combo:spacer("xd", "R Settings")
        mm.combo:slider("rr", "Min. R Range To Cast", 1500, 1000, 3000, 100)

        mm:header("laneclear", "LaneClear")
        mm.laneclear:spacer("qset", "Q Settings")
        mm.laneclear:boolean("useq", "Laneclear With Q", true)
        mm.laneclear:slider("min", "^- Number of Minions", 4, 1, 6, 1)

        mm:header("auto", "Automatic Settings")
        mm.auto:spacer("xd", "KillSteal Settings")
        mm.auto:boolean("uks", "Use Smart Killsteal", true)
        mm.auto:boolean("ukss", "Use W Only Out of Range", true)
        mm.auto:boolean("ukse", "Use R in Killsteal", true)
        mm.auto:spacer("semi", "Semi Keys")
        mm.auto:keybind("ekey", "E Semi Key", "T", false, false)
        mm.auto:keybind("rkey", "R Semi Key", "G", false, false)
        mm.auto:spacer("misc", "Misc")
        mm.auto:boolean("anti", "E Anti-Gapclose", true)

        mm:header("draws", "Draw Settings")
        mm.draws:spacer("xd", "Drawing Options")
        mm.draws:boolean("q", "Draw Q Range", true)
        mm.draws:boolean("r", "Draw R Range", true)

        return mm
    end

    function Jinx:CountEnemyHeroInRange(range)
        local range, count = range, 0 
        for _, enemy in pairs(ts.getTargets()) do
            if enemy and enemy:isValidTarget(math.huge, true, player.pos) and player.pos:dist(enemy.pos) <= range then 
                 count = count + 1
             end 
        end
        return count
    end

    function Jinx:QManager()
        local RocketRange = 675.5 + (75 + (25 * player:spellSlot(SpellSlot.Q).level) + player.boundingRadius)
        local RocketStatus = player:findBuff('jinxq')

        if not player.canAttack or player.isWindingUp then
            return
        end
        local MiniGunX = ts.getInRange(620)

        for _, enemy in pairs(ts.getTargets()) do
    

            local RocketGunX = enemy:isValidTarget(RocketRange, true, player.pos) and enemy.pos:dist(player.pos) > 620
            if self.menu.combo.q:get() then
                if MiniGunX and RocketStatus then
                    --print('Mini Gun Pref')
                    player:castSpell(SpellSlot.Q, false, false)
                    return 
                end

                if RocketGunX and not MiniGunX and not RocketStatus then
                    --print('Rocket Gun Pref')

                    player:castSpell(SpellSlot.Q, false, false)
                    return 
                end
            end
        end
    end

    function Jinx:CastW()
        if player:spellSlot(SpellSlot.W).state ~= 0 then return end
        if player.isWindingUp then return end
        if player.canAttack == false then return end
        local q_range = player:spellSlot(SpellSlot.Q).level > 0 and (QRange[player:spellSlot(SpellSlot.Q).level] + 600) or 600
        for _, enemy in pairs(ts.getTargets()) do
            if self.menu.combo.w:get() then
                local target = ts.getInRange(1480)
                if target
                and target:isValidTarget(self.wData.range, true, player.pos)
                and target.pos:dist(player.pos) > q_range then
                    local prediction = pred.getPrediction(target, self.wData)
                    if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                        player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
                    end
                end
            end
        end
    end

    function Jinx:AutoCC()
        for _, enemy in pairs(ts.getTargets()) do
            if enemy then
                if self.menu.combo.usee:get() and player:spellSlot(SpellSlot.E).state == 0 and enemy.pos:dist(player.pos) <= self.eData.range then
                    local prediction = pred.getPrediction(enemy, self.eData)
                    if enemy:hasBuffOfType(BuffType.Snare) or
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
                            player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
                        end
                    end
                end
            end
        end
    end

    function Jinx:EGapcloser()
        if self.menu.auto.anti:get() then
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

    function Jinx:WDmg(target)
        local spell = player:spellSlot(SpellSlot.W)
        if spell.level == 0 then return 0 end
        local damage = 10 + 50 * spell.level + player.totalAttackDamage * 1.6 - 50
        --print(damageLib.physical(player, target, damage))
        return damageLib.physical(player, target, damage)
    end

    function Jinx:RDmg(target)
        local distance = player.pos:dist(target.pos)
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return end
        local multiplier = math.min(1, 0.1+((player.pos:distance2D(target.pos)-(player.boundingRadius + target.boundingRadius))*0.9)/1500)
        local RB = 0.20 + (spell.level*0.05)
        local damage = ((100 + (150 * spell.level) + (player.totalBonusAttackDamage * 1.5)) * multiplier) + (RB * (target.maxHealth - target.health))
        print(damageLib.physical(player, target, damage))
        --print (multiplier)
        return damageLib.physical(player, target, damage)
    end
        

    
    --[[function Jinx:RDmg(target, distance)
        local distance = player.pos:dist(target.pos)
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return 0 end
        local multipler = 0
        if (distance * 0.166) >= 100 then
            multipler = 1
        else
            multipler = (distance + target.characterIntermediate.moveSpeed / 2.5) * 0.068 / 100
        end 
        local damage = (250 + 150 * spell.level + player.totalAttackDamage * 1.5) * (multipler) + RB[spell.level] * (target.maxHealth - target.health)
        print(damageLib.physical(player, target, damage))
        return damageLib.physical(player, target, damage)
    end--]]

    function Jinx:Killsteal()
        for _, enemy in pairs(ts.getTargets()) do
            if enemy and enemy:isValidTarget(self.wData.range, true, player.pos) and self.menu.auto.uks:get() and not self.menu.auto.ukss:get() then
                --print("enemy found valid enemy and ks enabled")
                if player:spellSlot(SpellSlot.W).state == 0 and player.pos:dist(enemy.pos) <= 1480 and Jinx:WDmg(enemy) > enemy.health then
                    local prediction = pred.getPrediction(enemy, self.wData)
                    --print("damage found and good state good")
                    if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                        --print("pred valid")
                        player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
                    end
                end
            else
                if enemy and enemy:isValidTarget(self.wData.range, true, player.pos) and self.menu.auto.uks:get() and self.menu.auto.ukss:get() then
                    local q_range = player:spellSlot(SpellSlot.Q).level > 0 and (QRange[player:spellSlot(SpellSlot.Q).level] + 600) or 600
                    if player:spellSlot(SpellSlot.W).state == 0 and player.pos:dist(enemy.pos) >= q_range and Jinx:WDmg(enemy) > enemy.health then
                        local prediction = pred.getPrediction(enemy, self.wData)
                        --print("damage found and good state good")
                        if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                            --print("pred valid")
                            player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
                        end
                    end
                end
            end
            if enemy and enemy:isValidTarget(self.rData.range, true, player.pos) and self.menu.auto.ukse:get() then
                if player:spellSlot(SpellSlot.R).state == 0 and Jinx:RDmg(enemy) > enemy.health and self.menu.auto.ukse:get() and enemy.pos:dist(player.pos) > 1000 and enemy.pos:dist(player.pos) <= 2500 then
                    local prediction = pred.getPrediction(enemy, self.rData)
                    --print(type(prediction))
                    if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                        player:castSpell(SpellSlot.R, prediction.castPosition, false, false)
                    end
                end
            end
        end
    end

    function Jinx:OnBuff(sender, buff, gain)
        if sender.handle ~= player.handle then return end
        
        if not buff then return end
        
        if buff.name == "jinxqicon" then
            if gain then
                Jinx.QBuff = buff
                MiniGun = true
            else
                Jinx.QBuff = nil
                MiniGun = false
            end
        end
    end

    function Jinx:LaneClear()
        if orb.laneClearKeyDown and player:spellSlot(SpellSlot.Q).state == 0 and self.menu.laneclear.useq:get() then
            local inRange = 0
            for _, minion in pairs(objManager.minions.enemies.list) do
                if player.pos:dist(minion.pos) <= 700 and not minion.isDead and minion.isVisible then
                    inRange = inRange + 1
                    if MiniGun then
                        if inRange > self.menu.laneclear.min:get() and minion.health < player.totalAttackDamage then
                            player:castSpell(SpellSlot.Q, false, false)
                        end
                    end
                    if not MiniGun then
                        if inRange < self.menu.laneclear.min:get() then
                            player:castSpell(SpellSlot.Q, false, false)
                        end
                    end
                end
            end
        end
    end

    function Jinx:OnDraw()
        if self.menu.draws.q:get() and player.isOnScreen then
            graphics.drawCircle(player.pos, (myHero.characterIntermediate.attackRange + myHero.boundingRadius), 2, graphics.argb(210, 20, 165, 228))
        end
        if self.menu.draws.r:get() and player.isOnScreen then
            graphics.drawCircle(player.pos, self.menu.combo.rr:get(), 2, graphics.argb(210, 20, 165, 228))
        end
    end

    function Jinx:Combo()
        Jinx:QManager()
        Jinx:CastW()
    end

    function Jinx:ESemiKey(target)
        if self.menu.auto.ekey:get() then
            local c_target = ts.getInRange(900)
            if c_target and c_target:isValidTarget(self.eData.range, true, player.pos) then
                target = c_target
            end
            local seg = pred.getPrediction(target, self.eData)
            if seg then
                player:castSpell(SpellSlot.E, seg.castPosition)
            end
        end
    end
    
    function Jinx:RSemiKey(target)
        if self.menu.auto.rkey:get() then
            local c_target = ts.getInRange(menu.combo.rr:get())
            if c_target and c_target:isValidTarget(self.rData.range, true, player.pos) then
                target = c_target
            end
            local seg = pred.getPrediction(target, self.rData)
            if seg then
                player:castSpell(SpellSlot.R, seg.castPosition)
            end
        end
    end

    function Jinx:OnTick()
        --print(self.wData.delay)
        if player.isDead or player.teleportType ~= TeleportType.Null then return end
        Jinx:EGapcloser()
        Jinx:AutoCC()
        Jinx:RSemiKey()
        Jinx:ESemiKey()
        Jinx:Killsteal()
        if orb.isComboActive == true then
            Jinx:Combo()
        end
        if orb.laneClearKeyDown == true then
            Jinx:LaneClear()
        end
    end
    Jinx:Boot()
end

function Jinx.Unload()
    menu.delete("JRC")
end

return Jinx





