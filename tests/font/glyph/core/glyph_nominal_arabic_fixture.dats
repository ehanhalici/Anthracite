#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_nominal.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/core/glyph_nominal_contracts.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join.sats"
extern fun nominal_header_failed(): int = "mac#anth_die_int"
extern fun nominal_table_failed(): OtSequenceLookup(2) = "mac#anth_die_box"
extern fun nominal_metadata_failed(): GlyphMetadata = "mac#anth_die_box"
extern fun nominal_mask_failed(): ArabicMaskPlan = "mac#anth_die_box"
fun gsub(b: !Buf,info: SfntInfo): OtSpan = case+ sfnt_table(b,info.tables,TableGsub()) of
  | HasSfntTable(s) => s | NoSfntTable() => let val failed=nominal_header_failed() in @{offset=failed,length=0} end
implement nominal_test_table(b,info,index) = case+ ot_layout_header_parse(b,gsub(b,info)) of
  | ~HeaderRejected(e) => nominal_table_failed()
  | ~HeaderAccepted(h) => let val child=ot_lookup_span(b,h,index) in case+ child.kind of
    | ChildMissing() => nominal_table_failed() | ChildInvalid() => nominal_table_failed()
    | ChildPresent() => (case+ ot_sequence_lookup_parse(b,child.span,info.glyphs,GsubMultiple()) of
      | ~SequenceLookupRejected(e) => nominal_table_failed() | ~SequenceLookupAccepted(t) => t) end
implement nominal_test_metadata(b,info) = let
  val child: OtChild=case+ sfnt_table(b,info.tables,TableGdef()) of
    | NoSfntTable() => @{kind=ChildMissing(),span= @{offset=0,length=0}}
    | HasSfntTable(s) => @{kind=ChildPresent(),span=s}
in case+ glyph_metadata_parse(b,child,3,info.glyphs) of
  | ~GlyphMetadataRejected(e) => nominal_metadata_failed() | ~GlyphMetadataAccepted(m) => m end
implement nominal_test_mask() = case+ arabic_mask_plan(@{initial=1u,medial=2u,final=4u,isolated=8u}) of
  | ~ArabicMaskRejected(e) => nominal_mask_failed() | ~ArabicMaskAccepted(p) => p
