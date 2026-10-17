staload "data_text/script/script_data_types.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/script/script_types.sats"
fun script_data_check(s: !PropertyMap(7),e: !ScriptExtensions): ScriptDataStatus
fun script_data_make(s: PropertyMap(7),e: ScriptExtensions): ScriptDataRead
fun script_data_load(scripts: string,extensions: string): ScriptDataRead
fun script_data_dispose(data: ScriptData): void
fun script_data_set(data: !ScriptData,cp: int): ScriptSet
fun script_data_at(data: !ScriptData,set: ScriptSet,index: int): ScriptCode
fun script_data_contains(data: !ScriptData,set: ScriptSet,code: ScriptCode): bool
fun script_data_capacity(data: !ScriptData): int
