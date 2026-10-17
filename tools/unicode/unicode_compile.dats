#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/source/text_source.sats"

datatype PropertySource = GraphemeSource | ConjunctSource | PictographicSource
typedef code_range = @{first=int, last=int, field=int}
extern fun invalid_ucd(): int = "mac#anth_die_int"

fun grapheme_code(b: !Buf, p: int, en: int): int =
  if text_token_is(b,p,en,"CR") then 1
  else if text_token_is(b,p,en,"LF") then 2
  else if text_token_is(b,p,en,"Control") then 3
  else if text_token_is(b,p,en,"Extend") then 4
  else if text_token_is(b,p,en,"ZWJ") then 5
  else if text_token_is(b,p,en,"Regional_Indicator") then 6
  else if text_token_is(b,p,en,"Prepend") then 7
  else if text_token_is(b,p,en,"SpacingMark") then 8
  else if text_token_is(b,p,en,"L") then 9
  else if text_token_is(b,p,en,"V") then 10
  else if text_token_is(b,p,en,"T") then 11
  else if text_token_is(b,p,en,"LV") then 12
  else if text_token_is(b,p,en,"LVT") then 13
  else if text_token_is(b,p,en,"Other") then 0 else invalid_ucd()

fun conjunct_code(b: !Buf, p: int, en: int): int =
  if not(text_token_is(b,p,en,"InCB")) then ~1 else let
    val semi = text_find_byte(b,p,en,59)
    val at = text_skip_space(b,iadd(semi,1),en)
  in
    if text_token_is(b,at,en,"Consonant") then 1
    else if text_token_is(b,at,en,"Extend") then 2
    else if text_token_is(b,at,en,"Linker") then 3
    else if text_token_is(b,at,en,"None") then 0 else invalid_ucd()
  end

fun property_code(kind: PropertySource, b: !Buf, p: int, en: int): int =
  case+ kind of
  | GraphemeSource() => grapheme_code(b,p,en)
  | ConjunctSource() => conjunct_code(b,p,en)
  | PictographicSource() => if text_token_is(b,p,en,"Extended_Pictographic") then 1 else ~1

fun property_factor(kind: PropertySource): int =
  case+ kind of
  | GraphemeSource() => 1 | ConjunctSource() => 16 | PictographicSource() => 64

fun read_range(b: !Buf, start: int, en: int): code_range = let
  var p: int = start
  val first = text_hex(b,p,en)
  val last = if ieq(buf_get(b,p),46) then let
    val () = p := iadd(p,2)
  in text_hex(b,p,en) end else first
  val field = text_skip_space(b,iadd(text_find_byte(b,p,en,59),1),en)
in @{first=first,last=last,field=field} end

fun fill_range {n:nat} .<n>. (n: int(n), dense: !Buf, cp: int, value: int): void =
  if n > 0 then let
    val old = buf_get32(dense,cp)
    val () = buf_set32(dense,cp,iadd(old,value))
  in fill_range(n-1,dense,iadd(cp,1),value) end else ()

fun parse_row(kind: PropertySource, b: !Buf, st: int, en: int, dense: !Buf): void =
  if ige(st,en) orelse ieq(buf_get(b,st),35) then () else let
    val range = read_range(b,st,en)
    val value = property_code(kind,b,range.field,en)
    val valid = ige(range.first,0) andalso ige(range.last,range.first)
      andalso ile(range.last,UNICODE_MAX_SCALAR)
  in
    if not(valid) then let val _ = invalid_ucd() in () end
    else if ilt(value,0) then ()
    else fill_range(airlock_nat(iadd(isub(range.last,range.first),1)),dense,
      range.first,imul(value,property_factor(kind)))
  end

fun parse_lines {fuel:nat} .<fuel>. (
  fuel: int(fuel), kind: PropertySource, b: !Buf, st: int, en: int, dense: !Buf
): void =
  if ige(st,en) then () else if fuel > 0 then let
    val finish = text_line_end(b,st,en)
    val () = parse_row(kind,b,text_skip_space(b,st,finish),finish,dense)
  in parse_lines(fuel-1,kind,b,iadd(finish,1),en,dense) end
  else let val _ = invalid_ucd() in () end

fun load_property(kind: PropertySource, path: string, dense: !Buf): bool =
  case+ text_file_read(path) of
  | ~TextFileError(code) => false
  | ~TextFile(b) => let
      val n = buf_len(b)
      val () = parse_lines(airlock_nat(n),kind,b,0,n,dense)
      val () = buf_free(b)
    in true end

fun emit_range(output: &Buf >> _, first: int, last: int, value: int, count: int): void = let
  val at = iadd(3,imul(count,3))
  val () = buf_ensure(output,imul(iadd(at,3),4))
  val () = buf_set32(output,at,first)
  val () = buf_set32(output,iadd(at,1),last)
in buf_set32(output,iadd(at,2),value) end

fun compress {n:nat} .<n>. (
  n: int(n), dense: !Buf, cp: int, start: int, previous: int, output: &Buf >> _, count: int
): int =
  if n = 0 then let val () = emit_range(output,start,isub(cp,1),previous,count)
    in iadd(count,1) end
  else let val value = buf_get32(dense,cp) in
    if ieq(value,previous) then compress(n-1,dense,iadd(cp,1),start,previous,output,count)
    else let val () = emit_range(output,start,isub(cp,1),previous,count) in
      compress(n-1,dense,iadd(cp,1),cp,value,output,iadd(count,1))
    end
  end

fun save_database(dense: !Buf, path: string): bool = let
  var output = buf_make(WORD16_MODULUS)
  val count = compress(UNICODE_MAX_SCALAR,dense,1,0,buf_get32(dense,0),output,0)
  val () = buf_set32(output,0,1096106837)
  val () = buf_set32(output,1,180000)
  val () = buf_set32(output,2,count)
  val size = imul(iadd(3,imul(count,3)),4)
  val () = buf_set_len(output,size)
  val written = fs_write_buf(path,output,size)
  val () = buf_free(output)
in ieq(written,1) end

fun compile_database(): bool = let
  val dense = buf_make(4456448)
  val a = load_property(GraphemeSource(),c_argv(1),dense)
  val b = load_property(ConjunctSource(),c_argv(2),dense)
  val c = load_property(PictographicSource(),c_argv(3),dense)
  val ok = a andalso b andalso c andalso save_database(dense,c_argv(4))
  val () = buf_free(dense)
in ok end

implement main0() =
  if ine(c_argc(),5) then exit(2)
  else if compile_database() then () else exit(1)
