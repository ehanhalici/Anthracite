staload "mem.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/script/script_types.sats"
staload "script_compile.sats"
typedef ScriptTestCounts = @{errors=int,rows=int,points=int}
fun script_test_units(s: !PropertyMap(7),e: !ScriptExtensions,d: !PropertyMap(8)): int
fun script_test_rejections(): int
fun script_test_scripts(a: !ScriptAliases,s: !PropertyMap(7),path: string): ScriptTestCounts
fun script_test_extensions(s: !PropertyMap(7),e: !ScriptExtensions,path: string): ScriptTestCounts
fun script_test_ignorables(d: !PropertyMap(8),path: string): int
