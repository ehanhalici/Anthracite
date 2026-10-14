#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/opentype_lookup_flags.sats"
staload "gdef_contracts.sats"

fun masked(code: int,mask: int): bool =
  ine(g0uint2int_uint_int(g0uint_land(g0int2uint_int_uint(code),g0int2uint_int_uint(mask))),0)
fun mark_expected(code: int,attachment: int,member: bool): bool =
  if masked(code,8) then true else if masked(code,16) then not(member)
  else igt(idiv(code,256),0) andalso ine(idiv(code,256),attachment)
fun expected(code: int,k: GdefGlyphKind,attachment: int,member: bool): bool = case+ k of
  | GlyphUnclassified() => false | GlyphComponent() => false
  | GlyphBase() => masked(code,2) | GlyphLigature() => masked(code,4)
  | GlyphMark() => mark_expected(code,attachment,member)

fun compare(code: int,f: OtLookupFlags,k: GdefGlyphKind,attachment: int,member: bool): int =
  if expected(code,k,attachment,member) = ot_lookup_skips_context(f,k,attachment,member) then 0 else 1

fun kinds(code: int,f: OtLookupFlags,attachment: int,member: bool): int =
  compare(code,f,GlyphUnclassified(),attachment,member)+compare(code,f,GlyphBase(),attachment,member)+
  compare(code,f,GlyphLigature(),attachment,member)+compare(code,f,GlyphMark(),attachment,member)+
  compare(code,f,GlyphComponent(),attachment,member)

fun accepted(code: int,f: OtLookupFlags): int =
  kinds(code,f,0,false)+kinds(code,f,0,true)+
  kinds(code,f,idiv(code,256),false)+kinds(code,f,idiv(code,256),true)+
  kinds(code,f,iadd(idiv(code,256),1),false)+kinds(code,f,iadd(idiv(code,256),1),true)

fun check(code: int): int = case+ ot_lookup_flags_of(code) of
  | ~FlagsRejected(e) => if ilt(code,0) orelse igt(code,65535) orelse masked(code,224) then 0 else 1
  | ~FlagsAccepted(f) => if masked(code,224) then 1 else accepted(code,f)

fun codes {n:nat} .<n>. (n: int(n),code: int,errors: int): int =
  if n = 0 then errors else codes(n-1,iadd(code,1),iadd(errors,check(code)))

implement gdef_test_flags() = codes(65536,0,0)+check(~1)+check(65536)
