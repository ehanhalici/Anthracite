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

fun delta_at(b: !Buf,d: OtDeviceInfo,index: int): int = let
  val read_bits=ot_packing_bits(d.packing)
  val per_word=idiv(16,read_bits)
  val word=ot_u16(b,d.span,iadd(6,imul(idiv(index,per_word),2)))
  val shift=isub(16,imul(iadd(imod(index,per_word),1),read_bits))
  val base=ot_packing_base(d.packing)
  val raw=imod(idiv(word,ot_power2(shift)),base)
in if ige(raw,idiv(base,2)) then isub(raw,base) else raw end

implement ot_device_pixels(b,d,ppem) =
  if ilt(ppem,d.first) orelse igt(ppem,d.last) then 0 else delta_at(b,d,isub(ppem,d.first))
