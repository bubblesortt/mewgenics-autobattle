# mewgenics-autobattle

**mewgenics-autobattle** is a mod for Mewgenics that significantly enhances the AI of cats during auto-battles. Instead of relying on generic randomness or clumsy logic, this mod assigns class-specific behavioral presets and logic conditions to ensure that your cats fight intelligently. 

Tanks will block damage and protect allies, Healers will prioritize saving dying friends instead of dealing trivial damage, Assassins (Thieves) will try to execute backstabs, and Necromancers will efficiently manage corpses and avoid suicidal spells.

## How to Use / Installation Guide

1. Download the latest release archive (`mewgenics-autobattle.zip`) from the Releases page.
2. Open **Mewtator** (the Mewgenics mod manager).
3. Install the mod by dragging and dropping the downloaded archive into the Mewtator window, or manually extract it into your active mods directory managed by Mewtator.
4. Make sure **mewgenics-autobattle** is enabled in the Mewtator mod list.
5. Launch the game through Mewtator so the custom `data/` patches are applied correctly.
6. The mod takes effect automatically during any battle encounter. Your cats will immediately start using the new customized logic profiles (`smart_fighter`, `smart_mage`, `smart_cleric`, etc.).


## How to Mod and Contribute
You can tweak existing AI behaviors or add your own by modifying the files inside the `data/` directory. When the mod loads, the game applies the files in the `data/` folder over the base game files using Mewgenics's specialized patching system.

### The GON Format and Patching Mechanics
Mewgenics uses the **GON** (Glaiel Object Notation) format for configuration files. It is lightweight and space-separated.
Instead of replacing entire original files, the mod directory uses file extensions to instruct the game on how to merge your changes:
- `[filename].gon.patch`: Modifies the targeted file using specific internal commands. Inside a `.patch` file, you can append commands like `.overwrite`, `.append`, `.merge`, `.add`, and `.multiply` to individual fields.
- `[filename].gon.merge`: Deep merges the file. It seeks out individual fields and replaces/adds just those fields without touching the rest.
- `[filename].txt.append`: Glues two files together (e.g., adding to a list).
- `[filename].csv.merge`: Overwrites CSV structures, but requires preserving comma empty values `,,,` for unchanged cells (not very future-proof).

*Example of a `.merge` operation:*
```json
smart_tank.merge {
    damage_ally -9999
    damage_enemy 1
    heal_ally 1
}
```

### Core AI Components
The modifications are separated into three main areas inside the `data/` folder:

#### 1. Decision Presets (`data/ai_presets/decision_presets.gon.patch`)
This file assigns point values (Scores) to actions. The AI will evaluate all possible actions and pick the one with the highest score.
- **Weights:** You can assign weights to actions like `damage_enemy`, `heal_ally`, `buff_self`, `kill_enemy`, `spawn_object`, etc.
- **Safety Flags:** Properties like `damage_ally -9999` ensure the AI won't accidentally kill teammates.
- **Rules:** Flags like `consider_aoe`, `consider_overkill`, and `accurate_knockback` change complex situational logic.

#### 2. Movement Presets (`data/ai_presets/move_presets.gon.patch`)
Determines where the cats want to stand.
- **Distances:** Configure `distance_to_enemy`, `distance_to_ally`, `distance_to_corpse`, and `preferred_distance` (which supports math like `mov+reach`). Positive numbers mean "move away", negative numbers mean "move closer".
- **Survival:** `danger_avoidance` controls how terrified the AI is of traps like spikes or lava. `tall_grass` makes units want to hide.

#### 3. Ability Patches (`data/abilities/*.gon.patch`)
You can inject situational logic directly into specific abilities using **Conditionals**. A common approach is giving a `FlatAIBonus` if a certain situation is met using `Conditional_Speculative`.

*Example: Make an ability highly prioritized ONLY if hitting a backstab:*
```json
SomeAttack.merge {
    damage_instance {
        ai_base_score 10
        effects {
            Conditional_Speculative {
                Conditional_Backstab {}
                Then { FlatAIBonus 50 }
            }
        }
    }
}
```
There are dozens of conditionals available in the base game: `Conditional_Ally`, `Conditional_Enemy`, `Conditional_TargetHasStatus`, `Conditional_HealthThreshold`, `Conditional_Boss`, etc. You can combine these to create highly intricate, situational behavior!

### Base Game Files You Can Modify
The original Mewgenics game includes many configuration files and folders. You can change them by creating `.patch` or `.merge` files in your own `data/` folder, which lets you modify almost every aspect of the game:

#### Artificial Intelligence (`ai_presets/`, `abilities/`)
- **`decision_presets.gon`**: Contains base line score templates (careless, angry, simple). You can completely overhaul how a class evaluates actions.
- **`move_presets.gon`**: Determines grid positioning, hazard avoidance (`danger_avoidance`), and movement behavior (`distance_to_water`, `randomness`).
- **`abilities/`**: The exact mathematical structures, AOE shapes, status applications, and AI triggers of every spell and attack. 

#### Cats and Classes (`characters/`, `classes/`, `catgen.gon`)
- Modify base stats, starting equipment, and growth curves for different classes.
- Change how cats are generated, including their names (`catnames_*.txt`) and what they say in combat (`catquotes.gon`).
- Alter mutations, injuries, and passive abilities (`mutations/`, `passives/`, `injuries.gon`).

#### Items and Equipment (`items/`, `item_pools/`)
- Rebalance weapons, armor, and consumables.
- Change which items drop from specific item pools or define new item set bonuses (`item_setbonuses.gon`).

#### World and Encounters (`maps/`, `spawns.gon`, `events/`)
- **`spawns.gon` & `maps/`**: Control which enemies appear in which biomes, their quantities, and how maps are generated.
- **`events/` & `npc_scripts/`**: Rewrite or add new narrative events, dialogue options, and NPC interactions on the world map.
- **`shops/`**: Adjust shop inventories and prices.

#### House Mechanics (`house.gon`, `furniture_effects.gon`)
- Change how furniture behaves, what buffs it provides for breeding, or how weather affects the house (`house_weather.gon`).

#### UI and Text (`text/`, `damage_text_styles.gon`)
- Localize the game into different languages or change UI text descriptions.
- Modify how damage numbers and floating combat text appear.
