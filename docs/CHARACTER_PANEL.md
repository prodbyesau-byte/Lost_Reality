# Character panel: PLAYER + SKILLS

C opens PLAYER; C or Escape closes. Drag the central model to rotate it. The preview copies only the current render hierarchy into its own 3D world, resets presentation joints, and stops rendering while hidden. It never changes the live actor, collision, camera or persistent state.

PLAYER has nine equipment sockets in a U: head, upper/lower body on the left; necklace, two rings and feet on the right; main/off hand below. Empty icons, selection and tooltips are presentation only. Equipment is unavailable until a later milestone implements it.

SKILLS shows nine unavailable disciplines in four groups. No skill level or XP is invented. CharacterSkillEntry.set_record accepts future display records; it owns no gameplay state. Attributes & profession expands the existing Milestone 2 controls, preserving their actual validation, events and save integration.

CharacterTheme and CharacterFrame now also supply the shared game-wide interface style (see SHARED_UI.md). SaveLoadMenu retains pause/input ownership and hosts the panel separately from the save/load view. No save schema change is needed.

Validation: tests/character_ui.tscn covers controls, layout, isolated preview, unavailable skill display and state preservation. tests/fullscreen.tscn checks both tabs and the progression foldout at 1920x1080, 2560x1440, 3840x2160, 1280x1024 and 3440x1440. The complete regression runner remains required.

Player realism work is explicitly paused; see docs/future/PLAYER_REALISM.md.
