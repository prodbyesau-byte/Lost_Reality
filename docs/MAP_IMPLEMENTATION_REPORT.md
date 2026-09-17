# Lost Reality — minimap & world map implementation report

Implemented and verified on 18 September 2026 in the existing Godot project. The preceding Welcome Back removal and bottom-left interaction prompt remain intact. The Windows release executable was subsequently rebuilt at `build/LostReality.exe` and passed a standalone startup check with no script or engine errors. Build output remains excluded from Git; the repository contains the source and export preset.

## 1. Files created

| File | Purpose |
| --- | --- |
| `core/map/map_manager.gd` | Exploration ownership, ray visibility, marker registry and chunk texture cache |
| `core/map/map_catalog.gd` | Trusted area/floor lookup |
| `core/map/map_area_data.gd` | Grid coordinates and cached schematic geometry |
| `core/map/exploration_schema.gd` | Compact bitmask encoding and pure validation |
| `components/map/map_trackable.gd` | Reusable dynamic registration component |
| `ui/map/map_canvas.gd` | Shared live minimap/world-map rendering and pan/zoom |
| `ui/map/map_ui.gd` | HUD placement, input, pause ownership and area/floor selector |
| `data/maps.json` | Tenement/Courtyard floor-0 definitions and stable POIs |
| `tests/map_system.gd`, `tests/map_system.tscn` | Integration, debug, resolution and restart tests |
| `tests/fixtures/milestone2_v3.json` | Existing nonzero progression/save migration fixture |
| `docs/MAP_SYSTEM.md` | Architecture, save contract, extension guide and limitations |
| `docs/MAP_IMPLEMENTATION_REPORT.md` | This implementation and verification report |

Godot `.gd.uid` companion files are included for all eight new scripts. Generated logs/screenshots remain under ignored `tests/output/`.

## 2. Files modified

| File | Change |
| --- | --- |
| `core/game.gd` | Registers player marker, adds map UI, configures `world_map` action |
| `project.godot` | Adds MapManager autoload |
| `core/state/game_state.gd` | Adds section/replacement notifications to refresh map caches on reset/load |
| `core/events/event_bus.gd` | Adds blocking-menu notification for safe map pause handoff |
| `core/save/save_constants.gd` | Save version 4 |
| `core/save/save_migrator.gd` | Adds sequential v3→v4 migration |
| `core/save/save_validator.gd` | Requires valid exploration before save application |
| `world/test_area/test_level.gd` | Attaches authored area POI components during existing level construction |
| `ui/save_load/save_load_menu.gd` | Safely takes modal ownership from an open map |
| `ui/start_screen/start_screen.gd` | Blocks M on the start screen; retains prior Welcome Back removal |
| `ui/debug/game_hud.gd` | Moves F3 overlay below minimap; retains prior bottom-left E prompt |
| `tests/Run-Tests.ps1` | Runs map, development-mode and fresh-process persistence suites |
| `tests/art_review.gd` | Updates current schema expectation and excludes intentional exploration growth from art-only invariance comparison |
| `tests/machine_ui.gd` | Updates current schema expectation |
| `tests/progression_regression.gd` | Expects latest sequentially migrated version |
| `README.md` | Documents M controls, map architecture and schema v4 |

`tests/regression.gd` also remains modified from the preceding request to expect the bottom-left interaction prompt. No save storage, serializer, progression logic, player movement, camera, existing collision or existing persistent object IDs were replaced.

## 3. Architecture summary

- A 224 × 224 north-up minimap follows the player's live position in the top-left HUD. The world map uses the same discovered data and cached terrain textures.
- A 0.5 m exploration grid reveals within a 5 m sight radius. Collision rays respect walls and doors. Visited cells stay revealed; no room/scene-wide automatic discovery occurs.
- Small masked terrain chunks are cached and drawn only within view. Player/entity markers are a separate live overlay; no duplicate world camera or per-frame scene reconstruction is used.
- `MapTrackable` supports PLAYER, NPC, ENEMY, QUEST, POI, SAVEPOINT, CUSTOM and LOCATION. Current gameplay registers only the player, Savepoints, exits and named locations. Live entities require explored terrain, current area/floor, range and line of sight.
- Stable area and floor IDs isolate discovery. Only discovered areas/floors are selectable; persistent POIs can be displayed after their scene unloads. Current content has only floor 0.
- Development reveal/clear/grid/registry tools require both a debug build and `--map-debug`.

## 4. Save schema changes

The new `exploration` GameState namespace holds per-zone dictionaries of discovered chunk masks and POI IDs. Each 16 × 16 chunk occupies 32 raw bytes / 64 hex characters, plus its JSON key. Raw images and arbitrary resources are never saved.

The migration chain is **v1→v2→v3→v4**. Older saves gain empty exploration, retaining metadata, player transform, world state, progression, profession and extension namespaces. A checked-in v3 fixture verifies preservation of a Level 1 Engineer with allocated Intelligence and unspent points. Current saves require valid map data; malformed cells, chunks, IDs, POIs and missing data are rejected before state is applied.

Exactly three SavePoint-authorized manual slots and one autosave remain. Existing atomic write/recovery, checksum and validation paths are unchanged. Load restores the exact recorded map; reveal resumes only with unpaused gameplay. New Game clears exploration without overwriting existing slots.

## 5. Input changes

- InputMap action `world_map`: **M** opens/closes the world map.
- **Escape** closes the map first; another Escape can open the normal pause menu.
- Left/middle mouse drag pans; wheel zoom interpolates smoothly; RECENTER returns to the player.
- The world map pauses gameplay. Start, pause, save and character menus retain their modal ownership; M cannot steal it. Character/interaction input cannot act through the map.

## 6. Testing performed

Engine: **Godot 4.7.2 stable**. Rendered verification: **Forward+ / NVIDIA RTX 3060 Laptop GPU / 2560 × 1440 fullscreen**.

```powershell
./tests/Run-Tests.ps1 -GodotPath 'C:\Users\Never\AppData\Local\Temp\westvale-godot\Godot_v4.7.2-stable_win64_console.exe'
```

The complete runner passed **663 assertions, zero failures**, including all original suites:

| Suite | Assertions / result |
| --- | --- |
| Gameplay / save regression | 112 passed |
| Progression / professions | 133 passed |
| Art / assets | 22 + 11 passed |
| Player visual scene | Completed without engine/script errors |
| Character UI / machine UI / pause-save-delete | 38 + 13 + 33 passed |
| Fullscreen / resolution | 125 passed |
| Map normal mode | 79 passed |
| Map explicit development mode | 81 passed |
| Map fresh-process seed / load | 2 + 3 passed |
| Existing fresh-process seed / load | 3 + 8 passed |

The map suite also passed **79 assertions in the actual graphical renderer**. Three generated screenshots were inspected: gameplay/minimap, world map and a previously visited unloaded area. The minimap remains square/top-left at 1280×720, 1600×900 and 2560×1080 logical viewport sizes; existing fullscreen tests cover further display layouts.

Specific coverage includes progressive discovery, retained cells, closed/open doors, full-height cutaway collision walls, moving blips, unregistering, wrong-floor/disabled/out-of-range hiding, an enemy hidden behind a previously explored wall, between-tick teleport visibility, exact fog texture opacity, texture-cache reuse, M/ESC priority, pause ownership, pan/zoom, all manual slots, autosave, cross-scene POIs, New Game reset, v1/v2/v3 migration, malformed state rejection and exact restoration across a fresh process. Test saves are isolated from `user://saves`.

Evidence: `tests/output/map-full-suite.log`, `tests/output/map-visual.log`, `tests/output/map_minimap.png`, `tests/output/map_world.png`, `tests/output/map_previous_area.png`. `git diff --check` passed under the repository's configured line-ending policy.

## 7. Known limitations

- The map is schematic at 0.5 m cell resolution. It represents playable floor/wall/obstacle footprints, not decorative background buildings or detailed 3D materials.
- Door collision affects discovery/visibility, but the map does not animate door leaves. Low furniture can be seen over according to the eye-height collision ray.
- Multiple area/floor addressing and selection are implemented; the current levels contain only floor 0, and no vertical-travel gameplay has been invented.
- Large streamed worlds and thousands of moving markers have not been stress-tested. Chunk rendering and reveal range are bounded, but future content may warrant marker spatial indexing and additional profiling. The existing 4 MiB save-file limit remains.
- The standalone Windows release was rebuilt from this source. The `build/` directory remains excluded from Git; clone users can reproduce the executable with the Windows Desktop export preset and Godot 4.7.2 export templates.

LOST REALITY — MINIMAP & WORLD MAP SYSTEM COMPLETE
