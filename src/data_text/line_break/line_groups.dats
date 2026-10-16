#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_predicates.sats"
staload "data_text/line_break/line_groups.sats"

implement line_is_hard(k) =
  line_is_bk(k) orelse line_is_cr(k) orelse line_is_lf(k) orelse line_is_nl(k)
implement line_is_combining(k) = line_is_cm(k) orelse line_is_zwj(k)
implement line_accepts_marks(k) =
  not(line_is_missing(k) orelse line_is_hard(k) orelse line_is_sp(k) orelse line_is_zw(k))
implement line_is_letter(k) = line_is_al(k) orelse line_is_hl(k)
implement line_is_hyphen(k) = line_is_hy(k) orelse line_is_hh(k)
implement line_is_close(k) = line_is_cl(k) orelse line_is_cp(k)
implement line_is_number_sep(k) = line_is_sy(k) orelse line_is_is(k)
implement line_is_prefix(k) = line_is_pr(k) orelse line_is_po(k)
implement line_is_ideograph(k) = line_is_id(k) orelse line_is_eb(k) orelse line_is_em(k)
implement line_is_hangul(k) =
  line_is_jl(k) orelse line_is_jv(k) orelse line_is_jt(k) orelse line_is_h2(k) orelse line_is_h3(k)
implement line_is_word_start(k) = line_is_missing(k) orelse line_is_hard(k)
  orelse line_is_sp(k) orelse line_is_zw(k) orelse line_is_cb(k) orelse line_is_gl(k)
implement line_is_initial_context(k) = line_is_missing(k) orelse line_is_hard(k)
  orelse line_is_op(k) orelse line_is_qu(k) orelse line_is_gl(k) orelse line_is_sp(k) orelse line_is_zw(k)
implement line_is_final_context(k) = line_is_missing(k) orelse line_is_hard(k)
  orelse line_is_sp(k) orelse line_is_gl(k) orelse line_is_wj(k) orelse line_is_close(k)
  orelse line_is_qu(k) orelse line_is_ex(k) orelse line_is_is(k) orelse line_is_sy(k) orelse line_is_zw(k)
implement line_is_brahmic_base(t) = line_is_ak(t.kind) orelse ieq(t.cp,9676)
implement line_is_brahmic(t) = line_is_brahmic_base(t) orelse line_is_as(t.kind)
