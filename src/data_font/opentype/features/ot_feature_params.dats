#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/features/ot_feature_params_kind.sats"
staload "data_font/opentype/features/ot_feature_params.sats"

fun accept(p: OtFeatureParams): OtFeatureParamsRead = FeatureParamsAccepted(p)
implement ot_feature_params_dispose(p) = case+ p of
  | ~ParamsSize(value) => () | ~ParamsStylistic(value) => () | ~ParamsVariant(value) => ()
  | ~ParamsOpaque() => () | ~ParamsAbsent() => ()
fun reject(reason: OtErrorReason, s: OtSpan): OtFeatureParamsRead = FeatureParamsRejected(ot_error(reason,s))

(* 'size': a nonzero subfamily identifier requires a name ID in 256..32767. *)
fun size_name_valid(name: int): bool = ige(name,256) andalso ile(name,32767)
fun size_read(b: !Buf, s: OtSpan): OtFeatureParamsRead = let
  val design=ot_u16(b,s,0)
  val subfamily=ot_u16(b,s,2)
  val name=ot_u16(b,s,4)
  val rangeStart=ot_u16(b,s,6)
  val rangeEnd=ot_u16(b,s,8)
in
  if ieq(design,0) orelse (ine(subfamily,0) andalso not(size_name_valid(name))) then reject(OtFormat(),s)
  else if igt(rangeStart,rangeEnd) then reject(OtOrder(),s)
  else accept(ParamsSize(@{design=design,subfamily=subfamily,name=name,
    rangeStart=rangeStart,rangeEnd=rangeEnd}))
end
fun size(b: !Buf, s: OtSpan): OtFeatureParamsRead =
  if ilt(s.length,10) then reject(OtBounds(),s) else size_read(b,s)

(* ss01-ss20: the leading version is a minor version; later minor versions
   only append data, so the two defined fields are read for any value. *)
fun stylistic(b: !Buf, s: OtSpan): OtFeatureParamsRead =
  if ilt(s.length,4) then reject(OtBounds(),s)
  else accept(ParamsStylistic(@{version=ot_u16(b,s,0),name=ot_u16(b,s,2)}))

(* uint24 scalar at relative offset: u16(off)*256 + low byte of u16(off+1),
   both reads inside the span because the caller checked its length. *)
fun scalar_at(b: !Buf, s: OtSpan, off: int): int =
  iadd(imul(ot_u16(b,s,off),256),imod(ot_u16(b,s,iadd(off,1)),256))
fun scalar_valid(cp: int): bool =
  ile(cp,UNICODE_MAX_SCALAR) andalso not(ige(cp,UNICODE_SURROGATE_START) andalso ile(cp,57343))
fun chars_valid {n:nat} .<n>. (n: int(n), b: !Buf, s: OtSpan, i: int): bool =
  if n = 0 then true
  else if not(scalar_valid(scalar_at(b,s,iadd(14,imul(i,3))))) then false
  else chars_valid(n-1,b,s,iadd(i,1))

(* cv01-cv99: format 0 header of 14 bytes, then charCount uint24 scalars.
   Without named parameters the first-parameter name ID must be zero. *)
fun variant_read(b: !Buf, s: OtSpan): OtFeatureParamsRead = let
  val format=ot_u16(b,s,0)
  val count=ot_u16(b,s,12)
  val named=ot_u16(b,s,8)
  val first=ot_u16(b,s,10)
in
  if ine(format,0) then reject(OtFormat(),s)
  else if ilt(s.length,iadd(14,imul(3,count))) then reject(OtBounds(),s)
  else if ieq(named,0) andalso ine(first,0) then reject(OtFormat(),s)
  else if not(chars_valid(airlock_nat(count),b,s,0)) then reject(OtFormat(),s)
  else accept(ParamsVariant(@{label=ot_u16(b,s,2),tooltip=ot_u16(b,s,4),
    sample=ot_u16(b,s,6),named=named,first=first,charCount=count}))
end
fun variant(b: !Buf, s: OtSpan): OtFeatureParamsRead =
  if ilt(s.length,14) then reject(OtBounds(),s) else variant_read(b,s)

fun present(b: !Buf, tag: OtTag, s: OtSpan): OtFeatureParamsRead =
  if not(ot_span_valid(b,s)) then reject(OtBounds(),s)
  else case+ ot_params_kind_of(tag) of
    | ParamsKindSize() => size(b,s)
    | ParamsKindStylistic() => stylistic(b,s)
    | ParamsKindVariant() => variant(b,s)
    | ParamsKindOpaque() => accept(ParamsOpaque())

implement ot_feature_params_parse(b,tag,params) = case+ params.kind of
  | ChildMissing() => accept(ParamsAbsent())
  | ChildInvalid() => reject(OtBounds(),params.span)
  | ChildPresent() => present(b,tag,params.span)
