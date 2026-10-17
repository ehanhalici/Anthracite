#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
staload "data_font/opentype/tables/opentype_lookup_flags.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_single.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "font/opentype/substitution/gsub_single_contracts.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
fun cached(b: !Buf,s: OtSpan,metadata: !GlyphMetadata,glyphs: int,input: int,output: int): int =
  case+ ot_single_lookup_parse(b,s,glyphs) of
  | ~SingleLookupRejected(e) => 1 | ~SingleLookupAccepted(t) => let
    val result=ot_single_lookup_query(b,t,input)
    val ok=result.matched andalso ieq(result.glyph,output)
    val errors=pass_font_lookup(b,t,metadata,glyphs,input,output)
    val ()=ot_single_lookup_dispose(t)
  in iadd(errors,if ok then 0 else 1) end
fun primitive(b: !Buf,s: OtSpan,glyphs: int,input: int,output: int): int =
  case+ gsub_single_parse(b,s,glyphs) of
  | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
    val errors=pass_font_run(b,t,glyphs,input,output)
    val ()=gsub_single_dispose(t)
  in errors end
fun subtable(b: !Buf,s: OtSpan,metadata: !GlyphMetadata,glyphs: int,input: int,output: int): int =
  if ilt(s.length,8) orelse ine(ot_u16(b,s,0),1) orelse ilt(ot_u16(b,s,4),1) then 1 else
  case+ ot_lookup_flags_of(ot_u16(b,s,2)) of
  | ~FlagsRejected(e) => 1 | ~FlagsAccepted(f) => let
    val floor=iadd(iadd(6,imul(ot_u16(b,s,4),2)),if f.useMarkSet then 2 else 0)
    val child=ot_optional_child(s,ot_u16(b,s,6),floor)
  in case+ child.kind of
    | ChildMissing() => 1 | ChildInvalid() => 1
    | ChildPresent() => primitive(b,child.span,glyphs,input,output)+cached(b,s,metadata,glyphs,input,output) end
fun rows{n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,metadata: !GlyphMetadata,glyphs: int,reference: !Buf,i: int): int =
  if n = 0 then 0 else let
    val at=iadd(2,imul(i,6))
    val child=ot_lookup_span(b,info,ot_fixture_read16(reference,at))
    val errors: int=case+ child.kind of
      | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() =>
        subtable(b,child.span,metadata,glyphs,ot_fixture_read16(reference,iadd(at,2)),ot_fixture_read16(reference,iadd(at,4)))
  in iadd(errors,rows(n-1,b,info,metadata,glyphs,reference,iadd(i,1))) end
fun oracle(b: !Buf,info: OtLayoutInfo,metadata: !GlyphMetadata,glyphs: int,font: SingleTestFont): int = let
  val reference=single_font_oracle(font)
  val count=ot_fixture_read16(reference,0)
  val errors=rows(airlock_nat(count),b,info,metadata,glyphs,reference,0)
  val ()=buf_free(reference)
  val ()=println!("event=glyph_pass_font oracle_rows=",count," oracle_errors=",errors)
in errors end
fun table(b: !Buf,info: SfntInfo,metadata: !GlyphMetadata,font: SingleTestFont): int =
  case+ sfnt_table(b,info.tables,TableGsub()) of
  | ~NoSfntTable() => 1 | ~HasSfntTable(s) => case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(layout) => oracle(b,layout,metadata,info.glyphs,font)
fun gdef(b: !Buf,info: SfntInfo): OtChild = case+ sfnt_table(b,info.tables,TableGdef()) of
  | ~NoSfntTable() => @{kind=ChildMissing(),span= @{offset=0,length=0}}
  | ~HasSfntTable(s) => @{kind=ChildPresent(),span=s}
fun face(f: !SfntFace,font: SingleTestFont): int = let val+ SfntFace(b,info)=f in
  case+ glyph_metadata_parse(b,gdef(b,info),3,info.glyphs) of
  | ~GlyphMetadataRejected(e) => 1 | ~GlyphMetadataAccepted(metadata) => let
    val errors=table(b,info,metadata,font) val ()=glyph_metadata_dispose(metadata)
  in errors end end
implement pass_test_font(path,font) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let
    val errors=face(f,font) val ()=sfnt_dispose(f)
  in errors end
