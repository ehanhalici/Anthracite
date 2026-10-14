#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/opentype_lookup_flags.sats"

fun bit_of(code: int,mask: int): bool = ieq(imod(idiv(code,mask),2),1)
implement ot_lookup_flags_of(code) =
  if ilt(code,0) orelse igt(code,65535) orelse ine(imod(idiv(code,32),8),0) then FlagsRejected(OtFormat())
  else FlagsAccepted(@{rtl=bit_of(code,1),ignoreBase=bit_of(code,2),ignoreLigature=bit_of(code,4),
    ignoreMarks=bit_of(code,8),useMarkSet=bit_of(code,16),attachment=idiv(code,256)})

fun skips_mark(f: OtLookupFlags,attachment: int,member: bool): bool =
  if f.ignoreMarks then true else if f.useMarkSet then not(member)
  else igt(f.attachment,0) andalso ine(f.attachment,attachment)

implement ot_lookup_skips_context(f,k,attachment,member) = case+ k of
  | GlyphUnclassified() => false | GlyphBase() => f.ignoreBase
  | GlyphLigature() => f.ignoreLigature | GlyphMark() => skips_mark(f,attachment,member)
  | GlyphComponent() => false
