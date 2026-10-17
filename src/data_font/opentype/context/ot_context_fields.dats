#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef FIRST_OUTPUT_INITIAL_BYTES = 4

staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/context/ot_context_work.sats"
fun fields {n:nat} .<n>. (n: int(n),output: !Buf,slot: int,at: int): void =
  if n = 0 then () else let val ()=buf_set32(output,slot,at) in
    fields(n-1,output,iadd(slot,1),iadd(at,2)) end
fun direct(p: OtContextPattern): Buf = let
  val total=iadd(iadd(p.backCount,p.inputCount),p.lookCount)
  val output=buf_make(imul(total,4))
  val ()=fields(airlock_nat(p.backCount),output,0,p.backAt)
  val ()=fields(airlock_nat(p.inputCount),output,p.backCount,p.inputAt)
  val ()=fields(airlock_nat(p.lookCount),output,iadd(p.backCount,p.inputCount),p.lookAt)
  val ()=buf_set_len(output,imul(total,4))
in output end
fun first(): Buf = let
  val output=buf_make(FIRST_OUTPUT_INITIAL_BYTES)
  val ()=buf_set32(output,0,2) and ()=buf_set_len(output,4)
in output end
implement ot_context_fields(info) = case+ info.encoding of
  | ContextGlyphs() => first() | ContextClasses() => first() | ContextCoverages() => direct(info.pattern)
