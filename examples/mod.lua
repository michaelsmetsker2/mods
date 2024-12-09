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

local oops_all_cheese = define_boon {
    id = 5,
    name = "Oops!!! All Cheese",
    desc = "The board starts filled with Cheese triggers. You start with 10 removals.",
    texture = triggers.cheese.texture,
    -- we mark this boon as hidden because we don't ever want someone to be able to draft it.
    rarity = rarities.hidden,
    on_place = function(e)
        -- this isn't really great because this will run before tribulations, so it could block out 
        -- roaming nihility, for example
        for slot in e.api.all_slots() do
            e.api.gain_removals { source = e.self, amount = 10 }
            e.api.place_trigger { def = triggers.cheese, slot = slot, with_fx = false }
        end
    end
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
