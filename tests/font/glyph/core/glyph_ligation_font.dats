#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup.sats"
staload "data_font/glyph/pass/glyph_pass_ligation.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/run/glyph_run_contracts.sats"
staload "font/glyph/core/glyph_ligation_contracts.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
extern fun ligation_font_run_failed(): GlyphRun(1) = "mac#anth_die_box"
fun append{n:nat} .<n>. (left: int(n),run: GlyphRun(0),o: !Buf,at: int,i: int,errors: &int >> _): GlyphRun(0) =
  if left = 0 then run else let
    val seed: GlyphSeed= @{glyph=ot_fixture_read16(o,iadd(at,imul(i,2))),scalar=1576,sourceStart=imul(i,2),
      sourceEnd=imul(iadd(i,1),2),cluster=i,mask=1u}
    val next=run_test_take(glyph_run_append(run,seed),run_test_updated,errors)
  in append(left-1,next,o,at,iadd(i,1),errors) end
fun run(glyphs: int,o: !Buf,at: int,count: int,errors: &int >> _): GlyphRun(1) =
  case+ glyph_run_make(3,glyphs,imul(count,2),count) of | ~GlyphRunRejected(e) => ligation_font_run_failed()
  | ~GlyphRunCreated(r) => glyph_run_substitute(append(airlock_nat(count),r,o,at,0,errors))
fun applied(b: !Buf,t: !OtLigationLookup,m: !GlyphMetadata,glyphs: int,o: !Buf,at: int): int = let
  var errors: int=0
  val count=ot_fixture_read16(o,iadd(at,4)) and expected=ot_fixture_read16(o,iadd(at,2))
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_ligation(b,t,m,run(glyphs,o,iadd(at,6),count,errors),@{kind=GlyphAll(),mask=0u})
  val v=glyph_run_query(r,0) and meta=glyph_run_meta(r)
  val ready=case+ status of | GlyphPassApplied() => true | GlyphPassDomain() => false | GlyphPassReference() => false | GlyphPassCapacity() => false
  val ok=ready andalso ieq(matches,1) andalso ieq(meta.live,1) andalso ieq(v.core.glyph,expected)
    andalso ieq(v.core.sourceStart,0) andalso ieq(v.core.sourceEnd,imul(count,2)) andalso ieq(v.core.cluster,0)
  val ()=glyph_run_dispose(r)
in iadd(errors,if ok then 0 else 1) end
fun row(b: !Buf,h: OtLayoutInfo,m: !GlyphMetadata,glyphs: int,o: !Buf,at: int): int = let
  val child=ot_lookup_span(b,h,ot_fixture_read16(o,at))
in case+ child.kind of | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() =>
  (case+ ot_ligation_lookup_parse(b,child.span,glyphs) of | ~LigationLookupRejected(e) => 1
  | ~LigationLookupAccepted(t) => let val errors=applied(b,t,m,glyphs,o,at) val ()=ot_ligation_lookup_dispose(t) in errors end) end
fun rows{n:nat} .<n>. (left: int(n),b: !Buf,h: OtLayoutInfo,m: !GlyphMetadata,glyphs: int,o: !Buf,at: int): int =
  if left = 0 then 0 else let val errors=row(b,h,m,glyphs,o,at) val count=ot_fixture_read16(o,iadd(at,4))
  in errors+rows(left-1,b,h,m,glyphs,o,iadd(at,iadd(6,imul(count,2)))) end
fun gdef(b: !Buf,info: SfntInfo): OtChild = case+ sfnt_table(b,info.tables,TableGdef()) of
  | ~NoSfntTable() => @{kind=ChildMissing(),span= @{offset=0,length=0}} | ~HasSfntTable(s) => @{kind=ChildPresent(),span=s}
fun checked(b: !Buf,info: SfntInfo,h: OtLayoutInfo,s: string): int = case+ glyph_metadata_parse(b,gdef(b,info),3,info.glyphs) of
  | ~GlyphMetadataRejected(e) => 1 | ~GlyphMetadataAccepted(m) => let val o=ot_fixture_words(s)
    val errors=rows(airlock_nat(ot_fixture_read16(o,0)),b,h,m,info.glyphs,o,2)
    val ()=buf_free(o) and ()=glyph_metadata_dispose(m)
  in errors end
fun face(f: !SfntFace,s: string): int = let val+ SfntFace(b,info)=f in case+ sfnt_table(b,info.tables,TableGsub()) of
  | ~NoSfntTable() => 1 | ~HasSfntTable(span) => case+ ot_layout_header_parse(b,span) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(h) => checked(b,info,h,s) end
fun font(path: string,s: string): int = case+ sfnt_open(path) of | ~RejectedSfnt(e) => 1
  | ~LoadedSfnt(f) => let val errors=face(f,s) val ()=sfnt_dispose(f) in errors end
implement ligation_test_fonts(latin,arabic) =
  font(latin,"0003 0006 0CB6 0002 0C9A 0C49 0007 0CB4 0002 0C9A 0C43 0008 0BE3 0002 0049 004F")
    +font(arabic,"0004 0005 0175 0002 0174 017E 000D 0131 0002 006B 012F 0027 00ED 0005 0008 0046 0044 0176 0051 0028 00EE 0003 0046 0044 0051")
