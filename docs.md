# Ballionaire API Mod Docs

Up-to-date as of Ballionaire `v0.103.0`

# Overview

## Language / Runtime

Ballionaire's mod uses Lua, powered by the [MoonSharp interpreter](https://www.moonsharp.org/). Please check out the MoonSharp FAQ for differences between MoonSharp's dialect of Lua and vanilla Lua.

## Sandbox

The Lua environment is heavily sandboxed. You'll have access to `print`, `string`, `math`, and `table` APIs, but not much else. Importantly, `require` and variations of `load` are not supported; your mod must reside entirely in a single `mod.lua` file.

## How to Structure Your Mod

The game will scan and load mods once, at startup. If you need to make changes to your mod, you'll need to restart the game. If you want to unload mods, you'll need to restart the game.

Mods should live in a directory, and may contain one `mod.lua` file that the game will read and load, as well as any image files used by the mode. Those images can be referred to via a relative path in the mod code.

```
my_mod\              (this is the mod's id)
  mod.lua
  trigger.png
  other_trigger.png
```

Mods are first loaded from the Steam workshop, e.g. `C:\Program Files (x86)\Steam\steamapps\workshop\content\2667120`. Each workship item in that directory will be examined for a mod.lua file.

```
C:\Program Files (x86)\Steam\steamapps\workshop\content\2667120
  3355979752\          (this is the mod's id)
    mod.lua
    trigger.png
    other_trigger.png
```

Mods are also loaded from the `mods\` directory of the game's working directory (on Steam, where the game is installed). Ballionaire will look at eash subdirectory directly under `mods\` and check for a `mod.lua` file.

Mods are identified by the name of the directory they're in. If the mod loader detects two mods with same id, it will complain.

Please see the [Framework](#framework) section on how defined a mod in `mod.lua`.

# Framework

The Ballionaire mod API is broken down into two sections: definition functions that run at game load time for defining your mod and content such as triggers, and game functions that run at game play time, for interacting with the gameplay and making things happen!
top level of `mod.lua`

### `define_mod`

This function should be called _exactly once_, and at the top of your `mod.lua` before any other content-defining functions like `define_trigger` are called.

`define_mod(options)`

**Arguments**

- `options` (`table`, required)
  - `name` (`string`, required): the name of this mod
  - `author` (`string`, required): the author of this mod
  - `desc` (`string`, required): the description of this mod
  - `texture` (`string`, required): path to the icon that represents this mod.

**Returns**

[Result](#result)

### `define_trigger`

Call this function at the top level of `mod.lua` to define a new trigger.

`define_trigger(options)`

**Arguments**

- `options` (`table`, required)
  - `id` (`number`, required): a unique number in _this_ `mod.lua` file. Recommended to start at 1 and simply count up. `Do not` renumber triggers; the save system is based around maintaining consistent trigger ids across versions.
  - `name` (`string`, required): the name of the trigger
  - `desc` (`string`, required): the description of this trigger
  - `rarity` (`string`, required): the rarity of the trigger, see [Rarity](#rarity) for valid values.
  - `cooldown` (`string`, optional, default = `none`): the cooldown time of the trigger, see [Cooldown](#cooldown) for valid values.
  - `texture` (`string`, required): path to the texture for the trigger.
  - `traits` (array of [Trait](#trait) objects, optional): any traits this trigger should be given. You can reference custom traits, or built-in traits.
  - `synergies` (mixed array of [Trait](#trait) or [Trigger](#trigger) objects, optional): Other things this trigger synergizes with. You can supply an array of traits and/or specific triggers. Synergies only serve to hint the player; there is no functionality based on this synergy list. (Note: from a _design_ perspective, it's better to design for trait-level synergy, but specific trigger synergies are necessary sometimes and supported!)
  - `on_place` (`function`, optional): called when the trigger is placed on the board _including_ when a save game is reloaded.
    - `on_place` arguments:
      - event (table)
        - `api` ([API](#api)) - the game API
        - `self` ([Trigger](Trigger)) - this trigger
        - `data` (table) - freeform data table for this trigger
        - `continuing` (boolean) - true if the trigger is being placed due to the player choosing to continue a saved game.
  - `on_drop` (`function`, optional): called when the initial ball drop(s) occur. _NOT_ called when a ball is spawned after the drop. _IMPORTANT_: some boards may have drop multiple balls, thus this callback receives an array of balls, not just a single ball. it's called after ALL balls drops.
    - `on_drop` arguments:
      - event (table)
        - `api` ([API](#api)) - the game API
        - `self` ([Trigger](Trigger)) - this trigger
        - `data` (table) - freeform data table for this trigger
        - `balls` (array of [Ball](Ball)) - the ball(s) that dropped. will be non-empty.
  - `on_next_drop` (`function`, optional): called after scoring, while the player is waiting to initiate the next drop.
    - `on_next_drop` arguments:
      - event (table)
        - `api` ([API](#api)) - the game API
        - `self` ([Trigger](Trigger)) - this trigger
        - `data` (table) - freeform data table for this trigger
  - `on_bonk` (`function`, optional): called when the trigger is bonked by a ball. Never called while the trigger is in cooldown.
    - `on_bonk` arguments:
      - event (table)
        - `api` ([API](#api)) - the game API
        - `self` ([Trigger](Trigger)) - this trigger
        - `data` (table) - freeform data table for this trigger
        - `ball` ([Ball](Ball)) - the ball that is causing the bonk.
  - `on_update` (`function`, optional): called every frame _only while the ball is dropping_. Use sparingly!
    - `on_update` arguments:
      - event (table)
        - `api` ([API](#api)) - the game API
        - `self` ([Trigger](Trigger)) - this trigger
        - `data` (table) - freeform data table for this trigger
        - `ball` ([Ball](Ball)) - the ball that is causing the bonk.
  - `on_earn_money` (`function`, optional): called when _any_ trigger has earned money.
    - `on_earn_money` arguments:
      - event (table)
        - `api` ([API](#api)) - the game API
        - `self` ([Trigger](Trigger)) - this trigger
        - `data` (table) - freeform data table for this trigger
        - `source` ([Trigger](#trigger)) - the trigger which earned money (in the future, may include more than triggers - recommend checking that `source.class == "Trigger"` if you care that it's specifically a trigger)
        - `ball` ([Ball](#ball)) - the ball that caused the earn, if any (may be nil, e.g. for passive scoring)
        - `earn` ([Earn](#earn)) - the earnings object (can be manipulated!)
  - `on_passive_earn` (`function`, optional): called after the drop, during the passive scoring phase of the game.
    - `on_passive_earn` arguments:
      - event (table)
        - `api` ([API](#api)) - the game API
        - `self` ([Trigger](Trigger)) - this trigger
        - `data` (table) - freeform data table for this trigger

**Returns**

[TriggerDef](#triggerdef)

### `define_trigger_draft`

Call this function at the top level of `mod.lua` to define a new trigger draft function.

`define_trigger_draft(options)`

**Arguments**

- `options` (`table`, required)
  - `id` (`number`, required): a unique number in _this_ `mod.lua` file. Recommended to start at 1 and simply count up. `Do not` renumber trigger drafts; the save system is based around maintaining consistent trigger ids across versions.
  - `accept` (`function`, required): a function to accept or reject a trigger def from the trigger draft
    - `accept` arguments:
      - `def` ([TriggerDef](#triggerdef)) - the trigger def being considered for inclusion in the draft
    - `accept` return: `bool` - true to allow the trigger into the draft, or false to reject the trigger from the draft

**Returns**

[TriggerDraft](#triggerdraft)

### `define_trait`

Call this function at the top level of `mod.lua` to define a new traits (the tags that many triggers have, such as "Spawner", etc)

`define_trait(options)`

**Arguments**

- `options` (`table`, required)
  - `name` (`string`, required) The visible name of the trait. Should be globally unique, to prevent confusion
  - `definition` (`string`, optional, default: `nil`) A definitional tooltip explaining the trait.
  - `definition_priority` (`number`, optional, default: `0`) If a definition is given, specify the priority of the definition. Popups only show 3 definitions, even if more are available, ordered by this priority.

**Returns**

[Trait](#trait)

# Data Types

## API

Much of the game logic lives in the API object, which is made available in the `api` property of most content callbacks.

- `add_drops(args)` - award extra drops to the player. **IMPORTANT**: this is obviously insanely powerful from a balance perspective. Use it wisely :)
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger), required) - the trigger adding rerolls
      - `ball` ([Ball](#ball), optional) - the ball if any which caused this
      - `amount` (`number`, required) - amount of extra drops to be given to the player.
  - returns: boolean
- `add_removals(args)` - award extra removals to the player.
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger), required) - the trigger adding rerolls
      - `ball` ([Ball](#ball), optional) - the ball if any which caused this
      - `amount` (`number`, required) - amount of extra removals to be given to the player.
  - returns: boolean
- `add_rerolls(args)` - award extra rerolls to the player.
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger), required) - the trigger adding rerolls
      - `ball` ([Ball](#ball), optional) - the ball if any which caused this
      - `amount` (`number`, required) - amount of extra rerolls to be given to the player.
  - returns: boolean
- `are_slots_adjacent(args)` - determine if two board slots are adjacent
  - arguments:
    - `args` (`table`, required)
      - `slot` ([Slot](#slot), required)
      - `other` ([Slot](#slot), required)
  - returns: boolean
- `are_triggers_adjacent(args)` - determine if two triggers are adjacent
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required)
      - `other` ([Trigger](#trigger), required)
  - returns: boolean
- `ball_type(type)` - get a [BallType](#balltype) enum, given a string. [BallType](#balltype) is currently kinda different from other enums as it's represented as an object instead of a string. This is probably going to get cleaned up soon. Likely the [BallType](#balltype) object and this function will go away and the API will only use strings.
  - arguments:
    - `type` (`string`, required)
  - returns: [BallType](#balltype)
- `bounce_ball(args)` - causes a ball bounce (e.g. Mushroom effect). **TODO**: document some reference values for velocity
  - arguments:
    - `args` (`table`, required)
      - `ball` ([Ball](#ball), required)
      - `velocity` ([Vector2](#vector2), required)
  - returns: n/a
- `carry(args)` - give a carryable to a ball. Carryables are defined simply by their TriggerDef. Note, this operation can fail due to game rules, so you should check the result.
  - arguments:
    - `args` (`table`, required)
      - `ball` ([Ball](#ball), required)
      - `def` ([TriggerDef](#triggerdef), required) - trigger to carry
  - returns: boolean (`def` was carried, `true` or `false`)
- `carrying(args)` - List all TriggerDefs carried by the ball.
  - arguments:
    - `args` (`table`, required)
      - `ball` ([Ball](#ball), required)
  - returns: Lua iterator of carried [TriggerDef](#triggerdef)s
- `consume_carryables(args)` - give a carryable to a ball. Carryables are defined simply by their TriggerDef.
  - arguments:
    - `args` (`table`, required)
      - `ball` ([Ball](#ball), required)
      - `limit` (`number`, optional, default = no limit) - maximum number of carryables to consume
      - `accept` (`function`, required) - a function that accepts or rejects a carrayble from being consumed
        - arguments:
          - `carryable` ([TriggerDef](#triggerdef)) - carryable to accept or reject
        - returns: `boolean` - `true` to consume, `false` to not consume
  - returns: n/a
- `cooldown(args)` - \*_IMPORTANT_ : a trigger with cooldown must explicitly call `cooldown` in order to enter the cooling-down state. It does NOT happen automaticall when bonked!
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required)
      - `ball` ([Ball](#ball), optional) - the ball if any which is causing the cooldown
  - returns: n/a
- `destroy_ball(args)`
  - arguments:
    - `args` (`table`, required)
      - `ball` ([Ball](#ball), required) - the ball to be destroyed
      - `trigger` ([Trigger](#trigger), optional) - the trigger that caused this, if any
      - `reason` ([BallDestroyedReason](#balldestroyedreason) string, optional) - reason the ball was destroyed
      - `destroyed_effect` ([BallDestroyedEffect](#balldestroyedeffect) string, optional) - effect to play for ball destruction
  - returns: n/a
- `destroy_trigger(args)`
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required)
      - `ball` ([Ball](#ball), optional) - the ball which caused the destruction
      - `destroyed_reason` ([TriggerDestroyedReason](#triggerdestroyedreason) string, optional, default: "destroyed") - the reason the trigger was destroyed
  - returns: n/a
- `earn(args)` - cause money to be earned by a trigger, possibly attributed to a ball. **NOTE**: This API is likely to change because the game, internally, has a "declarative" scoring system, not ad-hoc assignment of scoring amounts like this API. I suggest you work in multiples of $100, and try to follow the games's existing power curve. Money earned will be displayed to the user as "base X mult" when mult > 1, or "base" when mult <= 1. Base and Mult should always be integral and will ultimately be integralized inside the game anyway if you don't make them integral. This API can also take negative bases to represent a loss.
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger), required)
      - `ball` ([Ball](#ball), optional) - the ball if any which is causing the earning
      - `base` (`number`, required)
      - `mult` (`number`, option, default = `1`)
  - returns: n/a
- `hide_counter(args)` - hide the trigger's counter, if one is visible.
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required) - trigger whose counter to hide.
  - returns: n/a
- `is_carrying(args)` - determine if a balls carrying a particular carryable.
  - arguments:
    - `args` (`table`, required)
      - `ball` ([Ball](#ball), required)
      - `def` ([TriggerDef](#triggerdef), required)
  - returns: `true` if `ball` is carrying at least one carryable of the given `def` [TriggerDef](#triggerdef)
- `mixin(trigger, type, args)` - install the given [Mixin](#mixins) in this Trigger.
  - `trigger` ([Trigger](#trigger), required) - the trigger into which to install this mixin
  - `type` (`string`, required, [Mixin](#mixins) type string) - the type of mixin to install
  - `args` (`table`, optional) - arguments for the mixin, which depend on the mixin type:
    - ager
      - `max_age` (`number`, optional, default = no maximum) - age will never exceed this number
      - `auto_age` (`bool`, optional, default = true) - ager will automatically gain one age each drop
      - `on_value_change` (`function`, optional) - callback invoked whenever the age changes.
        - `on_value_change` arguments:
          - `api` ([API](#api))
          - `self` ([Trigger](#trigger))
          - `mixin` ([Ager](#ager)) - the ager mixin itself
          - `data` (`table`) - freeform data table for this trigger
          - `change` (`number`) - amount of the change (can be positive or negative!)
    - holder
      - `initial_amount` (`number`, optional, default = 0)
      - `max_amount` (`number`, optional, default = no maximum)
      - `on_value_change` (`function`, optional) - callback invoked whenever the age changes.
        - `on_value_change` arguments:
          - `api` ([API](#api))
          - `self` ([Trigger](#trigger))
          - `mixin` ([Holder](#holder)) - the holder mixin itself
          - `data` (`table`) - freeform data table for this trigger
          - `change` (`number`) - amount of the change (can be positive or negative!)
    - limited
      - `initial_charges` (`number`, optional, default = 0)
      - `max_charges` (`number`, optional, default = no maximum)
      - `on_value_change` (`function`, optional) - callback invoked whenever the age changes.
        - `on_value_change` arguments:
          - `api` ([API](#api))
          - `self` ([Trigger](#trigger))
          - `mixin` ([Holder](#holder)) - the limited mixin itself
          - `data` (`table`) - freeform data table for this trigger
          - `change` (`number`) - amount of the change (can be positive or negative!)
    - attackable
      - WIP
    - shy
      - WIP
    - value
      - WIP
  - returns: n/a
- `place_trigger(args)`
  - arguments:
    - `args` (`table`, required)
      - `def` ([TriggerDef](#triggerdef), required)
      - `slot` ([Slot](#slot), required)
      - `with_fx` (`boolean`, optional, default = `true`)
  - returns: n/a
- `play_sound(args)`
  - arguments:
    - `args` (`table`, required)
      - `sound` ([Sound](#sound), required) valid sound name to play, see [Sounds](#sound)
- `push_trigger_draft(args)` - Cause an extra draft to be offered during the next trigger drafting phase. Drafts are placed into a stack and processed in last-in/first-out order.
  - arguments:
    - `args` (`table`, required)
      - `can_reroll` (`boolean`, required) - can the player spend a reroll to get more draft choices (using the same provided draft)
      - `draft` ([TriggerDraft](#triggerdraft), required) - the trigger draft function, which is used to determine which triggers are offered in the draft.
      - `from` ([TriggerDef](#triggerdef), optional) - if applicable, the trigger def that offered this draft; displayed to the user so they understand where the draft is coming from.
  - returns: n/a
- `replace_trigger(args)`
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required) - the trigger being replaced
      - `def` ([TriggerDef](#triggerdef), required) - the replacing trigger def
      - `ball` ([Ball](#ball), optional) - the ball if any which caused this trigger to be replace
      - `spawn_effect` ([TriggerSpawnEffect](#triggerspawneffect) string, optional, default: "sparkle") - the spawn effect to use on the replacement trigger
      - `destroyed_reason` ([TriggerDestroyedReason](#triggerdestroyedreason) string, optional, default: "forced") - the reason the replaced trigger was destroyed
  - returns: n/a
- `set_counter(args)` - Set a visible counter's value to the given string **IMPORTANT**: will NOT make the counter appear if it's currently hidden.
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required) - trigger whose counter should be set.
      - `value` (`string`, required) - initial value to display in the counter
  - returns: n/a
- `show_counter(args)` - **IMPORTANT**: triggers can only display one counter.
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required) - trigger which will show the counter.
      - `value` (`string`, required) - initial value to display in the counter
      - `color` (`string`, required) - a color given as hexadecimal, e.g. `"#f87b4b"` (TODO: document the game's palette)
  - returns: n/a
- `spawn_ball(args)` - **NOTE** If you want to access the spawned ball, do so by placing code in the `on_spawn` callback. This function does **not** return the Ball - because a ball may not always spawn when this function is called!
  - arguments:
    - `args` (`table`, required)
      - `from` ([Trigger](#trigger), required)
      - `type` ([BallType](#balltype), required)
      - `linear_velocity` ([Vector2](#vector2), optional, default = `(0,0)`)
      - `on_spawn` (`function`, optional)
        - on_spawn arguments:
          - `ball` ([Ball](#ball)) - the spawned ball
  - returns: n/a
- `spawn_floatie(args)` - Spawn a wiggly floating texture above an object or position
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger) OR [Slot](#slot) OR [Vector2](#vector2), required)
      - `texture` ([Texture](#texture), required)
  - returns: n/a
- `spawn_trigger(args)` - Spawn a new trigger in a given slot (will remove any trigger already there)
  - arguments:
    - `args` (`table`, required)
      - `def` ([TriggerDef](#triggerdef), required)
      - `slot` ([Slot](#slot), required)
  - returns: n/a
- `empty_slots_adjacent_to_trigger(args)`
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required)
  - returns: Lua iterator of adjacent [Slot](#slot)s
- `triggers_adjacent_to_trigger(args)`
  - arguments:
    - `args` (`table`, required)
      - `trigger` ([Trigger](#trigger), required)
  - returns: Lua iterator of adjacent [Trigger](#trigger)s
- `vec2(x,y)` - construct a [Vector2](#vector2)
  - arguments:
    - `x` (`number`, required)
    - `y` (`number`, required)
  - returns: [Vector2](#vector2)

## Enumerations

### BallDestroyedReason

- `consumed`
- `exited_bottom`
- `exited_top`
- `exited_left`
- `exited_right`
- `expired`

### BallType

- `arrow`
- `balloon`
- `butterfly`
- `coin`
- `egg`
- `eggplant`
- `eye`
- `fire`
- `firecracker`
- `ghost`
- `rock`
- `water`

### Rarity

- `hidden` - Won't be surfaced in Ballipedia, can't be used in the Lab. Will never be shown in a draft under any circumstances.
- `common`
- `uncommon`
- `rare`
- `innate` - _Will_ be surfaced in Ballipedia, may be used in the lab. Could be shown in a draft if the conditions of the draft allow for it.

### Sounds

**NOTE** : please regard the list as "unstable" and volatile, at least until v1.0 launches.

`air_disperse`, `air_whoosh`, `bell`, `boing`, `bomb`, `bonk`, `boom`, `bowling`, `bow2`, `bow3`, `buckaw`, `chomp`, `chop`, `coin`, `creek_open`, `dice`, `ding`, `enhance`, `fireball`, `ghost`, `glissando_descend90s`, `horn_bus`, `laugh_high_pitched_imp00`, `notification`, `oldone`, `ouch_high_pitched_imp00`, `pinball_bumper`, `place_trigger`, `pop`, `popcorn`, `pop_longer`, `rubber_stretch_down_pitch`, `rubber_stretch_up_pitch`, `score_juice_high_pitch`, `score_juice_low_pitch`, `score_juice_medium_pitch`, `shatter`, `sizzle`, `sparkle`, `splash`, `splat`, `teleport`, `thunder`, `ui_blip00`, `ui_reject00`, `ui_shop_buy00`, `whoosh`, `wood_hinge_open`, `zap`

### Cooldown

- `none` - No cooldown
- `short` - 2 seconds
- `medium` - 5 seconds
- `long` - 10 seconds
- `verylong` - 30 seconds

## Mixins

Mixins are the mechanism by which common functionality can easily be bestowed upon a Trigger. See [API](#api) for details on how install a Mixin; Mixins should typically be installed unconditionally in the `on_place` callback. There is no way to uninstall a Mixin from a Trigger. Mixins handle saving/loading their own state.

Ballionaire currently supports six types of mixins: `ager`, `holder`, `limited`, `attackable`, `shy`, and `value`.

### Ager

Represents a Trigger that ages over time. This Mixin will give the Trigger a counter that displays its current age.

- `age` (`number`) - current age of this Trigger
- `change_age_by` (`function`) - increase or decrease the age of this trigger
  - arguments :
    - `amount` (`number`) - amount to change the age by
- `change_age_by` (`function`) - increase or decrease the age of this trigger
  - arguments :
    - `amount` (`number`) - amount to change the age by
- `change_age_gain_by` (`function`) - age again is basically a multiplier on any age changes. it starts at 1.
  - arguments :
    - `amount` (`number`) - amount to change the age gain by

### Attackable

Represents a Trigger that can be damaged by balls. The Trigger is responsible for implementing whatever it means to be "exhausted" (run out of health).

- `health` (`number`) - amount of remaining health
- `damage` (`function`) - cause damage to the trigger
  - arguments :
    - `ball` ([Ball](#ball)) - the ball if any which caused the damage
- `set_health` (`function`) - set the health to a specific value without triggering damage
  - arguments :
    - `amount` (`number`) - amount to set health to

### Holder

Represents a Trigger that "holds" things like balls, carryables, or other abstract concepts. This Mixin will give the Trigger a counter that displays the number of items currently held.

- `amount` (`number`) - current amount of held things
- `deposit` (`function`) - add to the held amount in this Holder
  - arguments :
    - `ball` (`number`) -
    - `amount` (`number`) - amount to deposit in the Holder
- `withdraw` (`function`) - remove fromt he held amount in the Holder
  - arguments :
    - `amount` (`number`) - amount to withdraw from the Holder
- `clear` (`function`) - reset the held count to zero.
  - arugments :
    - (none)

### Limited

Represents a Trigger that has a limited amount of uses. Triggers are responsible for consuming their own charges, and implementing whatever it means to run out of charges. Not all Triggers are destroyed when running out of charges, so this Mixin does not handle that functionality. This Mixin will give the Trigger a counter that displays the number of charges remaining.

- `charges` (`number`) - current amount of remaining charges.
- `max_charges` (`number`) - max charges this limited trigger can hold.
- `change_charges_by` (`function`) - increase or decrease the remaining charges of this Trigger
  - arguments :
    - `amount` (`number`) - amount to change the charges by

## Objects

### Result

- `ok, msg` (tuple)
  - `ok` (`boolean`) - true if successful
  - `msg` (`string`) - meaningful only if ok = false

### Ball

- `Ball` (`userdata`)
  - `class` (`string`) - `"ball"`
  - `position` ([Vector2](#vector2)) - the global position of this Ball.
  - `linear_velocity` ([Vector2](#vector2)) - the linear velocity of this Ball.
  - `type` ([BallType](#balls)) - the type of the Ball.

### BallDestroyedEffect

- `sucked` - ball spins and shrinks and disappears, e.g. when consumed by a holder
- `splatted` - ball splats in blood, e.g. when hitting a Cactus
- `none` - no effect

### BallDestroyedReason

- `exited_bottom`, `exited_top`, `exited_right`, `exited_left` - ball left the screen, and what side specifically
- `consumed` - something ate the ball, like a holder
- `expired` - ball was forced to leave the world, e.g. due to being stuck, etc

### Earn

- `Earn` (`userdata`)
  - `Base` (`number`) - the base amount earned
  - `Mult` (`number`) - the current multiplier

### Slot

- `Slot` (`userdata`)
  - `class` (`string`) - `"slot"`
  - `position` ([Vector2](#vector2)) - the global position of this slot.

### Trait

- `Trait` (`userdata`)
  - `class` (`string`) - `"trait"`
  - `name` (`string`) - the displayable name of the trait.

There's also a global object, named `traits`, that has all the built-in traits defined on it, e.g. `traits.spawner`. The existing built-in traits are `ager`, `animal`, `attackable`, `hat`, `holder`, `carryable`, `chain`, `cluster`, `plant`, `limited`, `food`, `meal`, `ingredient`, `shy`, `mover`, `secret`, `obstacle`, `one_shot`, `permanent`, `spawner`, `scroll`, `treasure`, `unique`, `vehicle`, and `weapon`.

### TriggerDef

- `TriggerDef` (`userdata`)
  - `class` (`string`) - `"triggerdef"`
  - `name` (`string`)
  - `texture` ([Texture](#texture))
  - `traits` (`table` where keys are [Trait](#trait) objects)

There's a global object, named `triggers`, that has all teh built-in triggers defined on it,. The existing built-intriggers are:

`abyssal_donut`, `anchor`, `armored_car`, `avalanche`, `axe`, `balloon`, `battery`, `bombgoblin`, `bow`, `bread`, `brick`, `broom`, `bullseye`, `bus`, `butterfly`, `cactus`, `cairn`, `campfire`, `candle`, `capacitor`, `caprese_salad`, `cash_register`, `caterpillar`, `cave`, `cave_troll`, `cheese`, `chefs_pan`, `cherry`, `chicken`, `chthonic_pylon`, `clear_weather`, `clover`, `coin_hoard`, `compass`, `credit_card`, `credit_card_bill`, `crystal_ball`, `dam`, `dart_trap`, `diamond`, `egg_carton`, `empty_spellbook`, `empyrean_egg`, `firecracker`, `gavel`, `glue`, `gold_mine`, `grape_vine`, `greenhouse`, `grilled_cheese`, `hammock`, `happy_drama_mask`, `hole_in_one`, `house_plant`, `hungry_mouth`, `ice_cubes`, `investment_bonk`, `juggler`, `jumprope`, `jungle_hat`, `kiln`, `lake`, `lich`, `lucky_clover`, `magic_castle`, `map`, `mine_cart`, `museum`, `mushroom`, `nest`, `old_one`, `packing_tape`, `pale_chalice`, `parachute`, `piggy_bonk`, `pinball_bumper`, `pizza`, `plate`, `practice_dummy`, `pumpkin`, `radiator`, `rainbow`, `recycling_bin`, `refrigerator`, `retirement_fund`, `rock_crusher`, `running_cap`, `sad_drama_mask`, `scroll_of_divination`, `scroll_of_enprisming`, `scroll_of_invigoration`, `scroll_of_rebirth`, `scroll_of_ripening`, `seedling`, `seven`, `shopping_cart`, `skillshot`, `smokescreen`, `spellbook_of_divination`, `spellbook_of_enprisming`, `spellbook_of_invigoration`, `spellbook_of_rebirth`, `spellbook_of_ripening`, `stopwatch`, `stormy_weather`, `sword`, `tanning_chair`, `teleporter`, `thief`, `tomato`, `tophat`, `torch`, `treasure_chest`, `tree`, `volcano`, `wallet`, `watermill`, `well`, `whale`, `whistle`, `windmill`, `wisening_wand`, and `wyvern`

So for example you can refer to the pizza trigger by `triggers.pizza`

### TriggerDraft

- `TriggerDraft` (`userdata`)
  - `class` (`string`) - `"triggerdraft"`

### Trigger

- `Trigger` (`userdata`)
  - `class` (`string`) - `"trigger"`
  - `def` ([TriggerDef](#triggerdef)) - the TriggerDef for this Trigger.
  - `position` ([Vector2](#vector2)) - the global position of this trigger.
  - `slot` ([Slot](#slot)) - the slot where the Trigger has been placed.
  - `as` (`function`) - returns the given [Mixin](#mixins), if installed in the Trigger.
    - arguments :
      - mixin (`string`, required) - the name of the mixin
    - returns :
      - [Mixin](#mixins) or `nil` (if mixin is not installed in the Trigger)

### TriggerDestroyedReason

- `destroyed` - the trigger was destroyed by some kind of in-game effect, like a Limited trigger being exhausted
- `forced` - the trigger was forced to leave the game, without necessarily being destroyed, e.g. Clover turning Lucky Clover
- `removed` - the trigger was manually removed by the player using the "Remove" button

### TriggerSpawnEffect

- `none` - trigger just appears
- `sparkle` - stars appear around the trigger and a little chime plays
- `smoke` - trigger appears with a puff of dust, similarly to how it appears when placed by the player.

## Godot

### Texture

- `Texture` (`userdata`)

An opaque userdata represented a Godot Texture. You can't do anything with it, other than pass it around.

### Vector2

- `Vector2` (`userdata`)

This object is auto-bound to [Godot's Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html), so most of this documentation should apply.

## Future Improvements

- Hot reload of mods
- Code sharing via `require` or a similar mechanism
- Rich text in trigger description
- Systematized earning
- Define custom mixins
- Define custom balls
- Define custom boons
- Define custom tribulations
- Define custom sets
- Localization support
- Reference values for physics properties like gravity, velocity, force
