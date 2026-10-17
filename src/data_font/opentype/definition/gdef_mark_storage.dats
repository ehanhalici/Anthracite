#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_mark_storage.sats"
fun encoding_code(encoding: OtEncoding): int = case+ encoding of
  | OtList() => 1 | OtRanges() => 2
extern fun descriptor_exhausted(): OtEncoding = "mac#anth_die_box"
fun encoding_of(code: int): OtEncoding = case+ code of
  | 1 => OtList() | 2 => OtRanges() | _ => descriptor_exhausted()

implement gdef_mark_descriptor_put(b,index,c) = let val at=imul(index,5) in
  buf_set32(b,at,c.span.offset); buf_set32(b,iadd(at,1),c.span.length);
  buf_set32(b,iadd(at,2),encoding_code(c.encoding)); buf_set32(b,iadd(at,3),c.count);
  buf_set32(b,iadd(at,4),c.total) end

implement gdef_mark_descriptor_get(b,index) = let val at=imul(index,5) in
  @{span= @{offset=buf_get32(b,at),length=buf_get32(b,iadd(at,1))},
    encoding=encoding_of(buf_get32(b,iadd(at,2))),
    count=buf_get32(b,iadd(at,3)),total=buf_get32(b,iadd(at,4))} end
