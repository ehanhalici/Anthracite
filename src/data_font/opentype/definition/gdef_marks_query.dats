#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_marks.sats"
staload "data_font/opentype/definition/gdef_mark_storage.sats"

implement gdef_mark_contains(b,sets,index,gid) = case+ sets of
  | GdefNoMarks() => false
  | GdefMarkSets(descriptors,count) =>
    if ilt(index,0) orelse ige(index,count) then false else let
      val coverage=gdef_mark_descriptor_get(descriptors,index)
      val result=ot_coverage_index(b,coverage,gid)
    in result.found end

implement gdef_mark_set_count(sets) = case+ sets of
  | GdefNoMarks() => 0 | GdefMarkSets(descriptors,count) => count
implement gdef_marks_dispose(sets) = case+ sets of
  | ~GdefNoMarks() => () | ~GdefMarkSets(descriptors,count) => buf_free(descriptors)
