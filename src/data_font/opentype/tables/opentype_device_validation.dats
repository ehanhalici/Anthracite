#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_device.sats"
staload "data_font/opentype/tables/opentype_packing.sats"

fun padding_valid(b: !Buf,s: OtSpan,values: int,read_bits: int,words: int): bool = let
  val unused=imod(isub(16,imod(imul(values,read_bits),16)),16)
  val last=ot_u16(b,s,iadd(6,imul(isub(words,1),2)))
in ieq(imod(last,ot_power2(unused)),0) end

fun packed(b: !Buf,s: OtSpan,packing: OtPacking): OtDeviceRead = let
  val first=ot_u16(b,s,0)
  val last=ot_u16(b,s,2)
  val values=iadd(isub(last,first),1)
  val read_bits=ot_packing_bits(packing)
  val words=idiv(iadd(imul(values,read_bits),15),16)
in if ilt(last,first) orelse not(ot_rows_fit(s,6,words,2)) then DeviceRejected(ot_error(OtBounds(),s))
  else if not(padding_valid(b,s,values,read_bits,words)) then DeviceRejected(ot_error(OtPadding(),s))
  else DeviceAccepted(@{span=s,packing=packing,first=first,last=last}) end

fun parse_encoding(b: !Buf,s: OtSpan): OtDeviceRead = let val code=ot_u16(b,s,4) in
  if ieq(code,WORD16_SIGN_BIT) then DeviceVariation(ot_u16(b,s,0),ot_u16(b,s,2)) else
    case+ ot_packing_of(code) of
    | ~None_vt() => DeviceRejected(ot_error(OtFormat(),s))
    | ~Some_vt(packing) => packed(b,s,packing) end

implement ot_device_parse(b,s) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then DeviceRejected(ot_error(OtBounds(),s))
  else parse_encoding(b,s)
