staload "mem.sats"
staload "data_text/unicode_property.sats"
staload "data_text/script_types.sats"
fun script_code_valid(code: int): bool
fun script_code_implicit(code: ScriptCode): bool
fun script_extensions_parse(bytes: Buf): ScriptExtensionsRead
fun script_extensions_load(path: string): ScriptExtensionsRead
fun script_extensions_dispose(extensions: ScriptExtensions): void
(* Sparse Script_Extensions overrides; all missing entries inherit Script. *)
fun script_set(extensions: !ScriptExtensions,scripts: !PropertyMap(7),cp: int): ScriptSet
fun script_set_at(extensions: !ScriptExtensions,set: ScriptSet,index: int): ScriptCode
fun script_set_contains(extensions: !ScriptExtensions,set: ScriptSet,code: ScriptCode): bool
