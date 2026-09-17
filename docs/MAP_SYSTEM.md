# Lost Reality — minimap and world map

The gameplay HUD has a 224 × 224 square minimap, 24 logical pixels from the top-left edge. It follows the player immediately, shows 12 metres in each direction by default, and keeps world north (negative Z) at the top. **M** opens/closes the world map; **Escape** closes the map without also opening the pause menu. Drag with the left/middle mouse button to pan, scroll to zoom, and use RECENTER to return to the player. Gameplay pauses while the full map is open.

## Ownership and data flow

| Module | Responsibility |
| --- | --- |
| `data/maps.json` | Trusted area/floor definitions, coordinate contracts and stable authored POIs |
| `core/map/map_catalog.gd` | Resolves allowlisted area/floor IDs; no save-provided paths |
| `core/map/map_area_data.gd` | World X/Z ↔ cell conversion and lazy cached terrain classification from existing layout data |
| `core/map/exploration_schema.gd` | Pure validation and compact chunk-bit encoding |
| `core/map/map_manager.gd` | Exploration, sight checks, dynamic registration, discovered POIs and masked texture cache |
| `components/map/map_trackable.gd` | Reusable child component; registers on ready and unregisters on exit |
| `ui/map/map_canvas.gd` | Shared terrain/blip presentation, clipping, live following, pan and smooth zoom |
| `ui/map/map_ui.gd` | HUD placement, world-map controls, discovered area/floor selector and pause ownership |

`MapManager` registers the `exploration` GameState namespace and validator. It commits only JSON-safe data through `GameState.set_section`. GameState section/replacement signals invalidate presentation caches on load/reset; no map state is independently serialized. The existing SaveManager snapshot, SaveSerializer checksum envelope, SaveStore atomic write/recovery, and validate-before-apply scene transition continue to own persistence. No additional save files or slots are introduced.

Both maps draw the same cached, fog-masked terrain chunks. The renderer asks only for chunks intersecting its visible bounds. A texture is rebuilt only when its 256-bit mask changes; no second world camera, full-scene render, per-frame image regeneration or world-object scan is used. Terrain colors are classified lazily from the existing floor, wall and obstacle layout, independent of detailed render meshes. Dynamic blips read the registered components' current positions each display frame.

## Exploration and visibility

The initial namespace is empty. The first unpaused physics update reveals the visible vicinity of the player; it never reveals the complete room or area. Discovery uses 0.5 m cells, a configurable 5 m radius and 0.15 s reveal interval. Rays use world collision layer 1 at eye height, respecting full-height cutaway walls and closed doors. A blocked ray reveals only the cell containing the first surface hit. Opening a door permits progressive reveal through the opening. Previously discovered cells remain visible permanently until New Game or an explicitly enabled development clear.

The player is always visible on the active floor's minimap, including before the first reveal tick. NPC/enemy/custom live markers require a discovered cell, current area/floor, distance and current line of sight. An old exploration mask is never permission to see an enemy through a wall. No NPC, enemy, combat or quest gameplay is added. Only the existing player, Savepoints, exits and named locations are registered in normal gameplay.

Static POIs are persisted by stable catalog ID, only after a range/sight discovery. Their icons remain available on the world map even if their scene has been unloaded. Rendering an icon never expands the terrain mask. The minimap clips out-of-range markers; the world map can show previously discovered static POIs farther away. Only visited areas/floors are offered by the selector (plus the current floor before its first reveal).

## Save schema v4

Sequential migration remains **v1 → v2 → v3 → v4**. The new v3→v4 step adds `exploration: {"zones": {}}` if absent. It preserves all existing progression, world state, transform, metadata and extension data. Legacy saves intentionally begin with no discovered map because they contain no exploration history. Migration never mutates the input or overwrites an existing malformed exploration section with defaults.

Example structure (mask contents abbreviated for readability):

```json
{
  "exploration": {
    "zones": {
      "tenement:0": {
        "chunks": {"1,2": "<64 lowercase hexadecimal characters>"},
        "pois": {"savepoint": true}
      }
    }
  }
}
```

A chunk contains 16 × 16 cells. Row-major bit `y * 16 + x` uses the least significant bit first within its byte. A 32-byte mask is encoded as 64 lowercase hex characters. Only nonempty chunks are saved. The schema rejects unknown area/floor/POI IDs, malformed or noncanonical chunk coordinates, invalid masks, out-of-bounds bits, empty masks and POIs whose cells were not revealed. Current v4 saves must contain valid exploration; missing/corrupt map state is not silently reset.

Loading replaces exactly the saved mask before gameplay resumes. No reveal occurs in the scene-changed signal, so loading/transition autosave cannot silently manufacture discoveries. Subsequent unpaused physics updates explore the player's current surroundings normally. Paused map/menu time does not advance exploration or playtime.

## Adding content

1. Add a stable area ID to the existing level catalog and `data/maps.json`. Area and floor IDs, grid origin, dimensions, cell size and POI IDs are save contracts; migrate existing masks deliberately if those contracts change.
2. Each floor defines a title, nonoverlapping `min_y`/`max_y` band, grid origin/size and static POIs. Floor geometry entries use a `floor` ID (defaults to `"0"`). The current two levels have only floor 0. Future floor geometry/layout loading can use the same catalog/renderer without inventing floors in current gameplay.
3. Call `MapManager.attach_area(level, area_id)` when constructing a new level to register its authored POIs. Existing level construction already does this. Scene teardown automatically unregisters these components.
4. For moving entities, add a `MapTrackable` child. Set `area_id`, `floor_id`, `marker_id`, title and category. The default visibility policy is `LIVE_SIGHT`, including for future NPCs/enemies. Set `sight_body` when the target has its own collider. Update the component's area/floor when moving between zones. Set `enabled = false` to hide it.
5. `DISCOVERED_POI` is for static IDs authored in the catalog, not a shortcut for enemy visibility. `CUSTOM`, `QUEST`, `NPC` and `ENEMY` categories are extension points; a later gameplay system must explicitly implement any special visibility policy.

## Development tools

Tools are disabled unless **both** `OS.is_debug_build()` and the explicit `--map-debug` user argument are true. Launch the editor/debug build with:

```powershell
& $GodotPath --path . -- --map-debug
```

Open M to access reveal-current-floor, clear-all-exploration, cell grid and registered-marker overlays. The marker overlay also prints the registry's IDs/areas/floors/positions. These commands change the debug session's exploration, so use isolated test saves. A release build cannot enable them even with the argument. Normal gameplay has no debug shortcuts or debug controls.

## Verification and current limits

`tests/Run-Tests.ps1` includes map integration, explicit-debug and fresh-process map seed/load tests alongside all pre-existing suites. All map tests use isolated `user://map_regression_*` / `user://map_restart_regression` directories. `tests/fixtures/milestone2_v3.json` retains a nonzero Engineer progression state for migration coverage.

This is a schematic map: it shows existing floor/wall/obstacle footprints, not decorative buildings outside the playable layout or detailed 3D art. Cell edges have 0.5 m resolution. Eye-height collision determines occlusion; short furniture does not block sight over its top. The map does not display animated door geometry, though actual door collision controls discovery and live visibility. Pan/zoom is smooth; permanent discovery is updated in small batches, not interpolated fog animation.

Multi-floor addressing, floor-specific geometry filtering and discovered-floor selection are implemented; vertical travel and additional floors do not exist in the current game. The architecture is chunked and range-bounded, but a streamed city-scale world and thousands of moving entities still require content-specific performance validation/spatial indexing. Existing save-size limits remain 4 MiB.
