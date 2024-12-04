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

--[[

------ drafts

draft_spawners = define_trigger_draft {
    id = 1,
    accept = function (def)
        return def.traits[traits.spawner]
    end
}

------ traits

traits.electronic = define_trait {
    name = "Electronic",
    definition = "I dunno I guess it's electric",
    definitionPriority = 1000,
}

------ triggers

tombstone = define_trigger {
    id = 1,
    name = "tombstone",
    rarity = "common",
    cooldown = "verylong",
    desc = "",
    texture = "res://mutators/textures/tombstone.png"
}

test_add_resources = define_trigger {
    id = 2,
    name = "test_add_resources",
    rarity = "common",
    cooldown = "verylong",
    desc = "Test adding resources",
    texture = "res://triggers/textures/computer.png",
    traits =  { traits.electronic, traits.creator },
    on_bonk = function (e)
        e.api.add_drops { source = e.self, ball = e.ball, amount = 1 }
        e.api.add_removals { source = e.self, ball = e.ball, amount = 1 }
        e.api.add_rerolls { source = e.self, ball = e.ball, amount = 1 }
    end,
}

test_create_destroy_triggers = define_trigger {
    id = 3,
    name = "test_create_destroy_triggers",
    rarity = "common",
    cooldown = "verylong",
    desc = "Test creating and destroying triggers",
    texture = "res://triggers/textures/computer.png",
    traits =  { traits.electronic, traits.creator },
    on_bonk = function (e)
        -- spawn smoke in all adjacent empty slots
        for slot in e.api.empty_slots_adjacent_to_trigger { trigger = e.self } do
            e.api.spawn_trigger { def = triggers.smoke, slot = slot }
        end
        -- replace ourselves with a trash can
        e.api.replace_trigger { trigger = e.self, def = triggers.trash_can, ball = e.ball, spawn_effect = "smoke", destroyed_reason = "destroyed" }
    end,
}

test_carry = define_trigger {
    id = 4,
    name = "test_carry",
    rarity = "common",
    cooldown = "verylong",
    desc = "Test carrying triggers",
    texture = "res://triggers/textures/computer.png",
    traits =  { traits.electronic, traits.creator, traits.carryable },
    on_bonk = function (e)
        e.api.carry { ball = e.ball, def = triggers.trash_can }  -- yes you can carry anything, technically :)
        e.api.carry { ball = e.ball, def = triggers.tomato } 
        e.api.carry { ball = e.ball, def = triggers.sword } 
    end,
}

test_consume_carryables = define_trigger {
    id = 5,
    name = "test_consume_carryables",
    rarity = "common",
    cooldown = "verylong",
    desc = "Test consuming carryables",
    texture = "res://triggers/textures/computer.png",
    traits =  { traits.electronic, },
    on_bonk = function (e)
        local consumed = 0
        e.api.consume_carryables { ball = e.ball, limit = nil, accept = function()
            consumed = consumed + 1
            return true
        end }
        e.api.earn { source = e.self, ball = e.ball, base = 100, mult = consumed }
        e.api.destroy_ball { source = e.self, ball = e.ball, reason = "consumed", destroyed_effect = "consumed" }
    end,
}

test_push_trigger_draft = define_trigger {
    id = 6,
    name = "test_push_trigger_draft",
    rarity = "uncommon",
    desc = "Testing awarding trigger drafts",
    texture = "res://triggers/textures/computer.png",
    on_bonk = function(e)
        e.api.push_trigger_draft { can_reroll = false, draft = draft_spawners, from = test_push_trigger_draft }
    end,
}

test_bounce = define_trigger {
    id = 7,
    name = "test_bounce",
    rarity = "uncommon",
    cooldown = "short",
    desc = "Testing for bounce api",
    texture = "res://triggers/textures/computer.png",
    on_bonk = function(e)
        e.api.cooldown { trigger = e.self, ball = e.ball }
        e.api.play_sound { sound = "boing" }
        e.api.bounce_ball { ball = e.ball, velocity = e.api.vec2(0,-2000) }
    end,
}

test_ager = define_trigger {
    id = 8,
    name = "test_ager",
    rarity = "uncommon",
    desc = "Testing for ager mixin",
    traits =  { traits.ager },
    texture = "res://triggers/textures/computer.png",
    on_place = function(e)
        e.api.mixin(e.self, "ager", { 
            auto_age = true,
            display = function (v)
                return "Age: "..v
            end,
            on_value_change = function (e)
                print("test_ager age changed by "..e.change.." to "..e.self.as("ager").age)
            end 
        })
    end,
    -- we don't need to do this because auto_age = true, but we could do it manually instead
    -- on_drop = function(e)
    --     e.self.as("ager").change_age_by(1)
    -- end,
    on_bonk = function(e)
        e.api.earn { source = e.self, ball = e.ball, base = 100, mult = e.self.as("ager").age }
    end,
}

test_holder = define_trigger {
    id = 9,
    name = "test_holder",
    rarity = "uncommon",
    desc = "Testing for holder mixin",
    traits =  { traits.ager },
    texture = "res://triggers/textures/computer.png",
    on_place = function(e)
        e.api.mixin(e.self, "holder", { 
            initial_amount = 1,
            max_amount = 5,
            display = function (v)
                return "Holding: "..v
            end,
            on_value_change = function (c)
                -- when we hold 5 things, clear it and earn $10,000
                if c.mixin.amount >= 5 then
                    c.mixin.clear()
                    -- note we're using c.ball here to actually attribute the earnings to the ball, IF a ball caused this change
                    e.api.earn { source = e.self, ball = c.ball, base = 10000 }
                end
            end 
        })
    end,
    on_bonk = function(e)
        e.self.as("holder").deposit(1)
        e.api.destroy_ball { source = e.self, ball = e.ball, reason = "consumed", destroyed_effect = "consumed" }
    end,
    -- we don't need to do this because auto_age = true, but we could do it manually instead
    -- on_drop = function(e)
    --     e.self.as("ager").change_age_by(1)
    -- end,
}

test_limited = define_trigger {
    id = 10,
    name = "test_limited",
    rarity = "uncommon",
    desc = "Testing for limited mixin",
    traits =  { traits.limited },
    texture = "ballionaire.png",
    on_place = function(e)
        e.api.mixin(e.self, "limited", { 
            initial_charges = 5,
            max_charges = 20,
            on_value_change = function (c)
                -- when we're out of charges, just die
                if c.mixin.charges <= 0 then
                    e.api.destroy_trigger { trigger = e.self, ball = c.ball, destroyed_reason = "destroyed" }
                end
            end 
        })
    end,
    on_bonk = function(e)
        local limited = e.self.as("limited")
        if limited.charges > 0 then
            limited.change_charges_by(-1)
            e.api.spawn_ball { from = e.self, type = e.api.ball_type("eggplant") }
        end
    end,
}

]]--