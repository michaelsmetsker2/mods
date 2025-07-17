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
        e.earn.gain_xmult(xmult)
        -- let's alert the player that this happened w/ a floatie if it's a trigger
        if e.trigger then
            e.api.spawn_floatie { source = e.trigger, texture = e.self.def.texture }
        end
    end,
}

local red_chip_ball_type = define_ball_type {
    id = 1,
    name = "Red Chip",
    texture = "red_chip.png",
    texture_left = "red_chip_left.png",
    texture_right = "red_chip_right.png",
}

define_boon {
    id = 2,
    name = "Chippy",
    desc = "Whenever a ball drops, spawn a Red Chip near it.",
    texture = "red_chip.png",
    rarity = rarities.common,
    on_drop = function(e)
        -- e.balls - an array of all balls dropping. slot machine can spawn more than one ball.
        for _,ball in pairs(e.balls) do
            e.api.spawn_ball { type = red_chip_ball_type, from = ball.position }
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

local cheese_eater = define_trigger {
    id = 2,
    name = "Cheese Eater",
    desc = "Earn $1,000 for each carried Cheese, then consume the Cheese.",
    texture = "cheese_eater.png",
    rarity = rarities.common,
    synergies = { triggers.cheese },
    traits = { },
    on_bonk = function(e)
        local consumed = 0
        e.api.consume_carryables { ball = e.ball, accept = function(def)
                consumed = consumed + (def == triggers.cheese and 1 or 0)
                return def == triggers.cheese
            end 
        }
        if consumed > 0 then
            e.api.earn { source = e.self, base = consumed * 1000 }                
        end
    end
}

local screamer = define_trigger {
    id = 3,
    name = "Screamer",
    desc = "Bonked ➜ Emit a Notify call",
    texture = triggers.hungry_mouth.texture,
    rarity = rarities.undraftable,
    traits = { },
    on_bonk = function(e)
        e.api.notify { source = e.self, silent = true, text = "I've been bonked!" }
    end
}

local better_battery = define_trigger {
    id = 4,
    name = "Better Battery",
    desc = color("yellow", "Each Drop").." ➜ Transfer 1 charge to each adjacent Limited trigger.",
    texture = triggers.battery.texture,
    rarity = rarities.uncommon,
    traits = { },
    on_drop = function(e)
        for adj in e.api.triggers_adjacent_to_trigger({ trigger = e.self }) do
            if adj.def.traits[traits.limited] then
                local limited = adj.as("limited")
                limited.change_charges_by(1)
            end
        end
    end
}

local simple_silo = define_trigger {
    id = 5,
    name = "Simple Silo",
    desc = "When a Plant trigger is placed adjacent to Simple Silo, destroy it and earn $10,000.\n\nWhen a Plant trigger adjacent to Simple Silo is removed, earn $10,000.",
    texture = triggers.silo.texture,
    rarity = rarities.rare,
    traits = { },
    can_earn = true,
    on_trigger_placed = function(e)
        if e.api.are_triggers_adjacent { trigger = e.self, other = e.trigger} and e.trigger.def.traits[traits.plant] then
            e.api.destroy_trigger { trigger = e.trigger, reason = trigger_destroyed_reasons.destroyed }
            e.api.earn { source = e.self, base = 10000 }
        end
    end,
    on_trigger_destroyed = function(e)
        if e.api.are_triggers_adjacent { trigger = e.self, other = e.trigger} and e.trigger.def.traits[traits.plant] and e.reason == trigger_destroyed_reasons.removed then
            e.api.earn { source = e.self, base = 10000 }
        end
    end,
}

local lucky_foot = define_trigger {
    id = 6,
    name = "Lucky Foot",
    desc = color("yellow", "Each Drop").." ➜ Each adjacent trigger gains +0.01 mult",
    texture = boons.rabbits_foot.texture,
    rarity = rarities.uncommon,
    traits = { },
    on_drop = function(e)
        for adj in e.api.triggers_adjacent_to_trigger({ trigger = e.self }) do
            e.api.gain_mult { trigger = adj, mult = 0.01 }
        end
    end,
}

local big_xmult = define_trigger {
    id = 7,
    name = "Big XMult",
    desc = "Adjacent triggers have x4.0 mult.",
    texture = "big_xmult.png",
    rarity = rarities.undraftable,
    traits = { },
    on_place = function(e)
        -- this handles the case of placing us initially in an existing board AND loading the board when continuing a game
        -- managed mults really have to be dealt with in BOTH on_place and on_trigger_placed. the save/load system does not record them!!!
        for adj in e.api.triggers_adjacent_to_trigger({ trigger = e.self }) do
            e.api.set_managed_xmult { trigger = adj, source = e.self, xmult = 4.0 }
        end
    end,
    on_trigger_placed = function(e)
        -- this handles the case of a trigger being placed in an existing board AND loading the board when continuing a game
        -- managed mults really have to be dealt with in BOTH on_place and on_trigger_placed. the save/load system does not record them!!!
        for adj in e.api.triggers_adjacent_to_trigger({ trigger = e.self }) do
            e.api.set_managed_xmult { trigger = adj, source = e.self, xmult = 4.0 }
        end
    end,
}

local br = "\n[img=bottom,1x12]res://images/empty.png[/img]"

local derpy_dragon = define_trigger {
    id = 8,
    name = "Derpy Dragon", 
    desc = "Bonked ➜ Damage the Derpy Dragon. Gain $100 per point of damage."..br.."Defeated ➜ Gain $1,000 and respawn with 1 more health",
    texture = "derpy_dragon.png",
    rarity = rarities.common,
    cooldown = 10,
    can_earn = true,
    traits = { },
    on_place = function(e)
        e.api.mixin(e.self, "attackable", {
            initial_health = 10,
            on_damaged = function(e)
                e.api.earn { source = e.self, base = 100, mult = e.amount }
            end,
            on_defeated = function(e)
                -- respawn is automatic, and occurs after the on_defeated call, so if we 
                -- bump our max_health now, the respawned Derpy Dragon will reflect it
                local attackable = e.self.as("attackable")
                attackable.max_health = attackable.max_health + 1
                e.api.cooldown { trigger = e.self, ball = e.causer }
                e.api.earn { source = e.self, base = 10000 }
            end,
        })
    end,
    on_bonk = function(e)
        local attackable = e.self.as("attackable")
        -- you have to consult the ball for how much damage should be dealt
        attackable.damage(e.ball, e.ball.damage_for(e.self))
    end,
}

-- n.b. this will CONSUME the iterator!
local count = function(iter)
    local count = 0
    for _ in iter do
      count = count + 1
    end
    return count
end

local board_report = define_trigger {
    id = 9,
    name = "Board Report", 
    desc = "Placed ➜ Perform a report on the board. Demonstrates the use of all_slots, all_triggers, is_slot_empty, and get_slot_trigger APIs.",
    texture = "board_report.png",
    rarity = rarities.undraftable,
    on_place = function(e)
        e.api.notify { source=e.self, silent=true, text="There are "..count(e.api.all_slots()).." slots"}
        e.api.notify { source=e.self, silent=true, text="There are "..count(e.api.all_triggers()).." triggers"}
        for slot in e.api.all_slots() do
            if not e.api.is_slot_empty { slot = slot } then
                local trigger = e.api.get_slot_trigger { slot = slot }
                e.api.notify { source=e.self, silent=true, text="Slot #"..tostring(slot.id).." has a "..trigger.def.name.." trigger"}
            end
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
        local removed = e.reason == trigger_destroyed_reasons.removed and "(removed)" or ""
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
    desc = "The standard trigger draft will randomly have between 1-5 choices.",
    texture = triggers.computer.texture,
    rarity = rarities.undraftable,
    would_offer_trigger_draft_size = function(e)
        if e.draft.is_standard then 
            return math.random(1,5)
        else
            return e.amount
        end
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
    desc = "The Dairy Dimension",
    texture = triggers.cheese.texture,
    drafts = {
        oops_all_cheese,
    }
}
