#include "script_test.hats"
fun tested(a: !ScriptAliases,s: !PropertyMap(7),e: !ScriptExtensions,d: !PropertyMap(8)): int = let
  val units=script_test_units(s,e,d) and rejected=script_test_rejections()
  val scripts=script_test_scripts(a,s,c_argv(5)) and extensions=script_test_extensions(s,e,c_argv(6))
  val ignorables=script_test_ignorables(d,c_argv(7))
  val ()=println!("event=script_conformance units=",units," rejection_errors=",rejected,
    " script_rows=",scripts.rows," script_points=",scripts.points," script_errors=",scripts.errors,
    " extension_rows=",extensions.rows," extension_points=",extensions.points," extension_errors=",extensions.errors,
    " ignorable_points=1114112 ignorable_errors=",ignorables)
in units+rejected+scripts.errors+extensions.errors+ignorables end
fun with_ignorables(a: !ScriptAliases,s: !PropertyMap(7),e: !ScriptExtensions): int =
  case+ property_load(c_argv(3),IgnorableProperty()) of | ~PropertyRejected(error) => 1
  | ~PropertyLoaded(d) => let val errors=tested(a,s,e,d) val ()=property_dispose(d) in errors end
fun with_extensions(a: !ScriptAliases,s: !PropertyMap(7)): int =
  case+ script_extensions_load(c_argv(2)) of | ~ScriptExtensionsRejected(error) => 1
  | ~ScriptExtensionsAccepted(e) => let val errors=with_ignorables(a,s,e) val ()=script_extensions_dispose(e) in errors end
fun with_scripts(a: !ScriptAliases): int = case+ property_load(c_argv(1),ScriptProperty()) of
  | ~PropertyRejected(error) => 1 | ~PropertyLoaded(s) => let val errors=with_extensions(a,s) val ()=property_dispose(s) in errors end
fun run(): int = case+ script_aliases_read(c_argv(4)) of | ~None_vt() => 1
  | ~Some_vt(a) => let val errors=with_scripts(a) val ()=script_aliases_dispose(a) in errors end
implement main0() = if ine(c_argc(),8) then exit(2) else let val before=mem_live()
  val errors=run() val balanced=ieq(before,mem_live())
  val ()=println!("event=script_ownership buf_balanced=",balanced)
in if igt(errors,0) orelse not(balanced) then exit(1) else () end
