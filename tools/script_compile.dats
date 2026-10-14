#include "script_compile_internal.hats"
implement main0() =
  if ine(c_argc(),6) then exit(2) else case+ script_aliases_read(c_argv(1)) of
  | ~None_vt() => exit(1) | ~Some_vt(aliases) => let
    val scripts=script_source_compile(aliases,c_argv(2),c_argv(4))
    val extensions=script_extensions_compile(aliases,c_argv(3),c_argv(5))
    val ()=script_aliases_dispose(aliases)
    val ()=println!("event=script_compile scripts_ready=",scripts," extensions_ready=",extensions)
  in if scripts andalso extensions then () else exit(1) end
