#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef NORMALIZATION_DRAFT_EXCLUDE_MASK_INITIAL_BYTES = 1114112

staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_draft.sats"
staload "data_text/normalization/normalization_exclusions.sats"
extern fun exclusion_exhausted(): int = "mac#anth_die_int"

fun set_range {n:nat} .<n>. (n: int(n), mask: !Buf, cp: int): void =
  if n = 0 then () else let val () = buf_set(mask,cp,1) in set_range(n-1,mask,iadd(cp,1)) end

fun exclusion_row(source: !Buf, start: int, finish: int, mask: !Buf): bool = let
  val semicolon = text_find_byte(source,start,finish,59)
  val field = text_skip_space(source,iadd(semicolon,1),finish)
in if not(text_token_is(source,field,finish,"Full_Composition_Exclusion")) then true else let
    var position: int = start
    val first = text_hex(source,position,semicolon)
    val last = if ieq(buf_get(source,position),CHAR_DOT) then let
      val () = position := iadd(position,2)
    in text_hex(source,position,semicolon) end else first
    val valid = ige(first,0) andalso ige(last,first) andalso ilt(last,1114112)
      andalso ieq(text_skip_space(source,position,semicolon),semicolon)
  in if not(valid) then false else let
      val () = set_range(airlock_nat(iadd(isub(last,first),1)),mask,first)
    in true end end end

fun lines {n:nat} .<n>. (n: int(n), source: !Buf, mask: !Buf, p: int): int =
  if ige(p,buf_len(source)) then 0 else if n = 0 then exclusion_exhausted() else let
    val finish = text_line_end(source,p,buf_len(source))
    val start = text_skip_space(source,p,finish)
    val comment = ige(start,finish) orelse ieq(buf_get(source,start),CHAR_HASH)
    val valid = comment orelse exclusion_row(source,start,finish,mask)
  in if not(valid) then 1 else lines(n-1,source,mask,iadd(finish,1)) end

fun apply {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, mask: !Buf, i: int): void =
  if n = 0 then () else let
    val row = normalization_draft_row(draft,i)
    val updated = @{cp=row.cp,ccc=row.ccc,kind=row.kind,offset=row.offset,count=row.count,
      depth=row.depth,canonical=row.canonical,compatibility=row.compatibility,excluded=igt(buf_get(mask,row.cp),0)}
    val () = normalization_draft_update(draft,i,updated)
  in apply(n-1,draft,mask,iadd(i,1)) end

implement normalization_draft_exclude(draft,source) = let
  val mask = buf_make(NORMALIZATION_DRAFT_EXCLUDE_MASK_INITIAL_BYTES)
  val valid = ieq(lines(airlock_nat(iadd(buf_len(source),1)),source,mask,0),0)
  val () = if valid then apply(airlock_nat(normalization_draft_count(draft)),draft,mask,0) else ()
  val () = buf_free(mask)
in valid end
