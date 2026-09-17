class_name SaveSlotPresentation
extends RefCounted
## Formats only validated store results. No IO or save mutations.
static func text(slot: int, result: Dictionary, exists: bool = false) -> String:
	var title := "AUTOSAVE" if slot == SaveConstants.AUTOSAVE_SLOT else "SAVE SLOT %02d" % slot
	if not result.ok:
		return title + ("  /  UNAVAILABLE\n" + str(result.get("error","Cannot read state.")) if exists else "  /  EMPTY")
	var data: Dictionary = result.data
	var meta: Dictionary = data.metadata
	var seconds := int(meta.playtime)
	var date := Time.get_datetime_string_from_unix_time(int(meta.timestamp)).replace("T"," ")
	var level := int(data.sections.get("progression",{}).get("level",0))
	var state := "RECOVERED" if result.get("recovered",false) else "VALIDATED"
	return "%s  /  %s\n%s  ·  LEVEL %d  ·  %02d:%02d:%02d\n%s UTC" % [title,state,LevelCatalog.title(data.scene),level,seconds/3600,(seconds/60)%60,seconds%60,date]
