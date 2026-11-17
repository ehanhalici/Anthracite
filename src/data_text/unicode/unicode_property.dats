#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/unicode/unicode_property.sats"

implement property_domain_code(domain) = case+ domain of
  | WordProperty() => 1 | BidiProperty() => 2 | JoiningProperty() => 3
  | LineProperty() => 4 | EastAsianProperty() => 5 | CategoryProperty() => 6
  | ScriptProperty() => 7 | IgnorableProperty() => 8 | ModifierMarkProperty() => 9

implement property_domain_max(domain) = case+ domain of
  | WordProperty() => 18 | BidiProperty() => 22 | JoiningProperty() => 5
  | LineProperty() => 48 | EastAsianProperty() => 5 | CategoryProperty() => 29
  | ScriptProperty() => SIGNED_INT_MAX_VALUE | IgnorableProperty() => 1 | ModifierMarkProperty() => 1

fun lower(c: int): bool = ige(c,97) andalso ile(c,122)
fun script_value_valid(value: int): bool =
  ige(idiv(value,16777216),65) andalso ile(idiv(value,16777216),90)
  andalso lower(imod(idiv(value,WORD16_MODULUS),256)) andalso lower(imod(idiv(value,256),256)) andalso lower(imod(value,256))
implement property_serialized_value_valid(domain,value) =
  if ilt(value,0) orelse igt(value,property_domain_max(domain)) then false else case+ domain of
  | ScriptProperty() => script_value_valid(value)
  | IgnorableProperty() => true | ModifierMarkProperty() => true | WordProperty() => true | BidiProperty() => true
  | JoiningProperty() => true | LineProperty() => true | EastAsianProperty() => true | CategoryProperty() => true
fun ranges_valid {n:nat}{kind:int} .<n>. (
  n: int(n), b: !Buf, at: int, previous: int, domain: PropertyDomain(kind)
): bool =
  if n = 0 then ieq(previous,isub(UNICODE_SCALAR_LIMIT,1)) else let
    val first = buf_get32(b,at)
    val last = buf_get32(b,iadd(at,1))
    val value = buf_get32(b,iadd(at,2))
  in if ine(first,iadd(previous,1)) orelse ilt(last,first) orelse ige(last,UNICODE_SCALAR_LIMIT)
      orelse not(property_serialized_value_valid(domain,value)) then false
    else ranges_valid(n-1,b,iadd(at,3),last,domain) end

fun header_valid{kind:int}(b: !Buf, domain: PropertyDomain(kind)): bool = let
  val size = buf_len(b)
  val count = buf_get32(b,3)
in ige(size,16) andalso ieq(buf_get32(b,0),PROPERTY_MAGIC)
  andalso ieq(buf_get32(b,1),PROPERTY_VERSION)
  andalso ieq(buf_get32(b,2),property_domain_code(domain))
  andalso igt(count,0) andalso ieq(imod(isub(size,16),12),0)
  andalso ieq(count,idiv(isub(size,16),12)) end

fun reject_map{kind:int}(b: Buf, error: PropertyError): PropertyLoad(kind) = let
  val () = buf_free(b)
in PropertyRejected(error) end

fun dense_base(count: int): int = iadd(4,imul(count,3))
fun dense_span{n:nat} .<n>. (n: int(n),b: !Buf,at: int,value: int): void =
  if n = 0 then () else let val ()=buf_set32(b,at,value) in dense_span(n-1,b,iadd(at,1),value) end
(* Ranges are validated contiguous from 0, so every dense slot gets written. *)
fun dense_fill{n:nat} .<n>. (n: int(n),b: !Buf,at: int,base: int): void =
  if n = 0 then () else let val first=buf_get32(b,at) in
    if ige(first,UNICODE_DENSE_SCALARS) then () else let
      val last=imin(buf_get32(b,iadd(at,1)),isub(UNICODE_DENSE_SCALARS,1))
      val ()=dense_span(airlock_nat(iadd(isub(last,first),1)),b,iadd(base,first),buf_get32(b,iadd(at,2)))
    in dense_fill(n-1,b,iadd(at,3),base) end end
fun with_dense(b0: Buf,count: int): Buf = let
  var b: Buf=b0
  val base=dense_base(count) val bytes=imul(iadd(base,UNICODE_DENSE_SCALARS),WORD32_BYTES)
  val ()=buf_ensure(b,bytes) val ()=buf_set_len(b,bytes)
  val ()=dense_fill(airlock_nat(count),b,4,base)
in b end

implement property_parse(b,domain) =
  if not(header_valid(b,domain)) then reject_map(b,PropertyHeader()) else let
    val count = buf_get32(b,3)
    val valid = ranges_valid(airlock_nat(count),b,4,~1,domain)
  in if valid then PropertyLoaded(PropertyMap(with_dense(b,count),count)) else reject_map(b,PropertyRanges()) end

implement property_load(path,domain) = case+ text_file_read(path) of
  | ~TextFileError(code) => PropertyRejected(PropertyIo(code))
  | ~TextFile(b) => property_parse(b,domain)

extern fun property_exhausted(): int = "mac#anth_die_int"

fun search {n:nat} .<n>. (
  n: int(n), b: !Buf, cp: int, low: int, high: int
): int =
  if ige(low,high) then 0 else if n = 0 then property_exhausted() else let
    val mid = iadd(low,idiv(isub(high,low),2))
    val at = iadd(4,imul(mid,3))
    val first = buf_get32(b,at)
    val last = buf_get32(b,iadd(at,1))
  in if ilt(cp,first) then search(n-1,b,cp,low,mid)
    else if igt(cp,last) then search(n-1,b,cp,iadd(mid,1),high)
    else buf_get32(b,iadd(at,2)) end

implement property_value(map,cp) = let val+ PropertyMap(b,count) = map in
  if ige(cp,0) andalso ilt(cp,UNICODE_DENSE_SCALARS) then buf_get32(b,iadd(dense_base(count),cp))
  else search(airlock_nat(iadd(count,1)),b,cp,0,count) end
fun dense_match{n:nat} .<n>. (n: int(n),b: !Buf,count: int,cp: int): bool =
  if n = 0 then true
  else ieq(buf_get32(b,iadd(dense_base(count),cp)),search(airlock_nat(iadd(count,1)),b,cp,0,count))
    andalso dense_match(n-1,b,count,iadd(cp,1))
implement property_dense_match(map) = let val+ PropertyMap(b,count) = map in
  dense_match(airlock_nat(UNICODE_DENSE_SCALARS),b,count,0) end

implement property_dispose(map) = let val+ ~PropertyMap(b,count) = map in buf_free(b) end
