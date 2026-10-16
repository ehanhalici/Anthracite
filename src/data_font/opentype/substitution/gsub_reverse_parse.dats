#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
staload "data_font/opentype/substitution/gsub_reverse_types.sats"
staload "data_font/opentype/tables/opentype_glyphs.sats"
staload "data_font/opentype/substitution/gsub_reverse.sats"
staload "data_font/opentype/substitution/gsub_reverse_work.sats"
fun outputs{back,look:nat}(b: !Buf,s: OtSpan,glyphs: int,back: int(back),look: int(look)): GsubReverseRead = let
  val at=iadd(10,imul(iadd(back,look),2))
  val count=ot_u16(b,s,isub(at,2))
in if not(ot_rows_fit(s,at,count,2)) then ReverseRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_array_valid(b,s,at,count,glyphs)) then ReverseRejected(ot_error(OtGlyphDomain(),s))
  else gsub_reverse_coverages(b,@{span=s,back=back,look=look,output=at,count=count,glyphs=glyphs}) end
fun lookahead{back:nat}(b: !Buf,s: OtSpan,glyphs: int,back: int(back)): GsubReverseRead = let
  val look=airlock_nat(ot_u16(b,s,iadd(6,imul(back,2))))
in if not(ot_rows_fit(s,iadd(10,imul(back,2)),look,2)) then ReverseRejected(ot_error(OtBounds(),s))
  else outputs(b,s,glyphs,back,look) end
implement gsub_reverse_parse(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then ReverseRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then ReverseRejected(ot_error(OtGlyphDomain(),s))
  else if ine(ot_u16(b,s,0),1) then ReverseRejected(ot_error(OtFormat(),s)) else let
    val back=airlock_nat(ot_u16(b,s,4))
  in if not(ot_rows_fit(s,8,back,2)) then ReverseRejected(ot_error(OtBounds(),s))
    else lookahead(b,s,glyphs,back) end
