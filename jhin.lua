local Jhin = { }
function Jhin.Load()

    function Jhin:Boot()

        self.handle = self.networkId

        self.qData = {
            range = 600
        }
        self.wData = {
            delay = 0.75,
            type = spellType.linear,
            range = 2550,
            speed = 5000,
            wdith = 45,
            collision = {
                hero = SpellCollisionType.Hard,
                minion = SpellCollisionType.Soft,
                tower = SpellCollisionType.None,
    
                flags = bit.bor(CollisionFlags.Windwall, CollisionFlags.Samira, CollisionFlags.Braum)
            }
        }
        self.eData = {
            delay = 0.85,
            type = spellType.circular,
            range = 750,
            speed = 1600,
            radius = 150,
            boundingRadiusMod = false
        }
        self.rData = {
            delay = 0.2,
            type = spellType.cone,
            range = 3500,
            speed = 4500,
            width = 40,
            angle = 60,
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

    function Jinx:CreateMenu()
        local mm = menu.create("JRC", "JRC Jhin")
        mm:header("combo", "Combo Settings")
        mm.combo:boolean("useq", "Use Q in Combo", true)
        mm.combo:boolean("usew", "Use W in Combo", true)
        mm.combo:boolean("usew2", "Use W Only if it Will Stun", true)
        mm.combo:boolean("usee", "Use E in Combo", false)

        mm:header("ultimate", "Ultimate Settings")
        mm.ultimate:keybind("tapkey", "R Tap Key", "T", false, false)
        mm.ultimate:keybind("cancelkey", "R Cancel Key", "G", false, false)

        mm:header("harass", "Harass Settings")
        mm.harass:boolean("useq", "Use Q in Harass", true)
        mm.harass:boolean("usew", "Use W in Harass", false)
        mm.harass:boolean("usee", "Use E in Harass", false)
        mm.harass:slider("mana", "Min. Mana% For Harass", 50, 0, 100, 1)

        mm:header("lasthit", "Lasthit Settings")
        mm.lasthit:boolean("useq", "Use Q in Lasthit", true)
        mm.lasthit:slider("mana", "Min. Mana% For Lasthit", 50, 0, 100, 1)

        mm:header("misc", "Misc Settings")
        mm.misc:spacer("killsteal", "Killsteal")
        mm.misc:boolean("useq", "Use Q in Killsteal", true)
        mm.misc:boolean("usew", "Use W in Killsteal", true)
        mm:misc:spacer("drawings", "Draw Settings")
        mm.misc:boolean("drawq", "Draw Q Range", true)
        mm.misc:boolean("draww", "Draw W Range", true)
        mm.misc:boolean("drawe", "Draw E Range", false)
        mm.misc:boolean("drawr", "Draw R Range", true)

        return mm
    end

    local Mark = false
    local Reload = false
    local UltOn = false 
    local Minions = {}

    function Jhin:CastQ()
        if player.canAttack == false then return end
        if player.isWindingUp then return end
        local target = ts.getInRange(self.qData.range)
        if target and player:spellSlot(SpellSlot.Q).state == 0 and target:isValidTarget(self.qData.range, true, player.pos) and player.pos:dist(target.pos) <= self.qData.range then
            player:castSpell(SpellSlot.Q, target, false, false)
        end
    end

    function Jhin:CastW()
        if player.canAttack == false then return end
        if player.isWindingUp then return end
        local target = ts.getInRange(self.wData.range)
        if target and player:spellSlot(SpellSlot.W).state == 0 and target:isValidTarget(self.wData.range, true, player.pos) and player.pos:dist(target.pos) <= self.wData.range and target:findBuff("jhinespotteddebuff") then
            local prediction = pred.getPrediction(target, self.wData)
            if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
            end
        end
    end

    function Jhin:CastW2()
        if player.canAttack == false then return end
        if player.isWindingUp then return end
        local target = ts.getInRange(self.wData.range)
        if target and player:spellSlot(SpellSlot.W).state == 0 and target:isValidTarget(self.wData.range, true, player.pos) and player.pos:dist(target.pos) <= self.wData.range then
            local prediction = pred.getPrediction(target, self.wData)
            if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                player:castSpell(SpellSlot.W, prediction.castPosition, false, false)
            end
        end
    end

    function Jhin:CastE()
        if player.canAttack == false then return end
        if player.isWindingUp then return end
        local target = ts.getInRange(self.eData.range)
        if target and player:spellSlot(SpellSlot.E).state == 0 and target:isValidTarget(self.eData.range, true, player.pos) and player.pos:dist(target.pos) <= self.eData.range then
            local prediction = pred.getPrediction(target, self.eData)
            if prediction and prediction.castPosition.isValid and prediction.hitChance >= 3 then
                player:castSpell(SpellSlot.E, prediction.castPosition, false, false)
            end
        end
    end

    






        

