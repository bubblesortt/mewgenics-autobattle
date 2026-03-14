# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.2] - 2026-03-14
- Fix autobattle issue


## [1.0.1] - 2026-03-12

### Added
- Enemies with full damage immunity are now heavily avoided as attack targets.
- Finishing low-health enemies is now prioritized more consistently across classes.
- Cleansing allies with removable debuffs is now prioritized by Medic AI.

### Changed
- Class AI now reacts more intelligently to enemy statuses when choosing attacks.
- Melee classes are less likely to hit into `Thorns`, especially on risky multi-hit attacks.
- Attacks are less likely to be wasted into `Brace`.
- Spell-based classes are more cautious around `Counterspell`.
- AoE and control-related attacks are less likely to break `Sleep` and `Freeze` unless a kill is likely.


## [1.0.0] - 2026-03-12
- Initial public release.
