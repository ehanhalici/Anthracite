#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/gsub_sequences.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_sequence.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/ot_sequence_lookup_types.sats"
staload "data_font/ot_sequence_lookup.sats"
staload "opentype_fixture.sats"
staload "glyph_run_contracts.sats"
staload "glyph_pass_contracts.sats"
staload "glyph_sequence_contracts.sats"
staload "data_font/sfnt.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_header.sats"
staload "data_font/ot_layout_lookups.sats"
fun multiple(b: !Buf,s: OtSpan,m: !GlyphMetadata,glyphs: int,input: int,oracle: !Buf,at: int,count: int): int =
  case+ ot_sequence_lookup_parse(b,s,glyphs,GsubMultiple()) of
  | ~SequenceLookupRejected(e) => 1 | ~SequenceLookupAccepted(t) => let
    val errors=seq_font_multiple(b,t,m,glyphs,input,oracle,at,count)
    val ()=ot_sequence_lookup_dispose(t)
  in errors end
fun alternate(b: !Buf,s: OtSpan,m: !GlyphMetadata,glyphs: int,input: int,oracle: !Buf,at: int,count: int): int =
  case+ ot_sequence_lookup_parse(b,s,glyphs,GsubAlternate()) of
  | ~SequenceLookupRejected(e) => 1 | ~SequenceLookupAccepted(t) => let
    val errors=seq_font_alternate(b,t,m,glyphs,input,oracle,at,count)
    val ()=ot_sequence_lookup_dispose(t)
  in errors end
fun row(b: !Buf,h: OtLayoutInfo,m: !GlyphMetadata,glyphs: int,oracle: !Buf,at: int): int = let
  val child=ot_lookup_span(b,h,ot_fixture_read16(oracle,iadd(at,2)))
  val input=ot_fixture_read16(oracle,iadd(at,4)) and count=ot_fixture_read16(oracle,iadd(at,6))
in case+ child.kind of | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() =>
  (case+ ot_fixture_read16(oracle,at) of
  | 2 => multiple(b,child.span,m,glyphs,input,oracle,iadd(at,8),count)
  | 3 => alternate(b,child.span,m,glyphs,input,oracle,iadd(at,8),count) | _ => 1) end
fun rows{n:nat} .<n>. (left: int(n),b: !Buf,h: OtLayoutInfo,m: !GlyphMetadata,glyphs: int,oracle: !Buf,at: int): int =
  if left = 0 then 0 else let val errors=row(b,h,m,glyphs,oracle,at)
    val count=ot_fixture_read16(oracle,iadd(at,6))
  in errors+rows(left-1,b,h,m,glyphs,oracle,iadd(at,iadd(8,imul(count,2)))) end
fun reference(b: !Buf,h: OtLayoutInfo,m: !GlyphMetadata,glyphs: int): int = let
  val oracle=ot_fixture_words("0007 0003 0001 008C 0002 00A0 0084 0002 000F 0266 0002 000E 0141 0002 0010 02EA 0002 003C 0137 0002 0017 000E 0001 0013 0002 0018 000E 0001 0010 0002 0019 0008 0001 0009 0002 001C 02D9 0001 0030")
  val errors=rows(7,b,h,m,glyphs,oracle,2)
  val ()=buf_free(oracle)
in errors end
fun gdef(b: !Buf,info: SfntInfo): OtChild = case+ sfnt_table(b,info.tables,TableGdef()) of
  | NoSfntTable() => @{kind=ChildMissing(),span= @{offset=0,length=0}}
  | HasSfntTable(s) => @{kind=ChildPresent(),span=s}
fun metadata(b: !Buf,info: SfntInfo,h: OtLayoutInfo): int =
  case+ glyph_metadata_parse(b,gdef(b,info),3,info.glyphs) of
  | ~GlyphMetadataRejected(e) => 1 | ~GlyphMetadataAccepted(m) => let
    val errors=reference(b,h,m,info.glyphs) val ()=glyph_metadata_dispose(m)
  in errors end
fun face(face: !SfntFace): int = let val+ SfntFace(b,info)=face in
  case+ sfnt_table(b,info.tables,TableGsub()) of
  | NoSfntTable() => 1 | HasSfntTable(s) => case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(h) => metadata(b,info,h) end
implement seq_test_fonts(path) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let val errors=face(f) val ()=sfnt_dispose(f) in errors end
