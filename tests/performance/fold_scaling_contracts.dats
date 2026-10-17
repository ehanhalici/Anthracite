#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "core_runtime/performance.sats"
staload "data_ast/document/doc.sats"
staload "ui_workspace/common/ui_common.sats"

fun fill{n:nat} .<n>. (remaining: int(n), text: &Buf >> Buf): void =
  if remaining > 0 then let
    val () = buffer_append_string(text, "# heading\nbody\n")
  in fill(remaining-1, text) end else ()

fun owners{n:nat} .<n>. (remaining: int(n), d: !Doc, index: int): bool =
  if remaining > 0 then let
    val line = imul(index, 2)
    val node = doc_line_node_foldable(d, line)
    val ok = ige(node, 0) andalso is_kind(doc_node_kind(d, node), KH1)
  in ok andalso owners(remaining-1, d, iadd(index, 1)) end else true

fun check_count(count: int): int = let
  val before = mem_live()
  var text: Buf = buf_make(1)
  val () = fill(airlock_nat(count), text)
  val d = doc_open()
  val () = performance_reset()
  val length = buf_len(text)
  val () = doc_insert_buf(d, text, length)
  val visits = performance_value(PERF_FOLD_NODE_VISITS)
  val bound = g0int2uint_int_ullint(iadd(doc_nnodes(d), doc_region_count(d)))
  val linear = visits <= bound andalso performance_value(PERF_FOLD_PREPARES) = 1ULL
  val ok = linear andalso ieq(doc_region_count(d), count) andalso owners(airlock_nat(count), d, 0)
  val () = doc_free(d)
  val () = buf_free(text)
  val () = println!("event=fold_scaling count=",count," visits=",visits," bound=",bound," ok=",ok)
in if ok andalso ieq(before, mem_live()) then 0 else 1 end

implement main0() = let
  val () = performance_enable(1)
  val errors = iadd(check_count(32), iadd(check_count(256), check_count(2048)))
in if igt(errors,0) then exit(1) else () end
