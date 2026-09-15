# Cumulative project rules

- This is Haunted Dimension through Milestone 2, the foundation for all later milestones. Inspect and extend existing code; do not replace working systems.
- Preserve SavePoint-only manual saving, exactly three manual slots and one autosave, atomic commit/recovery, and validate-before-apply loading.
- Keep player/camera, interaction, persistence, scene management and UI responsibilities separate.
- Future gameplay systems own JSON-safe GameState namespaces and pure validators. Add sequential migrations with fixtures for schema changes. Never deserialize arbitrary objects/resources from saves.
- Stable scene/object IDs are save contracts. Preserve them or migrate them deliberately.
- New Game must always reset to Level 0, XP 0, six zero base stats, zero points and no profession. Preserve the v1→v2→v3 migration chain.
- Progression owns its GameState section. Combat and other future systems consume its stat queries/events; they must not duplicate or replace it. Balance/definition changes affecting saved invariants require migrations.
- Profession bonuses are derived from the one active profession, separate from allocated base stats. Never grant duplicate bonuses on switching or loading.
- Keep out-of-scope RPG systems out until explicitly requested in a later milestone.
- Run `tests/Run-Tests.ps1` with a Godot console executable after meaningful changes. Test storage must remain isolated from `user://saves`.
- No addons or third-party game code are used.
- Follow `docs/art/ART_DIRECTION.md` for future visual work. Art geometry/materials live under `art/`; preserve the existing gameplay collision and stable IDs when replacing render meshes.
