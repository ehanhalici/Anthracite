#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_tags.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/opentype/layout/ot_layout_feature_set.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/layout/ot_layout_contracts.sats"

staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_header.sats"
staload "data_font/opentype/definition/gdef_classes.sats"
staload "data_font/opentype/definition/gdef_marks.sats"
fun plan{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),font: LayoutTestFont,domain: OtLayoutDomain(kind),set: !OtFeatureSet): int = let
  val info=ot_layout_info(t)
  val script=layout_font_script(font)
  val s=ot_script_select(b,info,script)
  val l=ot_language_default(b,s)
in case+ ot_stage_plan(b,t,l,set) of
  | ~PlanRejected(e) => 1 | ~PlanAccepted(p) => let
    val count=ot_plan_lookup_count(p)
    val errors=layout_font_plan_check(p,font,domain)
    val ()=println!("event=ot_layout_font script=",script.code,
      " table_lookups=",info.lookupCount," selected_lookups=",count," oracle_errors=",errors)
    val ()=ot_plan_dispose(p)
  in errors end end
fun features{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),font: LayoutTestFont,domain: OtLayoutDomain(kind)): int =
  case+ ot_feature_set_parse(layout_bytes("ccmpligarligcaltinitmedifinaisolkernmarkmkmk")) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val errors=plan(b,t,font,domain,set)
    val ()=ot_feature_set_dispose(set)
  in errors end
fun table{kind:int}(b: !Buf,info: SfntInfo,tag: SfntTable,domain: OtLayoutDomain(kind),
  caps: OtGdefCapabilities,font: LayoutTestFont): int = case+ sfnt_table(b,info.tables,tag) of
  | NoSfntTable() => 1 | HasSfntTable(s) => case+ ot_layout_parse(b,s,domain,caps) of
    | ~LayoutRejected(e) => let
      val ()=println!("event=ot_layout_font_rejected table_offset=",s.offset," error_offset=",e.offset)
    in 1 end
    | ~LayoutAccepted(t) => let
      val errors=features(b,t,font,domain)
      val ()=ot_layout_dispose(t)
    in errors end
fun tables(b: !Buf,info: SfntInfo,caps: OtGdefCapabilities,font: LayoutTestFont): int =
  table(b,info,TableGsub(),OtSubstitution(),caps,font)+
  table(b,info,TableGpos(),OtPositioning(),caps,font)
fun marks(b: !Buf,info: SfntInfo,h: GdefHeaderInfo,c: GdefClassMetadata,font: LayoutTestFont): int =
  case+ gdef_marks_parse(b,h,info.glyphs) of
  | ~GdefMarksRejected(e) => 1 | ~GdefMarksAccepted(sets) => let
    val caps= @{classes=c.defined,attachments=c.attachmentDefined,markSets=gdef_mark_set_count(sets)}
    val errors=tables(b,info,caps,font)
    val ()=gdef_marks_dispose(sets)
  in errors end
fun classes(b: !Buf,info: SfntInfo,h: GdefHeaderInfo,font: LayoutTestFont): int =
  case+ gdef_classes_parse(b,h,info.glyphs) of
  | ~GdefClassRejected(e) => 1 | ~GdefClassAccepted(c) => marks(b,info,h,c,font)
fun gdef(b: !Buf,info: SfntInfo,font: LayoutTestFont): int = case+ sfnt_table(b,info.tables,TableGdef()) of
  | NoSfntTable() => tables(b,info,@{classes=false,attachments=false,markSets=0},font)
  | HasSfntTable(s) => case+ gdef_header_parse(b,s) of
    | ~GdefHeaderRejected(e) => 1 | ~GdefHeaderAccepted(h) => classes(b,info,h,font)
fun face(face: !SfntFace,font: LayoutTestFont): int = let val+ SfntFace(b,info)=face in gdef(b,info,font) end
implement layout_test_font(path,font) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let
    val errors=face(f,font) val ()=sfnt_dispose(f)
  in errors end
