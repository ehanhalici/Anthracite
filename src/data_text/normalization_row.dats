#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_row.sats"
extern fun norm_kind_invalid(): DecompositionKind = "mac#anth_die_box"
extern fun norm_row_exhausted(): int = "mac#anth_die_int"

implement normalization_kind_of(code) = case+ code of
  | 0 => NoMapping() | 1 => CanonicalMapping() | 2 => CompatibilityMapping() | _ => norm_kind_invalid()
implement normalization_kind_code(kind) = case+ kind of
  | NoMapping() => 0 | CanonicalMapping() => 1 | CompatibilityMapping() => 2
implement normalization_has_mapping(kind) = case+ kind of
  | NoMapping() => false | CanonicalMapping() => true | CompatibilityMapping() => true
implement normalization_is_canonical(kind) = case+ kind of
  | NoMapping() => false | CanonicalMapping() => true | CompatibilityMapping() => false
implement normalization_scalar_valid(cp) =
  ige(cp,0) andalso ilt(cp,1114112) andalso not(ige(cp,55296) andalso ile(cp,57343))

implement normalization_default_row(cp) =
  @{cp=cp,ccc=0,kind=NoMapping(),offset=0,count=0,depth=0,canonical=1,compatibility=1,excluded=false}

implement normalization_row_read(rows,at) =
  @{cp=buf_get32(rows,at),ccc=buf_get32(rows,iadd(at,1)),kind=normalization_kind_of(buf_get32(rows,iadd(at,2))),
    offset=buf_get32(rows,iadd(at,3)),count=buf_get32(rows,iadd(at,4)),depth=buf_get32(rows,iadd(at,5)),
    canonical=buf_get32(rows,iadd(at,6)),compatibility=buf_get32(rows,iadd(at,7)),excluded=igt(buf_get32(rows,iadd(at,8)),0)}

implement normalization_row_write(rows,at,row) = let
  val () = buf_set32(rows,at,row.cp)
  val () = buf_set32(rows,iadd(at,1),row.ccc)
  val () = buf_set32(rows,iadd(at,2),normalization_kind_code(row.kind))
  val () = buf_set32(rows,iadd(at,3),row.offset)
  val () = buf_set32(rows,iadd(at,4),row.count)
  val () = buf_set32(rows,iadd(at,5),row.depth)
  val () = buf_set32(rows,iadd(at,6),row.canonical)
  val () = buf_set32(rows,iadd(at,7),row.compatibility)
in buf_set32(rows,iadd(at,8),if row.excluded then 1 else 0) end

fun search {n:nat} .<n>. (n: int(n), rows: !Buf, offset: int, cp: int, low: int, high: int): int =
  if ige(low,high) then ~1 else if n = 0 then norm_row_exhausted() else let
    val mid = iadd(low,idiv(isub(high,low),2))
    val value = buf_get32(rows,iadd(offset,imul(mid,NORMALIZATION_ROW_WORDS)))
  in if ilt(cp,value) then search(n-1,rows,offset,cp,low,mid)
    else if igt(cp,value) then search(n-1,rows,offset,cp,iadd(mid,1),high) else mid end

implement normalization_row_search(rows,offset,count,cp) =
  search(airlock_nat(iadd(count,1)),rows,offset,cp,0,count)
