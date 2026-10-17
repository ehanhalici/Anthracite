#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "os/fs.sats"
staload "data_font/opentype/layout/ot_layout_tags.sats"
fun byte_valid(value: int): bool = ige(value,32) andalso ile(value,126)
implement ot_tag_valid(code) = ige(code,0) andalso byte_valid(idiv(code,16777216))
  andalso byte_valid(imod(idiv(code,WORD16_MODULUS),256)) andalso byte_valid(imod(idiv(code,256),256))
  andalso byte_valid(imod(code,256))
implement ot_tag_of_string(text) =
  if ine(c_strlen(text),4) then None_vt() else let
    val a=c_str_byte(text,0) and b=c_str_byte(text,1)
    val c=c_str_byte(text,2) and d=c_str_byte(text,3)
  in if not(byte_valid(a) andalso byte_valid(b) andalso byte_valid(c) andalso byte_valid(d)) then None_vt()
    else Some_vt(@{code=iadd(imul(iadd(imul(iadd(imul(a,256),b),256),c),256),d)}) end
implement ot_tag_at(b,s,p) = @{code=ot_u32(b,s,p)}
implement ot_tag_default() = @{code=1145457748}
