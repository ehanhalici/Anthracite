#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_work.sats"
staload "glyph_position_contracts.sats"
staload "glyph_run_contracts.sats"
staload "opentype_fixture.sats"
extern fun position_fixture_failed(): GlyphPositioned(0) = "mac#anth_die_box"
extern fun position_fixture_metadata_failed(): GlyphMetadata = "mac#anth_die_box"
extern fun position_fixture_freeze_failed(): GlyphPositioned(1) = "mac#anth_die_box"
fun class_words(c: PositionTestClasses): string = case+ c of
  | TestBaseClasses() => "0001 0000 000C 0000 0000 0000 0001 0005 0004 0001 0001 0003 0003"
  | TestMarkClasses() => "0001 0000 000C 0000 0000 0000 0001 0005 0004 0003 0003 0003 0003"
implement position_test_fixture(words,classes) = let
  var b=ot_fixture_words(words)
  val length=isub(buf_len(b),8) and g=ot_fixture_words(class_words(classes))
  val ()=buf_set32(b,0,length)
  val ()=buf_append_at(b,g,8,isub(buf_len(g),8))
  val ()=buf_free(g)
in b end
implement position_test_span(b) = @{offset=8,length=buf_get32(b,0)}
implement position_test_metadata(b) = let val start=iadd(8,buf_get32(b,0)) in
  case+ glyph_metadata_parse(b,@{kind=ChildPresent(),span= @{offset=start,length=isub(buf_len(b),start)}},3,128) of
  | ~GlyphMetadataRejected(e) => position_fixture_metadata_failed() | ~GlyphMetadataAccepted(m) => m end
fun append{n:nat} .<n>. (left: int(n),r: GlyphRun(0),b: !Buf,i: int,errors: &int >> _): GlyphRun(0) =
  if left = 0 then r else let
    val seed: GlyphSeed= @{glyph=ot_fixture_read16(b,imul(i,2)),scalar=1576,sourceStart=imul(i,2),
      sourceEnd=imul(iadd(i,1),2),cluster=i,mask=3u}
    val r=run_test_take(glyph_run_append(r,seed),run_test_updated,errors)
  in append(left-1,r,b,iadd(i,1),errors) end
implement position_test_set(p,node,value) = let val+ PositionAccumulating(run,scale)=p
  val+ GlyphRun(phase,meta,s)=run in glyph_storage_set_position(s,node,value) end
implement position_test_mask(p,node,mask) = let val+ PositionAccumulating(run,scale)=p
  val+ GlyphRun(phase,meta,s)=run val c=glyph_storage_core(s,node)
in glyph_storage_set_core(s,node,glyph_run_new_mask(c,mask)) end
fun create(b: !Buf,size: int,errors: &int >> _): GlyphPositioned(0) =
  case+ glyph_run_make(3,128,imul(size,2),size) of
    | ~GlyphRunRejected(status) => position_fixture_failed()
    | ~GlyphRunCreated(run) => PositionAccumulating(glyph_run_position(glyph_run_substitute(append(airlock_nat(size),run,b,0,errors))),
        @{units=1024,xPpem=16,yPpem=16})
implement position_test_run(words,errors) = let
  val b=ot_fixture_words(words)
  val size=idiv(isub(buf_len(b),8),2)
  val p=create(b,size,errors)
  val ()=if igt(size,0) then position_test_set(p,0,@{xAdvance=1024,yAdvance=0,xOffset=0,yOffset=0,
    attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0}) else ()
  val ()=buf_free(b)
in p end
implement position_test_take(result,visited,matches,errors) = let val+ ~GlyphPositionResult(p,status,v,m)=result
  val ()=if glyph_position_ready(status) andalso ieq(v,visited) andalso ieq(m,matches) then () else errors := iadd(errors,1)
in p end
implement position_test_frozen(result,errors) = case+ result of | ~PositionFinished(p) => p
  | ~PositionUnfinished(p,status) => let val ()=glyph_position_dispose(p) val ()=errors := iadd(errors,1) in position_fixture_freeze_failed() end
implement position_test_values(p,node,xa,ya,xo,yo) = let val v=glyph_position_query(p,node)
in if ieq(v.position.xAdvance,xa) andalso ieq(v.position.yAdvance,ya)
  andalso ieq(v.position.xOffset,xo) andalso ieq(v.position.yOffset,yo) then 0 else 1 end
implement position_test_flags() = @{rtl=false,ignoreBase=false,ignoreLigature=false,ignoreMarks=false,useMarkSet=false,attachment=0}
implement position_test_all() = @{kind=GlyphAll(),mask=0u}
