# Milestone 2 verification

Verified on 2026-09-13 with Godot 4.7.2 stable, Windows, Compatibility/OpenGL renderer, NVIDIA RTX 3060 Laptop GPU.

- Project import: no script errors.
- Milestone 1 integration suite: **109 checks passed**.
- Milestone 2 progression suite: **133 checks passed**.
- Separate-process save setup: **3 checks passed**.
- Fresh-process restore: **8 checks passed**, including progression and profession bonuses.
- Total: **253 checks, zero failures**.
- Visually inspected Character screens at Level 0 and Level 1. Labels, disabled/enabled controls, bonus breakdowns and menu actions fit the viewport.
- Windows release export rebuilt with embedded game data. Export/startup logs and screenshots are generated in `tests/output/`.

The test runner uses isolated save directories and leaves the player's real manual/autosave slots untouched. Coverage includes M1 movement/camera/interaction/physics/transitions/recovery; exact New Game defaults; Level 1 gating; XP carryover and multi-level events; allocation and point conservation; profession selection/switching without stacking; progression persistence in every slot; v1/v2 migrations; malformed progression rejection before state application; and fresh-process restoration.

Placeholder balance: 100 XP for Level 1, 3 first attribute points, 2 points per later level, 50 more XP per threshold, test cap Level 100. Profession bonuses have no gameplay consumers yet. No combat, abilities, inventory, skill trees or other out-of-scope systems were added.
