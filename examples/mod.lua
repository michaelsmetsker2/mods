----- trait examples

local monitor_trait = define_trait { id = 1, name = "Monitor" }

------ boon examples

define_boon {
    id = 1,
    name = "Double or Nothing",
    desc = "Money earned randomly has either x2.0 or x0.0 mult",
    texture = "double_or_nothing.png",
    rarity = rarities.common,
    on_earn = function(e)
        -- e.ball - the ball, if any, that caused the earning. may be nil.
        -- e.trigger - the trigger, if any, that caused the earning. may be nil.
        -- e.boon - the boon. if any, that caused the earning. may be nil.
        -- e.earn - the earnings object. never nil.
        local xmult = 1.0
        if math.random() > 0.5 then
            xmult = 2.0
        else
            xmult = 0.0
        end
        -- apply as xmult
        e.earn.xmult(xmult)
        -- let's alert the player that this happened w/ a floatie if it's a trigger
        if e.trigger then
            e.api.spawn_floatie { source = e.trigger, texture = e.self.def.texture }
        end
    end,
}

define_boon {
    id = 2,
    name = "Friend Gregplant",
    desc = "Whenever a ball drops, spawn an Eggplant near it.",
    texture = "gregplant.png",
    rarity = rarities.common,
    on_drop = function(e)
        -- e.balls - an array of all balls dropping. slot machine can spawn more than one ball.
        for _,ball in pairs(e.balls) do
            e.api.spawn_ball { type = balls.eggplant, from = ball.position }
        end
    end,
}

define_boon {
    id = 3,
    name = "Free Real Estate",
    desc = "Placed ➜ Gain $1,234",
    texture = "free_real_estate.png",
    one_shot = true,
    rarity = rarities.common,
    on_place = function(e)
        -- e.continuing is true if we're loading the game. so don't repeat any behavior that's intended to be "one time"
        if not e.continuing then
            e.api.earn { source = e.self, ball = nil, base = 1234, mult = 1.0 }
        end
    end,
}

define_boon {
    id = 4,
    name = "Pangrea",
    desc = "Whenever a rock ball bonks a trigger, destroy it and spawn a water ball, and vice versa.",
    texture = "pangrea.png",
    rarity = rarities.common,
    on_bonk = function(e)
        -- e.ball - the ball that caused the bonk. won't be nil.
        -- e.trigger - the trigger that was bonked. won't be nil.
        if e.ball.type == balls.rock then
            e.api.destroy_ball { ball = e.ball }
            e.api.spawn_ball { type = balls.water, from = e.trigger }
            e.api.spawn_floatie { source = e.trigger, texture = e.self.def.texture }
        elseif e.ball.type == balls.water then
            e.api.destroy_ball { ball = e.ball }
            e.api.spawn_ball { type = balls.rock, from = e.trigger }
            e.api.spawn_floatie { source = e.trigger, texture = e.self.def.texture }
        end
    end,
}

local oops_all_cheese = define_boon {
    id = 5,
    name = "Oops!!! All Cheese",
    desc = "The board starts filled with Cheese triggers. You start with 10 removals.",
    texture = triggers.cheese.texture,
    rarity = rarities.undraftable,
    on_place = function(e)
        -- this isn't really great because this will run before tribulations, so it could block out 
        -- roaming nihility, for example
        if not e.continuing then
            for slot in e.api.all_slots() do
                e.api.place_trigger { def = triggers.cheese, slot = slot }
            end
            e.api.gain_removals { source = e.self, amount = 10 }
        end
    end
}

local event_monitor = define_boon {
    id = 6,
    name = "Event Monitor",
    desc = "Displays the last event that occurred.",
    texture = triggers.computer.texture,
    rarity = rarities.undraftable,
    synergies = { monitor_trait },
    on_place = function(e)
        e.api.show_counter { source = e.self, value = "on_place" }
    end,
    on_drop = function(e)
        e.api.set_counter { source = e.self, value = "on_drop" }
    end,
    on_after_tribute = function(e)
        e.api.set_counter { source = e.self, value = "on_after_tribute" }
    end,
    on_ball_spawn = function(e)
        e.api.set_counter { source = e.self, value = "on_ball_spawn ("..e.ball.type.name..")" }
    end,
    on_ball_carried = function(e)
        e.api.set_counter { source = e.self, value = "on_ball_carried ("..e.carryable.name..")" }
    end,
    on_ball_hat_worn = function(e)
        e.api.set_counter { source = e.self, value = "on_ball_hat_worn ("..e.hat.name..")" }
    end,
    on_ball_destroyed = function(e)
        local reason = { 
            [ball_destroyed_reasons.none] = "none",
            [ball_destroyed_reasons.consumed] = "consumed",
            [ball_destroyed_reasons.expired] = "expired",
            [ball_destroyed_reasons.exited_top_edge] = "exited_top_edge",
            [ball_destroyed_reasons.exited_bottom_edge] = "exited_bottom_edge",
            [ball_destroyed_reasons.exited_right_edge] = "exited_right_edge",
            [ball_destroyed_reasons.exited_left_edge] = "exited_left_edge",
        }
        reason = reason[e.reason]
        e.api.set_counter { source = e.self, value = "on_ball_destroyed ("..reason..")" }
    end,
    on_bonk = function(e)
        e.api.set_counter { source = e.self, value = "on_bonk ("..e.trigger.def.name..")" }
    end,
    on_earn = function(e)
        e.api.set_counter { source = e.self, value = "on_earn" }
    end,
    on_reroll = function(e)
        e.api.set_counter { source = e.self, value = "on_reroll" }
    end,
    on_trigger_placed = function(e)
        e.api.set_counter { source = e.self, value = "on_trigger_placed ("..e.trigger.def.name..")" }
    end,
    on_trigger_destroyed = function(e)
        local removed = e.reason == trigger_destroyed_effects.removed and "(removed)" or ""
        e.api.set_counter { source = e.self, value = "on_trigger_destroyed "..removed.."("..e.trigger.def.name..")" }
    end,
    on_trigger_draft_skipped = function(e)
        e.api.set_counter { source = e.self, value = "on_trigger_draft_skipped" }
    end,
    on_charges_consumed = function(e)
        e.api.set_counter { source = e.self, value = "on_charges_consumed ("..e.trigger.def.name..": "..e.amount..")" }
    end,
}

local spawn_counter = define_boon {
    id = 7,
    name = "Spawn Counter",
    desc = "Displays the total number of ball spawns that occurred.",
    texture = triggers.computer.texture,
    rarity = rarities.undraftable,
    -- use e.data to store state. it's NOT automatically saved/loaded!
    on_save = function(e)
        return tostring(e.data.count)
    end,
    on_load = function(e)
        e.data.count = tonumber(e.load)
        e.api.set_counter { source = e.self, value = tostring(e.data.count) }
    end,
    on_place = function(e)
        e.data.count = 0
        e.api.show_counter { source = e.self, value = tostring(e.data.count) }
    end,
    on_ball_spawn = function(e)
        e.data.count = e.data.count + 1
        e.api.set_counter { source = e.self, value = tostring(e.data.count) }
    end,
}

local random_draft_size = define_boon {
    id = 8,
    name = "Random Draft Size",
    desc = "The draft will randomly have between 1-5 choices.",
    texture = triggers.computer.texture,
    rarity = rarities.undraftable,
    would_offer_trigger_draft_size = function(e)
        return math.random(1,5)
    end,
}

local poor_mans_endlesss = define_boon {
    id = 9,
    name = "Poor Man's Endless Mode",
    desc = "If you survive Tribute 9, keep playing until you lose. Tribute 9 never really ends, so you won't get a boon draft or trigger \"After Tribute\" effects.",
    texture = "endless.png",
    rarity = rarities.undraftable,
    on_place = function(e)
        e.data.extra_tributes = 0
        e.api.show_counter { source = e.self, value = "Tribute "..e.api.current_tribute }
    end,
    on_save = function(e)
        return tostring(e.data.extra_tributes)
    end,
    on_load = function(e)
        e.data.extra_tributes = tonumber(e.load)
        e.api.set_counter { source = e.self, value = "Tribute "..(e.api.current_tribute + e.data.extra_tributes) }
    end,
    on_after_drop = function(e)
        if e.api.current_tribute == 9 and e.api.remaining_drops == 0 then
            if e.api.money > e.api.money_goal then
                if e.data.extra_tributes == 0 then
                    e.api.notify { source = e.self, text = "You survived the last tribute, welcome to Poor Man's Endless Mode!" }
                else
                    e.api.notify { source = e.self, text = "You survived Tribute "..(e.api.current_tribute + e.data.extra_tributes).."!" }
                end
                e.api.earn { source = e.self, base = -e.api.money, mult }
                e.api.gain_drops { source = e.self, amount = 7 }
                e.api.set_money_goal { amount = e.api.money_goal * 2 }
                e.data.extra_tributes = e.data.extra_tributes + 1
            end
        end
        e.api.set_counter { source = e.self, value = "Tribute "..(e.api.current_tribute + e.data.extra_tributes) }
    end,
}

local spawner_draft = define_trigger_draft {
    id = 1,
    accept = function (def,data)
        -- only accept spawners
        return def.traits[traits.spawner] 
    end,
    amount = 3,
}

local bag_of_spawners = define_boon {
    id = 10,
    name = "Bag of Spawners",
    desc = "Immediately draft a Spawner trigger.",
    texture = "bag.png",
    one_shot = true,
    rarity = rarities.common,
    on_place = function(e)
        e.api.push_trigger_draft { can_reroll = false, draft = spawner_draft, from = e.self.def }
    end,
}

local specific_id_draft = define_trigger_draft {
    id = 2,
    accept = function (def,data)
        -- if the id matches the specific trigger id we pushed
        return def.id == tonumber(data)
    end,
    amount = 1,
}

local bag_of_magic = define_boon {
    id = 11,
    name = "Bag of Eggs",
    desc = "Immediately draft a "..triggers.chicken.name..", a "..triggers.nest.name..", and a "..triggers.spell_of_eggsplosion.name..".",
    texture = "bag.png",
    one_shot = true,
    rarity = rarities.rare,
    on_place = function(e)
        e.api.push_trigger_draft { can_reroll = false, data = tostring(triggers.chicken.id), draft = specific_id_draft, from = e.self.def, }
        -- (note: you'll actually draft smoke if you don't have nest unlocked...)
        e.api.push_trigger_draft { can_reroll = false, data = tostring(triggers.nest.id), draft = specific_id_draft, from = e.self.def, }
        e.api.push_trigger_draft { can_reroll = false, data = tostring(triggers.spell_of_eggsplosion.id), draft = specific_id_draft, from = e.self.def, }
    end,
}

------ trigger examples

define_trigger {
    id = 1,
    name = "Event Monitor",
    desc = "Reports on events the trigger receives.",
    texture = triggers.computer.texture,
    rarity = rarities.undraftable,
    synergies = { monitor_trait },
    traits = { monitor_trait },
    cooldown = 10,
    on_place = function(e)
        e.data.events = 0
        e.api.show_counter { source = e.self, value = "on_place" }
    end,
    on_destroying = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_destroying" }
    end,
    on_after_drop = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_after_drop (total events = "..e.data.events..")" }
    end,
    on_after_tribute = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_after_tribute" }
    end,
    on_ball_spawn = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_ball_spawn" }
    end,
    on_bonk = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_bonk" }
    end,
    on_drop = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_drop" }
    end,
    on_earn = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_earn" }
    end,
    on_passive = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_passive" }
    end,
    on_reroll = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_reroll" }
    end,
    on_trigger_destroyed = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_trigger_destroyed" }
    end,
    on_trigger_placed = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_trigger_placed" }
    end,
    on_trigger_draft_skipped = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "on_trigger_draft_skipped" }
    end,
    would_offer_trigger_draft_size = function(e)
        e.data.events = e.data.events + 1
        e.api.set_counter { source = e.self, value = "would_offer_trigger_draft_size" }
        return e.amount
    end,
    on_save = function(e)
        return tostring(e.data.events)
    end,
    on_load = function(e)
        e.data.events = tonumber(e.load)
        e.api.set_counter { source = e.self, value = tostring(e.data.events) }
    end,
}

------ starter pack examples

define_starter_pack {
    id = 1,
    name = "Starter Pack Example",
    desc = "Start with a Tree, a Lake, and a few Animals.",
    texture = boons.zoo.texture, -- can refer to built-in textures this way
    drafts = {
        -- starter packs can specify specific boons, specific triggers, or triggers based on traits
        -- a starter pack is implicitly locked if any specific part of the start pack itsels is locked.
        boons.chonken,  -- specific boon
        triggers.tree,  -- specific trigger
        triggers.lake,  -- specific trigger
        traits.animal,  -- specific trigger
        traits.animal,  -- any trigger w/ animal trait
        traits.animal,  -- any trigger w/ animal trait
    }
}

define_starter_pack {
    id = 2,
    name = "Jugglernaut",
    desc = "THE JUGGLERNAUT",
    texture = triggers.juggler.texture,
    drafts = {
        boons.ear_plugs,
        triggers.juggler,
        triggers.juggler,
        triggers.juggler,
        triggers.juggler,
        triggers.juggler,
        triggers.dart_trap,
    }
}

define_starter_pack {
    id = 3,
    name = "Oops!!! All Cheese!!!",
    desc = "THE JUGGLERNAUT",
    texture = triggers.cheese.texture,
    drafts = {
        oops_all_cheese,
    }
}
