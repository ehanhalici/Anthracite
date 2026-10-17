#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"

implement ot_span_valid(b,s) = ige(s.offset,0) andalso ige(s.length,0)
  andalso ile(s.offset,buf_len(b)) andalso ile(s.length,isub(buf_len(b),s.offset))
implement ot_glyph_domain_valid(glyphs) = igt(glyphs,0) andalso ile(glyphs,WORD16_MAX_VALUE)
implement ot_rows_fit(s,header,count,stride) = ige(header,0) andalso ile(header,s.length)
  andalso ige(count,0) andalso igt(stride,0) andalso ile(count,idiv(isub(s.length,header),stride))
implement ot_u16(b,s,relative) = sfnt_be16(b,iadd(s.offset,relative))
implement ot_range(b,s,index) = let val at=iadd(4,imul(index,6)) in
  @{first=ot_u16(b,s,at),last=ot_u16(b,s,iadd(at,2)),value=ot_u16(b,s,iadd(at,4))} end
implement ot_encoding_of(code) = case+ code of
  | 1 => Some_vt(OtList()) | 2 => Some_vt(OtRanges()) | _ => None_vt()
implement ot_error(reason,s) = @{reason=reason,offset=s.offset}
implement ot_u32(b,s,relative) = sfnt_be32(b,iadd(s.offset,relative))
implement ot_optional_child(parent,relative,floor) =
  if ieq(relative,0) then @{kind=ChildMissing(),span= @{offset=0,length=0}}
  else if ilt(relative,floor) orelse ige(relative,parent.length) then
    @{kind=ChildInvalid(),span= @{offset=0,length=0}}
  else @{kind=ChildPresent(),
    span= @{offset=iadd(parent.offset,relative),length=isub(parent.length,relative)}}
implement ot_child_valid(child) = case+ child.kind of
  | ChildMissing() => true | ChildPresent() => true | ChildInvalid() => false
