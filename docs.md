# Ballionaire API Mod Docs

Up-to-date as of Ballionaire `v0.103.0`

# Overview

## Golden Rule

Documents can get stale, so please use `examples/mod.lua` as the source of truth if you find a contradiction between the docs and the examples :)

## Language / Runtime

Ballionaire's mods use Lua, powered by the [MoonSharp interpreter](https://www.moonsharp.org/). Please check out the MoonSharp FAQ for differences between MoonSharp's dialect of Lua and vanilla Lua. For the most part, there shouldn't be any practical differences.

## Sandbox

The Lua environment is heavily sandboxed. You'll have access to `print`, `string`, `math`, and `table` APIs, but not much else. Importantly, `require` and variations of `load` are not supported; your mod must reside entirely in a single `mod.lua` file.

I'll be working to support interactions betwene mods and mult-file mods in the future, but want to keep things simple for v1.0.

## How to Structure Your Mod

The game will scan and load mods once, at startup. If you need to make changes to your mod, you'll need to restart the game. If you want to unload mods, you'll need to restart the game.

Each Mod should live in its own directory, and must contain both a `mod.ini` and `mod.lua` file. Any image files used by the mode can also live in that directory. Those images can be referred to via a relative path in the mod code.

```
my_mod\              (this is the mod's id)
  mod.ini
  mod.lua
  trigger.png
  other_trigger.png
```

Mods are first loaded from the Steam workshop, e.g. `C:\Program Files (x86)\Steam\steamapps\workshop\content\2667120`. Each workship item in that directory will be examined for a mod.lua file.

```
C:\Program Files (x86)\Steam\steamapps\workshop\content\2667120
  3355979752\          (this is the mod's id)
    mod.ini
    mod.lua
    trigger.png
    other_trigger.png
```

Mods are also loaded from the `mods\` directory of the game's working directory (on Steam, where the game is installed). Ballionaire will look at eash subdirectory directly under `mods\` and check for a `mod.lua` file.

Mods are identified by the name of the directory they're in. If the mod loader detects two mods with same id, it will complain.

## mod.ini

The `mod.ini` file contains the basics of identifying your mod: the mod's name, the author's name, a description of the mod, an an icon representing the mod. All of this information will be display in-game in the Mods tab as well as in the Custom Run or Lab pages.

The `version` field is especially important. If you make breaking changes to your mod, such as removing content, or changing what the save/load structure is for a piece of content, you need to bump your mod's version up by 1. When the game sees a mod's version change, it will automatically cancel any in-progress run that was using the earlier version of the mod. To keep this simple, we recommend simply increasing your versio by 1 every time you publish a change to your mod.

```
[mod]
version = 1
name = "Examples"
author = "newobject"
about = "Mod API Examples"
texture = "computer.png"
```

## mod.lua

See `examples/mod.lua` for an example of how to define the content of your mod. A basic mod will typically only have top-level calls to definition functions like `define_starter_pack`, `define_boon`, etc. `mod.lua` itself is executed when the application starts, not when a run starts, so you generally don't want any gameplay logic executing at the top level of the file, because there won't be any "game" at that time.

## exports.txt

Several global values are made available to your mod, to allow you to refer to built-in content from the core gaem. These are all listed in `exports.txt` - the symbols there are verbatim how to refer to things, e.g. to refer to a Butterfly you would use `triggers.butterfly`.

The exports can and will change as the game receives updates. We'll try to make sure these changes are always backwards compatible, but we can't make any guarantees that such changes **won't** occur.

# Framework

The Ballionaire mod API is broken down into two sections: definition functions that run at game load time for defining your mod and content such as triggers, and game functions that run at game play time, for interacting with the gameplay and making things happen!
top level of `mod.lua`

### `define_board`

Coming soon :)

### `define_boon`

- `options` (`table`, required)
  - `id` (`number`, required): a unique boon id in _this_ `mod.lua` file. Recommended to start at 1 and simply count up. `Do not` renumber boons; the save system is based around maintaining consistent boon ids across versions.
  - `name` (`string`, required): the name of the boon.
  - `desc` (`string`, required): the description of the boon.
  - `texture` ([Texture](#texture), required): a texture for this boon's icons.
  - `rarity` ([Rarity](#rarity), required): the rarity of this boon.
  - `on_after_drop` (`function`, optional): called after the drop has occurred and been scored, but before payment (and possible win/loss) occurs.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
  - `on_after_tribute` (`function`, optional): called after the tribute has been satisfied. not called when the player loses, also not called at the end of the game.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
  - `on_attackable_defeated` (`function`, optional): called when an attackable trigger is defeated.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `trigger` ([Trigger](#trigger)) - the attackable trigger that was defeated.
      - `ball` ([Ball](#ball)) - the ball that caused the defeat (may be `nil`).
  - `on_ball_spawn` (`function`, optional): called when a ball spawns, either at the drop or during the drop.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `ball` ([Ball](#ball)) - the ball that spawned.
      - `trigger` ([Trigger](#trigger)) - the trigger that spawned the ball (may be `nil`)
      - `initial_drop` (boolean) - whether the ball spawn as part of the initial drop or not.
  - `on_ball_destroyed` (`function`, optional): called when a ball is destroyed.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `ball` ([Ball](#ball)) - the ball that was destroyed.
      - `reason` ([BallDestroyedReason](#balldestroyedreason)) - the reason for the ball's destruction.
  - `on_ball_carried` (`function`, optional): called when a ball carries a carryable.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `ball` ([Ball](#ball)) - the ball that spawned.
      - `carryable` ([TriggerDef](#triggerdef)) - the carryable's TriggerDef. NOT a specific Trigger instance.
  - `on_ball_hat_worn` (`function`, optional): called when a ball wears a hat
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `ball` ([Ball](#ball)) - the ball that spawned.
      - `hat` ([TriggerDef](#triggerdef)) - the hat's TriggerDef. NOT a specific Trigger instance.
  - `on_bonk` (`function`, optional): called when a ball bonks a trigger.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `ball` ([Ball](#ball)) - the ball that did the bonking.
      - `trigger` ([Trigger](#trigger)) - the trigger that was bonked.
  - `on_charges_consumed` (`function`, optional): called when a limited trigger consumes a charge.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `trigger` ([Trigger](#trigger)) - the limit trigger that consumed the charge.
      - `amount` (number) - the number of charges consumed.
      - `ball` ([Ball](#ball)) - the ball that caused the consumption. (may be `nil`)
  - `on_drop` (`function`, optional): called when the drop occurs. Note that this is only called _once_, even on a board like Slot Machine where multiple balls drop.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `balls` (array of [Ball](#ball) objects) - the balls that dropped.
  - `on_earn` (`function`, optional): called when money is earned _anywhere_.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `earn` ([Earn](#earn)) - the earn object.
      - `ball` ([Ball](#ball)) - the ball that earned money (may be `nil`).
      - `boon` ([Boon](#boon)) - the boon that earned money (may be `nil`).
      - `trigger` ([Trigger](#trigger)) - the trigger that earned money (may be `nil`).
  - `on_place` (`function`, optional): called when the boon is placed on the board _including_ when a save game is reloaded. BE VERY CAREFUL TO PAY ATTENTION TO THE `continuing` flag!!!
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `continuing` (boolean) - true if the boon is being placed due to the player choosing to continue a saved game.
  - `on_reroll` (`function`, optional): called when any draft (Trigger or Boon) is rerolled.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
  - `on_trigger_destroyed` (`function`, optional): called when a trigger destroyed, including being removed by the player. Check the reason to discern one case fromt he other.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `trigger` ([Trigger](#trigger)) - the trigger that was destroyed.
      - `ball` ([Ball](#ball)) - the ball that destroyed the trigger (may be `nil`).
      - `reason` ([TriggerDestroyedReason](#triggerdestroyedreason)) - the reason for the trigger's destruction.
  - `on_trigger_placed` (`function`, optional): called when a trigger is placed on the board _including_ when a save game is reloaded. BE VERY CAREFUL TO PAY ATTENTION TO THE `continuing` flag!!!
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `trigger` ([Trigger](#trigger)) - the trigger that was placed.
      - `continuing` (boolean) - true if the boon is being placed due to the player choosing to continue a saved game.
  - `on_trigger_draft_skipped` (`function`, optional): called when a trigger draft is skipped.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
  - `would_offer_trigger_draft_size` (`function`, optional, return type: `number`): when a trigger draft is being prepared, called with the proposed number of choices to offer. you should return the actual number of cards to be offered.
    - arguments table:
      - `api` ([API](#api)) - the game API.
      - `self` ([Boon](#boon)) - this boon.
      - `data` (table) - freeform data table for this boon.
      - `draft` ([TriggerDraft](#triggerdraft)) - the particular kind of draft occurring.
      - `amount` (number) - the proposed number of choices to offer.

⚠️ **NOTE** : Support here is preliminary, more to come! Many more `on_***` handlers coming soon! This is just a basic start.

### `define_starter_pack`

- `options` (`table`, required)
  - `id` (`number`, required): a unique starter pack id in _this_ `mod.lua` file. Recommended to start at 1 and simply count up. `Do not` renumber starter packs; the save system is based around maintaining consistent starter pack ids across versions.
  - `name` (`string`, required): the name of the starter pack
  - `desc` (`string`, required): the description of this starter pack
  - `texture` ([Texture](#texture), required): a texture for this starter pack's icons
  - `drafts` (array of [Concept](#concept) objects, required): the contents of the starter pack

See the example mod for examples of how to specify contents using a mix and mathc of [TriggerDef](#triggerdef)s, [BoonDef](#boondef)s, and [Trait](#trait)s

Some notes on starter packs:

- If any of the contents of the starter packs are locked for the player, the game will automatically show the starter pack as locked. You don't need to, and can't, control this.
- The starter packs are defined here are non-Initiate Starter Packs.
- Suggestion! You can use starter packs as a way to define special "challenges" or "game modes", e.g. where perhaps the board starts in an exact configuration: See the _""Oops!!! All Cheese!!!""_ starter pack in the example mod for some ideas.

### `define_tribulation`

Coming soon :)

### `define_trigger`

Coming soon :)

### `define_trigger_draft`

Coming soon :)

# Data Types

## API

Much of the game logic lives in the API object, which is made available in the `api` property of most content callbacks.

### Read-Only Properties

- `current_tribute` - (number) the current tribute number, 1-based
- `money` - (number) current amount of money earned this tribute.
- `money_goal` - (number) current money goal (tribute amount).
- `remaining_drops` - (number) how many drops are left before the tribute must be satisfied

### Functions

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
- `cooldown(args)` - cooldown the given trigger. **_IMPORTANT_** : a trigger with cooldown must explicitly call `cooldown` in order to enter the cooling-down state. It does NOT happen automatically when bonked!
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
      - `effect` ([BallDestroyedEffect](#balldestroyedeffect) string, optional) - effect to play for ball destruction. defaults to none.
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
      - `source` ([Trigger](#trigger) or [Boon](#boon), required)
      - `ball` ([Ball](#ball), optional) - the ball if any which is causing the earning
      - `base` (`number`, required)
      - `mult` (`number`, option, default = `1`)
  - returns: n/a
- `gain_drops(args)` - award extra drops to the player. **IMPORTANT**: this is obviously insanely powerful from a balance perspective. Use it wisely :)
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger), required) - the trigger adding rerolls
      - `ball` ([Ball](#ball), optional) - the ball if any which caused this
      - `amount` (`number`, required) - amount of extra drops to be given to the player.
  - returns: boolean
- `gain_removals(args)` - award extra removals to the player.
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger), required) - the trigger adding rerolls
      - `ball` ([Ball](#ball), optional) - the ball if any which caused this
      - `amount` (`number`, required) - amount of extra removals to be given to the player.
  - returns: boolean
- `gain_rerolls(args)` - award extra rerolls to the player.
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger), required) - the trigger adding rerolls
      - `ball` ([Ball](#ball), optional) - the ball if any which caused this
      - `amount` (`number`, required) - amount of extra rerolls to be given to the player.
  - returns: boolean
- `hide_counter(args)` - hide the trigger or boon's counter, if one is visible.
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger) or [Boon](#boon), required) - trigger or boon whose counter should be hidden.
  - returns: n/a
- `is_carrying(args)` - determine if a balls carrying a particular carryable.
  - arguments:
    - `args` (`table`, required)
      - `ball` ([Ball](#ball), required)
      - `def` ([TriggerDef](#triggerdef), required)
  - returns: `true` if `ball` is carrying at least one carryable of the given `def` [TriggerDef](#triggerdef)
- `mixin(trigger, type, args)` - install the given [Mixin](#mixins) in this Trigger. **WARNING**: this is very advanced and very under construction.
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
- `notify(args)` - Presenet a notification in the bottom right hand corner of the game screen. Use sparingly!
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger) or [Boon](#boon), options) - trigger or boon providing the notification. Its texture will appear, if provided.
      - `text` (`string`, required) - the text to display in the notification
  - returns: n/a
- `place_trigger(args)`
  - arguments:
    - `args` (`table`, required)
      - `def` ([TriggerDef](#triggerdef), required)
      - `slot` ([Slot](#slot), required)
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
      - `source` ([Trigger](#trigger) or [Boon](#boon), required) - trigger or boon whose counter should be set.
      - `value` (`string`, required) - initial value to display in the counter
  - returns: n/a
- `set_money_goal(args)` - Change the current money goal (tribute). Changing this value will _not_ immediately trigger any logic that cares about the tribute, e.g. Winner's Cup. They won't see the new money goal until the next time they would normally look at it.
  - arguments:
    - `args` (`table`, required)
      - `amount` (`number`, required) - new money goal. ensure this is a positive number.
  - returns: n/a
- `show_counter(args)` - Make a counter appear for the given trigger or boon. **IMPORTANT**: triggers and boons can only display one counter.
  - arguments:
    - `args` (`table`, required)
      - `source` ([Trigger](#trigger) or [Boon](#boon), required) - trigger or boon which will show the counter.
      - `value` (`string`, required) - initial value to display in the counter
      - `color` (`string`, optional, default: "`#f8ecd7`") - a color given as hex rgb.
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

### BallType

See the `exports.txt` file for a list of all Ball types.

### BallDestroyedEffect

See the `exports.txt` file for a list of all BallDestroyedEffects.

### BallDestroyedReason

See the `exports.txt` file for a list of all BallDestroyedReasons.

### Rarity

See the `exports.txt` file for a list of all Rarities.

### TriggerDestroyedReason

See the `exports.txt` file for a list of all TriggerDestroyedReasons.

### TriggerSpawnEffect

- `none` - trigger just appears
- `sparkle` - stars appear around the trigger and a little chime plays
- `smoke` - trigger appears with a puff of dust, similarly to how it appears when placed by the player.

## Sounds

**NOTE** : please regard the list as "unstable" and volatile, at least until v1.0 launches.

`air_disperse`, `air_whoosh`, `bell`, `boing`, `bomb`, `bonk`, `boom`, `bowling`, `bow2`, `bow3`, `buckaw`, `chomp`, `chop`, `coin`, `creek_open`, `dice`, `ding`, `enhance`, `fireball`, `ghost`, `glissando_descend90s`, `horn_bus`, `laugh_high_pitched_imp00`, `notification`, `oldone`, `ouch_high_pitched_imp00`, `pinball_bumper`, `place_trigger`, `pop`, `popcorn`, `pop_longer`, `rubber_stretch_down_pitch`, `rubber_stretch_up_pitch`, `score_juice_high_pitch`, `score_juice_low_pitch`, `score_juice_medium_pitch`, `shatter`, `sizzle`, `sparkle`, `splash`, `splat`, `teleport`, `thunder`, `ui_blip00`, `ui_reject00`, `ui_shop_buy00`, `whoosh`, `wood_hinge_open`, `zap`

### Cooldowns

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

### Ball

- `Ball` (`userdata`)
  - `class` (`string`) - `"ball"`
  - `position` ([Vector2](#vector2)) - the global position of this Ball.
  - `linear_velocity` ([Vector2](#vector2)) - the linear velocity of this Ball.
  - `type` ([BallType](#balls)) - the type of the Ball.

### Boon

- `Boon` (`userdata`)
  - `class` (`string`) - `"boon"`
  - `def` ([BoonDef](#boondef)) - the BoonDef for this Boon.

### BoonDef

- `BoonDef` (`userdata`)
  - `class` (`string`) - `"boondef"`
  - `name` (`string`)
  - `texture` ([Texture](#texture))

See the `exports.txt` file for a list of all built-in Boon definitions. So for example you can refer to the Correctional Fluid boon by `boons.correctional_fluid`

### Concept

A `Concept` is an umbrella of many things; every [TriggerDef](#triggerdef) or [BoonDef](#boondef) is a concept. Each [Trait](#trait) is a concept.

### Earn

- `Earn` (`userdata`)
  - `Base` (`number`, read-only) - the earning base
  - `Mult` (`number`, read-only) - the earning overall multiplier (see below)
  - `Scalar` (`number`, read-only) - the total value earned `Base * Mult`
  - `mult` (`function`, args: `number`) - add to the mult
  - `xmult` (`function`, args: `number`) - multiply the xmult

Earning is based on a mult/xmult model:

`(1.0 + mult) * xmult`

For example, given an Earn object `earn`, with Base: 800, Mult: 1.0

If you then call

`earn.mult(0.25)`

`earn.xmult(2)`

`earn.mult(0.25)`

The Earn object will now have an internal mult of `0.5`, an xmult of `2.0`. Plugging into the overall Mult formula: `(1.0 + 0.5) * 2.0` - the total Mult is `3.0`.

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

See the `exports.txt` file for a list of all built-in Trigger definitions. So for example you can refer to the pizza trigger by `triggers.pizza`

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

## Godot

### Texture

- `Texture` (`userdata`)

**As output _from_ the API**: An opaque userdata represented a Godot Texture. You can't do anything with it, other than pass it around. Look in the example mod to see how we repurpose a boon or trigger texture as an icon for our starter pack, e.g. `boons.zoo.texture`

**As input _to_ the API**: Either:

- An opaque userdata, as above
- _or_ if you supply a `string`, the game will attempt to load an imagee from disk at that path.

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
