#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_draft.sats"
staload "data_text/normalization/normalization_source.sats"
staload "data_text/normalization/normalization_errors.sats"
extern fun norm_lines_exhausted(): int = "mac#anth_die_int"

fun source_line(source: !Buf, rows: &Buf >> _, maps: &Buf >> _, p: int, finish: int, counts: DraftCounts): DraftCounts = let
  val start = text_skip_space(source,p,finish)
  val comment = ige(start,finish) orelse ieq(buf_get(source,start),CHAR_HASH)
in if comment then counts else normalization_source_row(source,start,finish,rows,maps,counts) end

fun lines {n:nat} .<n>. (
  n: int(n), source: !Buf, rows: &Buf >> _, maps: &Buf >> _, p: int, counts: DraftCounts
): DraftCounts = if ige(p,buf_len(source)) then counts else if n = 0 then let
    val stop = norm_lines_exhausted()
  in counts end else let
    val finish = text_line_end(source,p,buf_len(source))
    val updated = source_line(source,rows,maps,p,finish,counts)
  in if not(updated.valid) then updated else lines(n-1,source,rows,maps,iadd(finish,1),updated) end

implement normalization_source(source) = let
  var rows = buf_make(WORD16_MODULUS)
  var maps = buf_make(WORD16_MODULUS)
  val counts = lines(airlock_nat(iadd(buf_len(source),1)),source,rows,maps,0,@{rows=0,mappings=0,valid=true})
in if counts.valid andalso igt(counts.rows,0) then DraftLoaded(NormalizationDraft(rows,maps,counts.rows,counts.mappings))
  else let val () = buf_free(rows) val () = buf_free(maps) in DraftRejected(NormSource()) end end
