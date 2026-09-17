# Shared interface style

The current interface is Lost Reality / Future Machine. See [LOST_REALITY_UI.md](LOST_REALITY_UI.md) for the design system, screen inventory, compatibility decisions and tests. This supersedes the earlier brass/leather RPG interface.

CharacterTheme is the single theme source. UIStyle adapts it for existing HUD/menu callers. Future screens should reuse these styles and the shared machine frame/components.

Control legends and hover tooltips remain removed. The contextual E prompt uses existing range/line-of-sight logic and appears at the bottom-right; it hides in menus and during transitions. See HUD_PAUSE_SAVES.md for the simplified pause menu and confirmed save deletion.

