#include "data_ast/folding/private/fold_region/regions_radix_sort.hats"

fun regions_sort_by_owner(regions: !Buf): void =
  seen_int(regions_sort_work(regions))

implement fold_region_build(d, regions) = let
  val () = buf_set_len(regions, 0)
  val nlines = doc_nlines(d)
  var delim_buf = buf_make(imax(INITIAL_BUF_BYTES, nlines))
  val () = buf_ensure(delim_buf, nlines)
  val () = buf_zero(delim_buf)
  val () = buf_set_len(delim_buf, nlines)
  val () = collect_delimited_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, doc_nnodes(d), regions, delim_buf)
  var stk = buf_make(INITIAL_STACK_BYTES)
  val () = scan_lines_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nlines, stk, regions, delim_buf)
  val () = stack_drain_all_with_fuel(airlock_nat(MAX_REC_FUEL), stk, regions, nlines, d)
  val () = buf_free(stk)
  val () = buf_free(delim_buf)
  val () = regions_sort_by_owner(regions)
in
  fold_region_count(regions)
end

#include "data_ast/folding/private/fold_region/mark_hidden_lines.hats"

fun sweep_one_region(
  d: !Doc, regions: !Buf, r: int, hidden: !Buf, cover_end: &int >> _
): void = let
  val owner = fold_region_owner(regions, r)
  val fend = fold_region_end(regions, r)
  val off = fold_region_offset(regions, r)
in
  if ilt(owner, cover_end) then ()
  else if fold_has(d, off) then let
    val () = mark_hidden_lines_with_fuel(airlock_nat(MAX_REC_FUEL), hidden, iadd(owner, 1), fend)
    val () = cover_end := imax(cover_end, fend)
  in
  end else ()
end

fun sweep_regions_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, regions: !Buf, r: int, nreg: int, hidden: !Buf, cover_end: &int >> _
): void =
  if recursion_fuel_available(recfuel) then (
    if r >= nreg then ()
    else let
      val () = sweep_one_region(d, regions, r, hidden, cover_end)
    in
      sweep_regions_with_fuel(recfuel - 1, d, regions, iadd(r, 1), nreg, hidden, cover_end)
    end
  ) else ()

implement fold_regions_compute_hidden(d, regions, hidden) = let
  val nlines = doc_nlines(d)
  val () = buf_ensure(hidden, nlines)
  val () = buf_zero(hidden)
  val () = buf_set_len(hidden, nlines)
  var cover_end: int = ~1
  val nreg = fold_region_count(regions)
in
  sweep_regions_with_fuel(airlock_nat(MAX_REC_FUEL), d, regions, 0, nreg, hidden, cover_end)
end

implement fold_region_line_hidden(hidden, line) =
  if line < 0 orelse line >= buf_len(hidden) then 0
  else buf_get(hidden, line)
