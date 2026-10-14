#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/text_source.sats"
staload "data_text/text_fields.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_draft.sats"
staload "data_text/normalization_source.sats"
staload "data_text/normalization_hangul.sats"
staload "data_text/normalization_row.sats"
extern fun norm_source_exhausted(): int = "mac#anth_die_int"

fun mapping_values {n:nat} .<n>. (n: int(n), source: !Buf, p: int, finish: int, maps: &Buf >> _, count: int): int =
  if ige(p,finish) then count else if n = 0 then norm_source_exhausted() else let
    var next: int = p
    val cp = text_hex(source,next,finish)
    val valid = normalization_scalar_valid(cp) andalso igt(next,p)
  in if not(valid) then ~1 else let
      val () = buf_ensure(maps,imul(iadd(count,1),4))
      val () = buf_set32(maps,count,cp)
    in mapping_values(n-1,source,text_skip_space(source,next,finish),finish,maps,iadd(count,1)) end end

fun store_row(rows: &Buf >> _, row: NormalizationRow, counts: DraftCounts, total: int): DraftCounts =
  if ieq(row.ccc,0) andalso not(normalization_has_mapping(row.kind)) then
    @{rows=counts.rows,mappings=total,valid=true}
  else let
    val previous = if ieq(counts.rows,0) then ~1 else buf_get32(rows,imul(isub(counts.rows,1),NORMALIZATION_ROW_WORDS))
    val valid = normalization_scalar_valid(row.cp) andalso igt(row.cp,previous)
      andalso not(normalization_hangul_syllable(row.cp))
  in if not(valid) then @{rows=counts.rows,mappings=total,valid=false} else let
      val at = imul(counts.rows,NORMALIZATION_ROW_WORDS)
      val () = buf_ensure(rows,imul(iadd(at,NORMALIZATION_ROW_WORDS),4))
      val () = normalization_row_write(rows,at,row)
    in @{rows=iadd(counts.rows,1),mappings=total,valid=true} end end

fun emit_mapping(
  source: !Buf, rows: &Buf >> _, maps: &Buf >> _, counts: DraftCounts,
  cp: int, ccc: int, start: int, finish: int
): DraftCounts = let
  val header = normalization_mapping_header(source,start,finish)
  val total = if header.valid then mapping_values(airlock_nat(iadd(isub(finish,header.start),1)),source,header.start,finish,maps,counts.mappings) else ~1
  val size = isub(total,counts.mappings)
  val valid = header.valid andalso ige(total,0)
    andalso (not(normalization_has_mapping(header.kind)) orelse igt(size,0))
  val row = @{cp=cp,ccc=ccc,kind=header.kind,offset=counts.mappings,count=size,depth=0,
    canonical=(if normalization_has_mapping(header.kind) then 0 else 1),
    compatibility=(if normalization_has_mapping(header.kind) then 0 else 1),excluded=false}
in if not(valid) then @{rows=counts.rows,mappings=counts.mappings,valid=false}
  else store_row(rows,row,counts,total) end

implement normalization_source_row(source,start,finish,rows,maps,counts) = let
  var position: int = start
  val cp = text_hex(source,position,finish)
  val cp_valid = igt(position,start) andalso ieq(buf_get(source,position),59) andalso ige(cp,0) andalso ilt(cp,1114112)
  val ccc_start = text_field(source,start,finish,3)
  val ccc_end = text_find_byte(source,ccc_start,finish,59)
  val () = position := ccc_start
  val ccc = text_decimal(source,position,ccc_end)
  val mapping_start = text_field(source,start,finish,5)
  val mapping_end = text_find_byte(source,mapping_start,finish,59)
  val valid = cp_valid andalso ige(ccc,0) andalso ile(ccc,255) andalso ieq(position,ccc_end) andalso ilt(mapping_end,finish)
in if not(valid) then @{rows=counts.rows,mappings=counts.mappings,valid=false}
  else emit_mapping(source,rows,maps,counts,cp,ccc,mapping_start,mapping_end) end
