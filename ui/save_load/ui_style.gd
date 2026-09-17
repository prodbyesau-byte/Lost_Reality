class_name UIStyle
extends RefCounted
## Shared game-wide presentation; CharacterTheme is the established visual source.
const INK := CharacterTheme.TEXT
const MUTED := CharacterTheme.MUTED
const ACCENT := CharacterTheme.ACCENT

static func panel(color: Color = CharacterTheme.SURFACE, border: Color = CharacterTheme.DIM) -> StyleBoxFlat:
	return CharacterTheme.box(color, border, 18)

static func theme() -> Theme:
	return CharacterTheme.theme()

static func label(text: String, size: int = 18, color: Color = INK) -> Label:
	return CharacterTheme.label(text, size, color, size >= 23)

static func style_dialog(dialog: ConfirmationDialog) -> void:
	dialog.theme = theme()
	dialog.min_size = Vector2i(590,180)
	dialog.get_label().add_theme_color_override("font_color",INK)
	dialog.get_label().add_theme_font_size_override("font_size",16)
