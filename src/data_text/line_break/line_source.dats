#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_source.sats"
staload "data_text/line_break/line_predicates.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/utf8/utf8.sats"

(* Raw property codes are decoded here, once, at the data boundary. *)
fun east_of(code: int): bool = case+ code of
  | 3 => true | 4 => true | 5 => true | _ => false

fun facts_of(width: int,gc: int,ep: bool): LineFacts =
  @{east=east_of(width),initial=ieq(gc,16),final=ieq(gc,17),potential=ieq(gc,0) andalso ep}

fun resolved(k: LineClass,gc: int): LineClass = case+ k of
  | LXX() => LAL() | LAI() => LAL() | LSG() => LAL() | LCJ() => LNS()
  | LSA() => if ieq(gc,6) orelse ieq(gc,7) then LCM() else LAL()
  | LAK() => k | LAL() => k | LAP() => k | LAS() => k | LB2() => k
  | LBA() => k | LBB() => k | LBK() => k | LCB() => k | LCL() => k
  | LCM() => k | LCP() => k | LCR() => k | LEB() => k | LEM() => k
  | LEX() => k | LH2() => k | LH3() => k | LHH() => k | LHL() => k
  | LHY() => k | LID() => k | LIN() => k | LIS() => k | LJL() => k
  | LJT() => k | LJV() => k | LLF() => k | LNL() => k | LNS() => k
  | LNU() => k | LOP() => k | LPO() => k | LPR() => k | LQU() => k
  | LRI() => k | LSP() => k | LSY() => k | LVF() => k | LVI() => k
  | LWJ() => k | LZW() => k | LZWJ() => k | LGL() => k | LMissing() => k

implement line_source_token(map,width,category,emoji,cp,index) = let
  val kind = line_class_of(property_value(map,cp))
  val gc = property_value(category,cp)
  val facts = facts_of(property_value(width,cp),gc,unicode_pictographic(emoji,cp))
in @{kind=resolved(kind,gc),cp=cp,facts=facts,zwj=line_is_zwj(kind),source=index} end

(* LB10's virtual A resets every property, not just Line_Break. *)
implement line_unbound_mark(t) =
  @{kind=LAL(),cp=65,facts= @{east=false,initial=false,final=false,potential=false},
    zwj=t.zwj,source=t.source}
