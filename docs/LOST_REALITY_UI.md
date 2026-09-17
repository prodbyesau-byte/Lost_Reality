# Lost Reality — Future Machine interface

This is the existing Demon Time / Haunted Dimension project, renamed in place. Gameplay, stable IDs, scenes, progression, SavePoint authorization, three manual slots, one autosave, atomic recovery and v1→v2→v3 migration contracts are unchanged.

## Screen inventory and implementation

- Main menu: Lost Reality branding, user-supplied datacenter background (`pictures/startscreen.png`, aspect-preserving cover), New Game / Load / Settings / Quit, keyboard focus and Escape-to-main navigation.
- Configuration: existing quality/fullscreen information; optional session-only interference switch under Accessibility. No unsupported settings categories are invented.
- Save/load and pause: stored-state cards with actual location, level, timestamp, playtime, validation/recovery status and existing actions.
- Confirmations: shared machine window, text and button styles.
- PLAYER / SKILLS: technical frame, measurement grid, unchanged live-appearance preview and U sockets; existing progression controls preserved. Unimplemented skills/equipment remain unavailable.
- HUD: compact actual level/XP, location, transient messages, E above the player, existing debug display and a scene-busy indicator. No fictional health, conditions or corruption percentages.

## Shared code

`ui/character/character_theme.gd` remains the single theme source; its existing class/path is retained deliberately. Semantic tokens TEXT, MUTED, ACCENT, DIM, SURFACE, WARNING and ERROR replace the old brass/bone palette. `ui/save_load/ui_style.gd` is a compatibility adapter, not a second theme. Buttons, tabs, bars, popups, scrollbars and future sliders share these values. Windows use Segoe UI and Consolas with system fallbacks.

`CharacterFrame` supplies a clipped-corner machine enclosure. `CharacterBackdrop` supplies a quiet measurement grid. The start scene uses the supplied datacenter image with aspect-preserving cover scaling. `SaveSlotPresentation` formats validated results for both loading screens, with no storage writes.

`MachineInterference` draws two faint lines only within the top frame rail, for at most 120 ms, at randomized 24–45 second intervals after an initial 18–34 second delay. It never changes text, input targets, data, focus or layout. Invisible panels suspend the effect. Accessibility disables it for the session.

## Compatibility and scope

The visible application name and Windows product metadata are Lost Reality. The new executable is `build/LostReality.exe`. The explicit custom user directory resolves to the exact legacy `Godot/app_userdata/Haunted Dimension` directory; the save envelope identifier remains `haunted-dimension-save`. These internal legacy names are intentional compatibility contracts, not visible branding.

The user replaced the old menu artwork with `pictures/startscreen.png`; the new image is included in the standalone export. World art and the paused player-model work are unchanged. There is no existing inventory/combat/audio backend. No fake inventory, health, abilities or sounds were added. Final UI audio and persistent accessibility preferences can be added later; no temporary audio or third-party bitmap assets are used.

## Verification

The complete regression runner covers gameplay, interaction, camera, progression, saves, migrations, restart persistence, character controls, display policy and visual assets. Machine UI tests cover branding, legacy storage path, menu routing, interference timing/disable behavior and save-state presentation. Fullscreen tests render main/settings/load plus gameplay, character and pause UI at 1080p, 1440p and 4K, with existing additional aspect-ratio coverage.

