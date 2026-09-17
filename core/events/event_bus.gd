extends Node
## Cross-system notifications. Commands remain on their owning services.
signal interaction_focus_changed(text: String)
signal message_requested(text: String)
signal save_menu_requested
signal scene_changed(scene_id: String)
signal save_completed(slot: int)
signal load_completed(slot: int, recovered: bool)
signal new_game_started
signal progression_changed
signal level_up(level: int)
signal progression_unlocked
signal profession_changed(previous_id: String, selected_id: String)
signal blocking_menu_opened
