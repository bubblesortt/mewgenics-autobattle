# Mewgenics mewgenics-autobattle Mod - AI Assistant Guidelines

## Overview
You are working on the **mewgenics-autobattle** mod for Mewgenics. This mod enhances the game's auto-battle AI by applying class-specific behaviors through customized scoring weights and positioning algorithms.

**CRITICAL:** All mod modifications must remain strictly within the `data/` directory. The game uses a customized patching engine over the base game's files.

## GON File Format and Patching Mechanics
Mewgenics uses **GON** (Glaiel Object Notation), a custom, whitespace-separated format.
Files inside `data/` use suffixes to dictate how they modify the base game data:
- `.gon.patch`: Applies specific, surgical operations. Inside the patch scope, use suffixes like `.overwrite`, `.append`, `.merge`, `.add`, or `.multiply` on individual fields/keys.
- `.gon.merge`: Automatically deep-merges objects. If a key exists, it alters the value. If not, it adds it.
- `.txt.append` / `.swf.append`: Simple text concatenation (e.g., loading extra assets into lists).
- `.csv.merge`: Overwrites CSV structures. Unchanged cells MUST be preserved using commas (e.g., `,,,`). This is brittle and generally discouraged unless necessary.

## Modifiable AI Targets
AI behavior is defined in three primary file types:

### 1. Decision Presets (`data/ai_presets/decision_presets.gon.patch`)
Defines the point-value (Scores) of specific actions. The AI simulates valid actions and picks the highest total score.
- **Weights:** Key values include `damage_enemy`, `heal_ally`, `buff_self`, `kill_enemy`, `revive_ally_corpse`, `spawn_object`.
- **Modifiers:** Use `damage_ally -9999` to ensure safe casting.
- **Flags:** Boolean settings such as `consider_aoe`, `consider_total_damage`, `consider_overkill`, `accurate_knockback`.

### 2. Move Presets (`data/ai_presets/move_presets.gon.patch`)
Defines spatial positioning evaluations.
- **Targets:** `distance_to_enemy`, `distance_to_ally`, `distance_to_corpse`, `distance_to_water`. (Negative = closer, Positive = farther).
- **Distances:** `preferred_distance` accepts integers or arithmetic (e.g., `mov`, `reach`, `mov+reach`).
- **Pacing:** `total_distance_moved` determines how much movement points the AI wishes to expend per turn.
- **Hazard Awareness:** `danger_avoidance` controls reluctance to step on spikes/lava. `tall_grass` adds value to ending a turn hidden.

### 3. Ability Overrides (`data/abilities/*.gon.patch`)
Abilities can be overridden to inject context-sensitive behavior via `Conditional_Speculative` effects. This manipulates `ai_base_score` on the fly.
**Available Conditionals (Use to build custom logic):**
- `Conditional_Ally`, `Conditional_Enemy`, `Conditional_Boss`, `Conditional_Corpse`
- `Conditional_HealthThreshold { threshold_percent 50% }`
- `Conditional_TargetHasStatus { status [StatusName] }`, `Conditional_SourceHasStatus`
- `Conditional_Backstab`, `Conditional_LastHit`, `Conditional_DoesDamage`
- `Conditional_Adjacent`, `Conditional_Flying`, `Conditional_DestructibleCorpse`

**Applying Bonuses:**
Use `FlatAIBonus` inside conditionals to sway the AI's likelihood of casting.
```json
// Example: Cast ONLY when hitting an enemy's back
HeavyStrike.merge {
    damage_instance {
        effects {
            Conditional_Speculative {
                Conditional_Backstab {}
                Then { FlatAIBonus 50 }
                Else { FlatAIBonus -9999 } // Disables regular casting
            }
        }
    }
}
```

## Numeric Tuning Reference
For concise numeric ranges, balancing tiers, and practical tuning workflow, use:
- `docs/ai_numeric_tuning_guide.md`

## Agent Directives
1. When modifying AI logic, prioritize surgical `.merge` or `.patch` files over outright `.overwrite` entire blobs.
2. Ensure you never use JSON-style colons or quotes for simple STR dict keys.
3. Be aware of `ai_base_score` manipulation for complex logic. Rely on existing `Conditional_` triggers defined in the game engine.

## Mini Release Guide (For Agents)
Use this flow when you need to ship a new version of the mod.

1. Confirm changes are ready:
   - `git status`
2. Bump version and add a short release note:
   - Patch release: `scripts/version.sh bump patch --note "Short summary"`
   - Minor release: `scripts/version.sh bump minor --note "Short summary"`
   - Major release: `scripts/version.sh bump major --note "Short summary"`
3. Build release archives locally:
   - `scripts/release.sh all`
   - If `7z`/`rar` tools are missing locally, build available formats (`zip`, `tar`) and continue.
4. Validate output:
   - Archives are created in `dist/` as `mewgenics-autobattle.<ext>`.
   - Each archive must contain only `data/` and `description.json`.
5. Commit and push:
   - `git add .`
   - `git commit -m "release: vX.Y.Z"`
   - `git push`
6. Create and push tag:
   - `git tag vX.Y.Z`
   - `git push origin vX.Y.Z`
7. Verify GitHub Release pipeline:
   - Workflow `Release` should publish assets to GitHub Releases.
   - Notes are pulled from the matching `CHANGELOG.md` section (`## [X.Y.Z]`).
