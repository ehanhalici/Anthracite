#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/property_symbols.sats"
staload "data_text/unicode/property_source.sats"

typedef source_range = @{first=int,last=int,value=int}

fun source_range_of{kind:int}(domain: PropertyDomain(kind), b: !Buf, start: int, en: int): source_range = let
  var p: int = start
  val first = text_hex(b,p,en)
  val last = if ieq(buf_get(b,p),CHAR_DOT) then let val () = p := iadd(p,2) in text_hex(b,p,en) end else first
  val field = text_skip_space(b,iadd(text_find_byte(b,p,en,59),1),en)
in @{first=first,last=last,value=property_symbol_of(domain,b,field,en)} end

fun assign_range {n:nat} .<n>. (n: int(n), dense: !Buf, cp: int, value: int): void =
  if n = 0 then () else let val () = buf_set32(dense,cp,value) in
    assign_range(n-1,dense,iadd(cp,1),value) end

fun apply_row{kind:int}(domain: PropertyDomain(kind), b: !Buf, p: int, en: int, dense: !Buf): bool = let
  val row = source_range_of(domain,b,p,en)
  val valid = ige(row.first,0) andalso ige(row.last,row.first) andalso ilt(row.last,UNICODE_SCALAR_LIMIT)
    andalso ige(row.value,0) andalso ile(row.value,property_domain_max(domain))
in if not(valid) then false else let
    val () = assign_range(airlock_nat(iadd(isub(row.last,row.first),1)),dense,row.first,row.value)
  in true end end

fun requested{kind:int}(domain: PropertyDomain(kind),b: !Buf,p: int,en: int): bool = case+ domain of
  | IgnorableProperty() => let val field=text_skip_space(b,iadd(text_find_byte(b,p,en,59),1),en)
    in text_token_is(b,field,en,"Default_Ignorable_Code_Point") end
  | ModifierMarkProperty() => let val field=text_skip_space(b,iadd(text_find_byte(b,p,en,59),1),en)
    in text_token_is(b,field,en,"Modifier_Combining_Mark") end
  | ScriptProperty() => true | WordProperty() => true | BidiProperty() => true
  | JoiningProperty() => true | LineProperty() => true | EastAsianProperty() => true | CategoryProperty() => true
fun source_row{kind:int}(domain: PropertyDomain(kind), b: !Buf, p: int, en: int, dense: !Buf): bool =
  if ige(p,en) then true
  else if text_token_is(b,p,en,"# @missing:") then
    let val start=text_skip_space(b,iadd(p,11),en)
    in if requested(domain,b,start,en) then apply_row(domain,b,start,en,dense) else true end
  else if ieq(buf_get(b,p),CHAR_HASH) then true
  else if requested(domain,b,p,en) then apply_row(domain,b,p,en,dense) else true

extern fun property_source_exhausted(): int = "mac#anth_die_int"

fun source_lines {n:nat}{kind:int} .<n>. (
  n: int(n), domain: PropertyDomain(kind), b: !Buf, p: int, en: int, dense: !Buf
): int =
  if ige(p,en) then 0 else if n = 0 then property_source_exhausted() else let
    val finish = text_line_end(b,p,en)
    val valid = source_row(domain,b,text_skip_space(b,p,finish),finish,dense)
  in iadd(if valid then 0 else 1,source_lines(n-1,domain,b,iadd(finish,1),en,dense)) end

implement property_source_read(domain,path,dense) = case+ text_file_read(path) of
  | ~TextFileError(code) => false
  | ~TextFile(b) => let
      val n = buf_len(b)
      val valid = igt(n,0) andalso ieq(source_lines(airlock_nat(n),domain,b,0,n,dense),0)
      val () = buf_free(b)
    in valid end
