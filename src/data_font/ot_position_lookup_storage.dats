#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/ot_position_lookup_work.sats"
implement ot_position_tables_make(xs,n) = let
  val (pf,gc | rows)=array_ptr_alloc<OtPositionPayload>(i2sz(n))
  val ()=array_initize_list_vt<OtPositionPayload>(!rows,n,xs)
in OtPositionTables(pf,gc | rows,n,n) end
implement ot_position_payload_list_dispose(xs) = dispose(xs) where {
  fun dispose{n:nat} .<n>. (xs: list_vt(OtPositionPayload,n)): void = case+ xs of | ~list_vt_nil() => ()
    | ~list_vt_cons(x,tail) => let val ()=ot_position_payload_dispose(x) in dispose(tail) end }
implement array_uninitize$clear<OtPositionPayload>(i,x) = let val owned=x in ot_position_payload_dispose(owned) end
implement ot_position_tables_dispose(t) = let val+ ~OtPositionTables(pf,gc | rows,n,i)=t
  val ()=array_uninitize<OtPositionPayload>(!rows,i2sz(n))
in array_ptr_free(pf,gc | rows) end
implement ot_position_tables_action(t,fallback) = let val+ OtPositionTables(pf,gc | rows,n,i)=t in
  if n = 0 then fallback else let
    var loan: OtPositionPayload=PositionPayloadVacant()
    val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(0),loan)
    val action=ot_position_payload_action(loan)
    val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(0),loan)
    val ()=ot_position_payload_dispose(loan)
  in action end end
