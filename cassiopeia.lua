local Cassiopeia = { }
function Cassiopeia.Load()

    function Cassiopeia:Boot()

        self.handle = self.networkId

        self.q = {
            delay = 0.75,
            speed = math.huge,
            range = 850,
            type = spellType.circular,
            radius = 170,
            boundingRadiusMod = false
        }

        self.w = {
            delay = 0.7,
            range = 850,
            speed = 3000,
            type = spellType.circular,
            radius = 150,
            boundingRadiusMod = false
        }

        self.e = {
            range = 750
        }

        self.r = {
            delay = 0.5,
            speed = math.huge,
            range = 825,
            spellType.cone,
            angle = 80,
            width = 100,
            boundingRadiusMod = false
        }

        self.rflash = {
            range = self.r.range + 410
        }

        self.menu = self:CreateMenu()
        self.callbacks = { { }, { } }

        -- all credits to torben for this callback handler
        table.insert(self.callbacks[1], cb.tick)
        table.insert(self.callbacks[2], function(...) Cassiopeia:OnTick(...) end)
        --table.insert(self.callbacks[1], cb.create)
        --table.insert(self.callbacks[2], function(...) Caitlyn:OnCreate(...) end)
        --table.insert(self.callbacks[1], cb.delete)
        --table.insert(self.callbacks[2], function(...) Caitlyn:OnDelete(...) end)
        table.insert(self.callbacks[1], cb.draw)
        table.insert(self.callbacks[2], function(...) Cassiopeia:OnDraw(...) end)
    end

    local interruptableSpells = {
        ["anivia"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "glacialstorm",
                channelduration = 6
            }
        },
        ["caitlyn"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "caitlynaceinthehole",
                channelduration = 1
            }
        },
        ["ezreal"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "ezrealtrueshotbarrage",
                channelduration = 1
            }
        },
        ["fiddlesticks"] = {
            {menuslot = "W", slot = 1, spellname = "drain", channelduration = 5},
            {
                menuslot = "R",
                slot = 3,
                spellname = "crowstorm",
                channelduration = 1.5
            }
        },
        ["gragas"] = {
            {
                menuslot = "W",
                slot = 1,
                spellname = "gragasw",
                channelduration = 0.75
            }
        },
        ["janna"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "reapthewhirlwind",
                channelduration = 3
            }
        },
        ["karthus"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "karthusfallenone",
                channelduration = 3
            }
        }, -- common.IsValidTargetTarget will prevent from casting @ karthus while he's zombie
        ["katarina"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "katarinar",
                channelduration = 2.5
            }
        },
        ["lucian"] = {
            {menuslot = "R", slot = 3, spellname = "lucianr", channelduration = 2}
        },
        ["lux"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "luxmalicecannon",
                channelduration = 0.5
            }
        },
        ["malzahar"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "malzaharr",
                channelduration = 2.5
            }
        },
        ["masteryi"] = {
            {menuslot = "W", slot = 1, spellname = "meditate", channelduration = 4}
        },
        ["missfortune"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "missfortunebullettime",
                channelduration = 3
            }
        },
        ["nunu"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "absolutezero",
                channelduration = 3
            }
        },
        -- excluding Orn's Forge Channel since it can be cancelled just by attacking him
        ["pantheon"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "pantheonrjump",
                channelduration = 2
            }
        },
        ["shen"] = {
            {menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3}
        },
        ["twistedfate"] = {
            {menuslot = "R", slot = 3, spellname = "gate", channelduration = 1.5}
        },
        ["varus"] = {
            {menuslot = "Q", slot = 0, spellname = "varusq", channelduration = 4}
        },
        ["warwick"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "warwickr",
                channelduration = 1.5
            }
        },
        ["xerath"] = {
            {
                menuslot = "R",
                slot = 3,
                spellname = "xerathlocusofpower2",
                channelduration = 3
            }
        }
    }

    function Cassiopeia:CreateMenu()
        local mm = menu.create("JRC", "Trent Cassiopeia")

        mm:header("combo", "Combo")
        mm.combo:header("qset", "Q Settings")
        mm.combo.qset:boolean("qcombo", "Use Q in Combo", true)
        mm.combo.qset:boolean("qpoison", " ^-Only if NOT POISONED", false)
        mm.combo.qset:boolean("autoq", "Auto Q on Dash", true)

        mm.combo:header("wset", "W Settings")
        mm.combo.wset:boolean("wcombo", "Use W in Combo", true)
        mm.combo.wset:boolean("startw", "Start Combo with W", true)
        mm.combo.wset:slider("rangew", "W Max Range", 780, 400, 850, 1)

        mm.combo:header("eset", "E Settings")
        mm.combo.eset:boolean("ecombo", "Use E in Combo", true)
        mm.combo.eset:boolean("epoison", " ^-Only if POISONED", false)

        mm.combo:header("rset", "R Settings")
        mm.combo.rset:slider("range", "R Range", 750, 100, 825, 1)
        mm.combo.rset:list("rusage", "R Usage", {'At X Health', 'Only if Killable', 'Never'}, 0)
        mm.combo.rset:slider("waster", "Don't waste R if Enemy Health < X", 100, 0, 500, 1)
        mm.combo.rset:slider("hpr", "R if Target has X Health Percent", 60, 0, 100, 1)
        mm.combo.rset:boolean("face", "Use R only if Facing", true)
        mm.combo.rset:slider("hitr", "Min. Enemies to Hit", 2, 2, 5, 1)
        mm.combo.rset:boolean("facer", " ^-Only count if Facing", true)

        mm.combo:keybind("rflash", "R-Flash Key", "G", false, false)
        mm.combo:boolean("flashrface", " ^- Only if Facing", true)
        mm.combo:keybind("semir", "Semi-R Key", "T", false, false)
        mm:header("blacklist", "R Blacklist")
        for _, hero in pairs(objManager.heroes.enemies.list) do
            if hero then
                mm.blacklist:boolean(hero.skinHash, "Block: " .. hero.skinName, false)
            end
        end

        mm:header("harass", "Harass")
        mm.harass:slider("mana", "Mana Manager", 50, 0, 100, 1)
        mm.harass:boolean("qharass", "Use Q to Harass", true)
        mm.harass:boolean("eharass", "Use E to Harass", true)
        mm.harass:boolean("epoison", " ^-Only use if POISONED", false)
        mm.harass:boolean("laste", "Last Hit with E", true)

        mm:header("laneclear", "Farming")
        mm.laneclear:header("push", "Pushing")
        mm.laneclear.push:slider("mana", "Mana Manager", 30, 0, 100, 1)
        mm.laneclear.push:boolean("useq", "Use Q to Farm", true)
        mm.laneclear.push:slider("hitq", " ^-If Hits", 2, 0, 6, 1)
        mm.laneclear.push:boolean("farme", "Use E to Farm", true)
        mm.laneclear.push:boolean("epoison", " ^-Only if POISONED", true)
        mm.laneclear.push:boolean("disable", "Disable AA", true)
        mm.laneclear:header("passive", "Freeze")
        mm.laneclear.passive:boolean("farme", "Use E to Last Hit", true)

        mm.laneclear:header("jungle", "Jungle Clear")
        mm.laneclear.jungle:slider("mana", "Mana Manager", 30, 0, 100, 1)
        mm.laneclear.jungle:boolean("useq", "Use Q in Jungle", true)
        mm.laneclear.jungle:boolean("usee", "Use E in Jungle", true)

        mm:header("lasthit", "Last Hit")
        mm.lasthit:boolean("qlasthit", "Use E", true)

        mm:header("killsteal", "Killsteal")
        mm.killsteal:boolean("ksq", "Killsteal with Q", true)
        mm.killsteal:boolean("kse", "Killsteal with E", true)
        mm.killsteal:boolean("ksr", "Killsteal with R", true)
        mm.killsteal:slider("saver", "Don't waste R if Enemy Health < X", 100, 0, 500, 1)

        mm:header("misc", "Misc.")
        mm.misc:boolean("disable", "Disable Auto Attack", true)
        mm.misc:slider("level", "Disable AA at X Level", 6, 1, 18, 1)
        mm.misc:boolean("GapA", "Use R for Anti-Gapclose", true)
        mm.misc:slider("health", " ^-Only if my Health Percent < X", 50, 1, 100, 1)
        mm.misc:header("interrupt", "Interrupt Settings")
        mm.misc.interrupt:boolean("inte", "Use R to Interrupt", true)
        mm.misc.interrupt:header("interruptmenu", "Interrupt Settings")

        for _, enemy in pairs(ts.getTargets()) do
            local name = string.lower(enemy.skinHash)
            if enemy and interruptableSpells[name] then
                for v = 1, #interruptableSpells[name] do
                    local spell = interruptableSpells[name][v]
                    mm.misc.interrupt.interruptmenu:boolean(string.format(tostring(enemy.skinHash) .. tostring(spell.menuslot)), "Interrupt " .. tostring(enemy.skinName) .. " " .. tostring(spell.menuslot), true)
                end
            end
        end

        mm:header("draws", "Draw Settings")
        mm.draws:boolean("drawq", "Draw Q Range", true)
        mm.draws:boolean("draww", "Draw W Range", false)
        mm.draws:boolean("drawwmin", "Draw Min. W Range", false)
        mm.draws:boolean("drawe", "Draw E Range", true)
        mm.draws:boolean("drawr", "Draw R Range", false)
        mm.draws:boolean("drawrf", "Draw R-Flash Range", false)
        mm.draws:boolean("drawdamage", "Draw Damage", true)
        mm.draws:boolean("drawkill", "Draw Killable Minions with E", true)

        return mm
    end

    function Cassiopeia:count_enemies_in_range(pos, range)
        local enemies_in_range = {}
        for _, enemy in pairs(ts.getTargets()) do
            if pos:dist(enemy.pos) < range then
                enemies_in_range[#enemies_in_range + 1] = enemy
            end
        end
        return enemies_in_range
    end

    function Cassiopeia:isFacing(target)
        return player.path.serverPosition:distSqr(target.path.serverPosition) >
               player.path.serverPosition:distSqr(
                   target.path.serverPosition + target.direction)
    end
    
    --[[function Cassiopeia:EDmg(target)
        local damage = 0
        local ElvlDmgBonus = {20, 40, 60, 80, 100}
        local ElvlDamage = 4
        local spell = player:spellSlot(SpellSlot.R)
        if spell.level == 0 then return end
        if target:findBuff("poisontrailtarget") or target:findBuff("TwitchDeadlyPoison") or
           target:findBuff("cassiopeiawpoison") or target:findBuff("cassiopeiaqdebuff") or
           target:findBuff("ToxicShotParticle") or target:findBuff("bantamtraptarget") then
            damage = (52 + ElvlDamage) * (player.level - 1) + (player.totalAbilityPower * 0.1) + (ElvlDmgBonus[spell.level]) + (player.totalAbilityPower * 0.6)
        else
            damage = (52 + ElvlDamage) * (player.level - 1) + (player.totalAbilityPower * 0.1)
            print(ElvlDamage)
        end
        --print(damageLib.magical(player, target, damage))
        return damageLib.magical(player, target, damage)
    end--]]

    function Cassiopeia:EDmg(target)
        local damage = 0
        local spell = player:spellSlot(SpellSlot.E) -- wrong slot
        if spell.level == 0 then
            return 0
        end
        if
            target:findBuff('poisontrailtarget') or target:findBuff('TwitchDeadlyPoison') or
                target:findBuff('cassiopeiawpoison') or
                target:findBuff('cassiopeiaqdebuff') or
                target:findBuff('ToxicShotParticle') or
                target:findBuff('bantamtraptarget')
         then
            damage =
                (10 + (4 * player.level) + (player.totalAbilityPower * 0.1) + (20 * spell.level) +
                (player.totalAbilityPower * 0.6))
        else
            damage = (10 + (4 * player.level) + (player.totalAbilityPower * 0.1)) + 25
        end

        return damageLib.magical(player, target, damage) -- one return
    end

    --[[function Cassiopeia:AutoDash()
        local target = ts.getInRange(self.q.range)
        if player.pos:dist(target.pos) <= self.q.range and target.path.isActive and target.path.isDashing then
            if target then
                local pred_pos
            end
        end
    end--]]

    --[[function Cassiopeia:WGapCloser()
        if player:spellSlot(SpellSlot.W).level == 0 and self.menu.misc.GapA:get() then
            for _, dasher in pairs(ts.getTargets()) do
                if dasher and dasher:isValidTarget(self.w.range, true, player.pos) and
                    dasher.path.isActive and dasher.path.isDashing and
                    player.pos:dist(dasher.path.point[1]) < 850 then
                    if player.pos2D:dist(dasher.path.point2D[1]) <
                        player.pos2D:dist(dasher.path.point2D[0]) then
                        if ((player.health / player.maxHealth) * 100 <=
                            menu.misc.health:get()) then
                            player:castSpell(SpellSlot.W, dasher.path.point2D[1], false, false)
                        end
                    end
                end
            end
        end
    end--]]

    local FlashSlot = false
    local delay = 0
    if player:spellSlot(4).name == "SummonerFlash" then
        FlashSlot = 4
    elseif player:spellSlot(5).name == "SummonerFlash" then
        FlashSlot = 5
    end

    local next_flash = false
    function Cassiopeia:FlashR(target)
        local target = ts.getInRange(self.rflash.range)
        next_flash = game.time + 0.25
        if not self.menu.combo.rflash:get() then return end
        if (not FlashSlot or player:spellSlot(SpellSlot.FlashSlot).state ~= 0) then return end
        if not target then print("wtf") return end
        if not target.isVisible or player.pos:dist(target.pos) > self.rflash.range then return end
        player:move(vec3(game.cursorPos.x, game.cursorPos.y, game.cursorPos.z), false, false, false)
        if game.time > next_flash then
            print("fuck12")
            player:castSpell(FlashSlot, target.pos, false, false)
            next_flash = false
            return
        end

        if player:spellSlot(SpellSlot.R).state == 0 then
            local pos = pred.getPrediction(target, self.rflash)
            if pos then print("yolo")
                player:castSpell(SpellSlot.R, pos.castPosition, false, false)
                next_flash = game.time + 0.25
            end
        end
    end

    function Cassiopeia:LastHit()
        for _, minion in pairs(objManager.minions.enemies.list) do
            if minion and minion.isVisible and minion.isTargetable and not minion.isDead and minion.pos:dist(player.pos) < self.e.range then
                local minionPos = vec3(minion.x, minion.y, minion.z)
                delay = 125 / 1000 + player.pos:dist(minion.pos) / 840
                if (Cassiopeia:EDmg(minion) >= orb.predictHP(minion, delay / 2) - 150) then
                    orb.setAttackPause(1)
                end
                if (Cassiopeia:EDmg(minion) >= orb.predictHP(minion, delay/ 2)) then
                    player:castSpell(SpellSlot.E, minion, false, false)
                end
            end
        end
    end
                

    function Cassiopeia:OnDraw()
        -- blash blah blah
    end
    
    function Cassiopeia:OnTick()
        if orb.laneClearKeyDown == true then
            Cassiopeia:LastHit()
        end
        Cassiopeia:FlashR()
        --blah
    end

    Cassiopeia:Boot()
end

function Cassiopeia.Unload()
    menu.delete("JRC")
end

return Cassiopeia

