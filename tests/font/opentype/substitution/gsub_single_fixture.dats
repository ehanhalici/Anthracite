#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "os/fs.sats"
staload "data_font/opentype/substitution/gsub_single.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_single_contracts.sats"

implement single_expect(b,s,glyphs,input,output) = case+ gsub_single_parse(b,s,glyphs) of
  | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
    val r=gsub_single_query(b,t,input)
    val ok=r.matched andalso ieq(r.glyph,output)
    val ()=gsub_single_dispose(t)
  in if ok then 0 else 1 end
implement single_reject(b,s,glyphs) = case+ gsub_single_parse(b,s,glyphs) of
  | ~SingleRejected(e) => 0 | ~SingleAccepted(t) => let val ()=gsub_single_dispose(t) in 1 end
