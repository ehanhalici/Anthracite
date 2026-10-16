#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_font/native/text/native_text_coverage.sats"
fun covered{n:nat} .<n>. (left: int(n),b: !Buf,info: SfntInfo,ignorable: !PropertyMap(8),
  source: !ScalarText,index: int): bool = if left = 0 then true else let
  val cp=scalar_value(source,index)
  val supported=ine(property_value(ignorable,cp),0) orelse igt(sfnt_map(b,info,cp),0)
in supported andalso covered(left-1,b,info,ignorable,source,iadd(index,1)) end
implement native_text_range_covered(b,info,ignorable,source,start,finish) =
  covered(airlock_span(start,finish),b,info,ignorable,source,start)
implement native_text_cluster_face(preferred,pinfo,alternative,ainfo,ignorable,source,start,finish) =
  if covered(airlock_span(start,finish),preferred,pinfo,ignorable,source,start) then ClusterPreferred()
  else if covered(airlock_span(start,finish),alternative,ainfo,ignorable,source,start) then ClusterAlternative()
  else ClusterMissing()
