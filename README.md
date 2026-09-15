# Haunted Dimension — Milestone 2

**Visual quality upgrade:** the Tenement and Courtyard follow the [3D art-direction guide](docs/art/ART_DIRECTION.md), with shaped sedans, branching trees, pitched-roof suburban architecture, upholstered furniture, articulated human visuals, and distinct PBR surface maps. Fullscreen is permanent. Gameplay and save schema remain Milestone 2.

An original Godot 4, true 3D RPG foundation with Level 0 progression, six base attributes and a data-driven profession framework. Milestone 1 movement, camera, interaction, scenes and saves are preserved. Combat, inventory, quests and other future gameplay systems are not implemented.

## Run

Import [project.godot](project.godot) in Godot 4 and press **F6 on `core/game.tscn`** or **F5** to run the project. The project is verified with **Godot 4.7.2 stable** on Windows / NVIDIA RTX 3060 Laptop GPU. The art pass uses Forward+ by default; the earlier foundation used Compatibility. Older engine builds have not been regression-tested.

Alternatively, run `./Run-Game.ps1 -GodotPath 'C:\path\to\Godot_console.exe'`. Set `GODOT_PATH` to avoid supplying the path each time. No external addons or assets are required.

The standalone Windows build is `build/HauntedDimension.exe`. All game data is embedded in the executable; Godot does not need to be installed to play it.

**F4** switches Atmospheric/Performance profiles while playing. Performance removes optional effects, local light shadows and secondary clutter while preserving curved and bevelled asset silhouettes. On older graphics hardware, launch `HauntedDimension.exe --rendering-method gl_compatibility`; unsupported SSAO/volumetric effects are disabled automatically. Profiles are presentation-only and do not change saved data.

## Controls

| Control | Action |
| --- | --- |
| WASD / arrow keys | Camera-relative eight-direction movement |
| Mouse wheel | Smooth orthographic zoom, size 10–28 |
| E | Interact with nearest reachable object |
| Escape | Pause / load menu; return to game |
| C | Character / Progression panel; close it with C or Escape |
| F3 | Position, speed, zoom, playtime and FPS overlay |
| F4 | Atmospheric / Performance visual profile |

The player begins in the Refuge. Walk next to the labelled **SavePoint** cabinet/work light and press E to save. The nearby standing work lamp can be toggled. A wooden door in the north partition opens into the Passage; the signed metal entrance at its far end leads to the Courtyard. The east gap connects the Refuge and Hall. Camera-facing walls retain a visual cutaway and their full collision height. The SavePoint visual remains provisional.

## Progression / New Game

Each launch begins a New Game; use Escape → Load to continue a saved character. Escape → **New Game** also starts fresh after an unsaved-progress confirmation. Every New Game resets the scene, world state, playtime and progression: **Level 0, XP 0, no profession, all six base stats 0, no attribute points, all professions locked**. Existing save slots are retained; New Game never overwrites an autosave.

Open **C** and use **DEBUG: Award 100 XP** to test progression. There are no natural XP sources yet. The first 100 XP reaches Level 1 and grants 3 attribute points. Use the + buttons to allocate points. Engineer, Police Officer and Paramedic unlock at Level 1; none is chosen automatically.

Placeholder tuning lives in `data/progression.json`: each next-level requirement is `100 + 50 × current_level`, later levels grant 2 points, and the test cap is Level 100. XP is progress **within the current level**; surplus crosses thresholds, awarding each level once. At the cap, XP is 0 and additional awards are rejected. Multi-level awards emit each level-up after the whole valid state is committed. Loading does not replay rewards.

Profession definitions live in `data/professions.json`. They include stable ID, name, description, minimum-level/base-stat requirements, starting stat bonuses, stat modifiers and a skill-modifier dictionary (empty until actual skills exist). Only one selected ID is stored. Unlocked professions can be switched for testing. Starting bonuses and modifiers are derived only from the active profession; switching/loading never stacks them, adds free points or changes base attributes. Their tuning is provisional. Attribute allocation is one point per click, with no respec in this milestone.

Strength, Fitness, Dexterity, Perception, Intelligence and Willpower have **no hardcoded gameplay effects**. Future systems can read `Progression.base_stat(id)`, `stat_bonus(id)`, `effective_stat(id)` and `skill_modifiers()`. No combat, profession abilities or skill system has been added.

## Save behavior

- Exactly **three manual slots** (1–3) and **one autosave** (0).
- Manual saving requires a live SavePoint session. The manager checks the actual SavePoint type, distance and unobstructed line of sight. Closing the menu, leaving range, transitioning, loading or completing a save revokes permission. Escape never grants saving access.
- Every occupied manual slot, including a corrupted slot, requires confirmation. The confirmation includes the revision of all slot artifacts; stale confirmations cannot overwrite changed data.
- Successful travel autosaves the **destination** entrance after collision registration. First launch and loading a save never autosave.
- Saving captures UTC timestamp, active unpaused playtime, stable scene ID, player position/rotation and all persistent GameState namespaces. The required `progression` section includes level, within-level XP, base stats, unspent points, profession unlocks and selected profession.
- Saves use a JSON envelope with SHA-256 over the exact payload string. Structural, version, numeric, scene and position checks run before state is applied. Hashes detect corruption, not intentional cheating.
- Writes stage and flush a same-directory temporary file, read it back through the validation pipeline, retain a verified previous backup, then rename over the primary without deleting the primary first.
- Reads prefer primary → backup → verified temporary file. Recovery is explicitly indicated in the menu and load message. A valid backup is never replaced by a corrupt primary. Loading does not rewrite recovery files; the next successful save repairs the primary.
- Format version is **3**. Existing Milestone 1 version 2 saves gain zeroed Level 0 progression through migration, preserving metadata, transforms, world state and unknown namespaces. The sequential v1 → v2 → v3 chain is tested. Missing progression in a v3 save, invalid point budgets, inconsistent unlocks and locked/unknown selected professions are rejected before applying state. Saves from newer formats remain protected. Westvale's unrelated schema was never supplied, so compatibility with Westvale itself is not claimed.
- Data lives at `user://saves` (normally `%APPDATA%\Godot\app_userdata\Haunted Dimension\saves` on Windows). `.bak` and `.tmp` files belong to their slot, not extra user-facing slots.

## Architecture / important files

| File or directory | Responsibility |
| --- | --- |
| `core/game.gd`, `core/game.tscn` | Persistent game shell and input setup |
| `actors/player/` | CharacterBody3D movement and independent orthographic follow rig |
| `components/interaction/` | Reusable interaction contract, nearest-target selection and line of sight |
| `core/scene_management/scene_router.gd` | Stage, validate and commit levels; restore player; transition autosave |
| `core/scene_management/level_catalog.gd` | Stable scene IDs and content allowlist |
| `core/state/game_state.gd` | Defensive copies of JSON namespaces, extension validation, playtime |
| `core/progression/progression.gd` | XP awards, allocation, single active profession, stat queries and events |
| `core/progression/progression_schema.gd` | Level 0 defaults and cross-field validation |
| `core/progression/progression_rules.gd`, `stat_catalog.gd`, `profession_catalog.gd` | Progression tuning and data contracts |
| `data/progression.json`, `data/professions.json` | Editable XP/point tuning and profession definitions |
| `core/events/event_bus.gd` | Cross-system notifications |
| `core/save/save_manager.gd` | SavePoint authorization, captures and load orchestration |
| `core/save/save_store.gd` | Atomic commits, bounded reads, revisions and recovery |
| `core/save/save_serializer.gd` | JSON envelope, checksum and transform conversion |
| `core/save/save_validator.gd` | Semantic and structural validation |
| `core/save/save_migrator.gd` | Sequential version migrations |
| `core/save/save_constants.gd` | Format, version, paths, limits, exact slot configuration |
| `data/*.json`, `world/test_area/` | Data-driven greybox layouts, geometry and safe placement checks |
| `world/interactables/` | SavePoint, door, lamp and level exits |
| `ui/save_load/`, `ui/debug/` | Paused slot menu, confirmations, feedback and debug overlay |
| `ui/character/character_panel.gd` | Character panel hosted inside the existing pause menu |
| `tests/regression.gd` | Scene-tree, filesystem and fresh-process regression tests |
| `tests/progression_regression.gd`, `tests/fixtures/milestone1_v2.json` | Progression integration, invalid data, New Game and old-save compatibility |
| `art/materials/`, `art/meshes/`, `art/presentation/` | Shared visual-only materials, meshes, dressing, lighting, quality profiles and vignette |
| `actors/player/human_visual.gd` | Ordinary human presentation and simple walk cycle, independent of movement physics |
| `data/art_direction.json`, `data/*_art.json` | Palette/material tuning and level art dressing |
| `tests/art_review.gd` | Visual profile, LOD, collision-preservation checks and rendered screenshots/metrics |

## Extending in Milestone 3

Preserve these systems. A future system can store a dictionary with `GameState.set_section("its_namespace", data)` and retrieve a defensive copy with `get_section`. Values must be JSON-safe; encode vectors/IDs explicitly. Register a pure validator with `register_section` during startup. Its optional default dictionary makes the section required and restores defaults on every New Game. Unknown namespaces round-trip unchanged. Listen for `EventBus.load_completed` and `new_game_started` to rebuild runtime views, or read GameState directly. Commit changes to GameState when they happen so snapshots remain authoritative.

Progression has one authoritative GameState section and no duplicate cached character state. Future XP sources call `Progression.award_xp(amount)`. Combat can consume effective stats and listen to `progression_changed` without owning XP, allocation or saves. `level_up(level)`, `progression_unlocked` and `profession_changed(previous_id, selected_id)` announce actual runtime changes; load/new-game refreshes emit `progression_changed` without awarding anything. The profession requirement evaluator supports level and allocated base-stat requirements. To expand professions, add data and migrate existing unlock maps. To change XP curves, point budgets, stat IDs or persisted rules, add a migration and fixtures; changing those contracts without migration may invalidate older characters.

Use stable IDs for persistent world objects. Add levels to the catalog and implement the existing level contract (`spawn_position`, `apply_persistent_state`, `position_is_safe`). Extend the migration chain and add fixtures whenever the save schema changes; never replace the save pipeline. Tests use injected directories and must not touch real user saves.

## Regression tests

Run `./tests/Run-Tests.ps1 -GodotPath 'C:\path\to\Godot_console.exe'`. Add `-Visual` to run with the real renderer and capture gameplay/menu and Level 0/1 character images to `tests/output`. The runner imports the project, executes both milestone suites, then saves and loads in **two separate engine processes**. It fails on either a nonzero exit code or an engine script/error diagnostic.

Coverage includes camera directions and limits, acceleration/deceleration, floor/wall/obstacle physics, object range/visibility, door collision safety, E-key SavePoint interaction, permission revocation, overwrite confirmation, all four slots, metadata, schema/hash/size corruption, recovery, migrations, future format protection, unknown namespaces, extension validation, I/O failure, scene rollback, safe loaded positions, transition autosaves, paused loading and fresh-process persistence.

Milestone 2 adds initial defaults, C-key input, paused movement, Level 1 gates, exact thresholds, multi-level XP, point conservation, profession switching without bonus duplication, active-stat queries, all-slot progression persistence, M1 migration, malformed progression rejection, New Game preservation of save slots, the level cap and fresh-process progression restoration.

## Fullscreen desktop policy

The project opens directly in Godot `MODE_FULLSCREEN` (desktop borderless fullscreen). `core/display/display_policy.gd` centrally retains that mode even while paused, consumes Alt+Enter/keypad Enter and F11, and checks restoration after display changes. Minimize and Alt-Tab remain available. Deferred window callbacks avoid re-entering the Windows display API during a resize.

The desktop determines physical resolution. No monitor mode or forced window-size workaround is used. Canvas-item scaling with Expand preserves at least the 1440×900 UI design space without distorting text. The orthographic camera retains vertical framing on wide displays and expands its vertical view on narrow displays to preserve baseline horizontal visibility.

`tests/fullscreen.gd` checks startup, mode-change recovery, paused menus, shortcut handling, camera framing and menu containment. With `-Visual`, embedded render surfaces exercise 1920×1080, 2560×1440, 3840×2160, 1280×1024 and 3440×1440 and save exact-size screenshots. Native fullscreen is tested on the available 2560×1440 desktop; the other sizes are rendered coverage, not physical monitor mode switches.

## Known limits

- The original procedural art kit now includes architecture, cars, upholstered furniture and organic vegetation. The human has articulated knees/elbows, but final skinned animation, audio and dynamic roof visibility remain future work. Surrounding shops, civic buildings, roads and trees are visual scenery outside the existing playable boundaries, not new playable locations. The generated reference board is a concept target, not a gameplay screenshot.
- Levels are small authored test areas; loading and capped 4 MiB save writes are synchronous. Streaming and background I/O are not part of this milestone.
- Atomic rename and validated backups protect application-level interrupted writes. Absolute durability during sudden hardware/power failure depends on the OS/filesystem; Godot's flush is not a cross-platform disk `fsync` guarantee. Network filesystems and simultaneous game processes writing the same slots are not supported.
- Windows/Godot 4.7.2 was tested. The Windows standalone build receives a startup smoke test. Other platforms have not been verified.
