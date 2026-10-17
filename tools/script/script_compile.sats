staload "mem.sats"
typedef ScriptSourceRange = @{first=int,last=int,field=int,valid=bool}
typedef ScriptSourceCounts = @{valid=bool,rows=int,total=int}
datavtype ScriptAliases = ScriptAliases of (Buf,Buf,int)
fun script_source_range(b: !Buf,p: int,en: int): ScriptSourceRange
fun script_source_tag(b: !Buf,p: int,en: int): int
fun script_aliases_read(path: string): Option_vt(ScriptAliases)
fun script_aliases_dispose(aliases: ScriptAliases): void
fun script_aliases_find(aliases: !ScriptAliases,b: !Buf,p: int,en: int): int
fun script_aliases_contains(aliases: !ScriptAliases,code: int): bool
fun script_source_compile(aliases: !ScriptAliases,path: string,output: string): bool
fun script_extensions_compile(aliases: !ScriptAliases,path: string,output: string): bool
fun script_extensions_source(aliases: !ScriptAliases,b: !Buf,rows: &Buf >> Buf,tags: &Buf >> Buf): ScriptSourceCounts
fun script_extensions_write(rows: !Buf,tags: !Buf,count: int,total: int,path: string): bool
