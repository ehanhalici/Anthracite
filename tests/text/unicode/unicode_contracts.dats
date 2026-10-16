#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "os/fs.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/bidi/bidi_mirror.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
extern fun contract_exhausted(): int = "mac#anth_die_int"

fun fixture_bytes(value: string): Buf = let
  val size = c_strlen(value)
  var bytes = buf_make(iadd(size,1))
  val () = buf_append(bytes,c_str_ptr(value),size)
in bytes end

fun bad_brackets(value: string): int = let
  val source = fixture_bytes(value)
  val result = bidi_brackets_parse(source)
  val () = buf_free(source)
in case+ result of
  | ~BracketsRejected(error) => 0
  | ~BracketsLoaded(data) => let val () = bidi_brackets_dispose(data) in 1 end end

fun bad_mirrors(value: string): int = let
  val source = fixture_bytes(value)
  val result = bidi_mirrors_parse(source)
  val () = buf_free(source)
in case+ result of
  | ~MirrorsRejected(error) => 0
  | ~MirrorsLoaded(data) => let val () = bidi_mirrors_dispose(data) in 1 end end

fun source_errors(): int =
  bad_brackets("; 0029; o\n0029; 0000; c\n")
  + bad_brackets("0028; ; o\n0029; 0028; c\n")
  + bad_brackets("0028; 0029; o\n0029; 0028; o\n")
  + bad_mirrors("0028; # missing mapping\n")
  + bad_mirrors("0028; 0029\n0028; 0029\n")
  + bad_mirrors("D800; 0029\n")

fun map_fixture(): Buf = let
  val b = buf_make(28)
  val () = buf_set_len(b,28)
  val () = buf_set32(b,0,PROPERTY_MAGIC)
  val () = buf_set32(b,1,PROPERTY_VERSION)
  val () = buf_set32(b,2,1)
  val () = buf_set32(b,3,1)
  val () = buf_set32(b,4,0)
  val () = buf_set32(b,5,UNICODE_MAX_SCALAR)
  val () = buf_set32(b,6,0)
in b end

fun rejected{kind:int}(bytes: Buf, domain: PropertyDomain(kind)): int = case+ property_parse(bytes,domain) of
  | ~PropertyRejected(error) => 0
  | ~PropertyLoaded(map) => let val () = property_dispose(map) in 1 end

fun truncations {n:nat} .<n>. (n: int(n), size: int): int = if n = 0 then 0 else let
  val bytes = map_fixture()
  val () = buf_set_len(bytes,size)
  val errors = rejected(bytes,WordProperty())
in iadd(errors,truncations(n-1,iadd(size,1))) end

fun check_domain(): int = rejected(map_fixture(),BidiProperty())
fun check_value(): int = let
  val bytes = map_fixture()
  val () = buf_set32(bytes,6,19)
in rejected(bytes,WordProperty()) end
fun check_range(): int = let
  val bytes = map_fixture()
  val () = buf_set32(bytes,4,1)
in rejected(bytes,WordProperty()) end
fun check_version(): int = let
  val bytes = map_fixture()
  val () = buf_set32(bytes,1,170000)
in rejected(bytes,WordProperty()) end

fun mirror_rows {n:nat} .<n>. (n: int(n), data: !BidiMirrors, i: int, errors: int): int =
  if n = 0 then errors else let
    val+ BidiMirrors(rows,count) = data
    val cp = buf_get32(rows,imul(i,2))
    val expected = buf_get32(rows,iadd(imul(i,2),1))
    val valid = ieq(bidi_mirror_codepoint(data,cp,1),expected)
      andalso ieq(bidi_mirror_codepoint(data,cp,2),cp)
      andalso ieq(bidi_mirror_codepoint(data,cp,125),expected)
  in mirror_rows(n-1,data,iadd(i,1),iadd(errors,if valid then 0 else 1)) end

fun check_mirror(): int = case+ bidi_mirrors_load(c_argv(1)) of
  | ~MirrorsRejected(error) => let val () = println!("event=mirror_load_failed") in 1 end
  | ~MirrorsLoaded(data) => let
      val+ BidiMirrors(rows,count) = data
      val errors = mirror_rows(airlock_nat(count),data,0,0)
      val unchanged = ieq(bidi_mirror_codepoint(data,65,1),65)
        andalso ieq(bidi_mirror_codepoint(data,64830,1),64830)
        andalso ieq(bidi_mirror_codepoint(data,64831,1),64831)
      val () = bidi_mirrors_dispose(data)
      val () = println!("event=mirror_contract count=",count," errors=",errors," unchanged=",unchanged)
    in iadd(errors,if unchanged then 0 else 1) end

fun run(): int = let
  val before = mem_live()
  val truncated = truncations(28,0)
  val domain = check_domain()
  val value = check_value()
  val range = check_range()
  val version = check_version()
  val mirror = check_mirror()
  val source = source_errors()
  val errors = truncated + domain + value + range + version + mirror + source
  val () = println!("event=unicode_contract_details truncated=",truncated," domain=",domain," value=",value," range=",range," version=",version," mirror=",mirror)
  val () = println!("event=unicode_contracts errors=",errors)
in iadd(errors,if ieq(before,mem_live()) then 0 else 1) end

implement main0() = if ine(c_argc(),2) then exit(2) else if igt(run(),0) then exit(1) else ()
