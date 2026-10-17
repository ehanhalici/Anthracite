#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_break/line_types.sats"

implement line_class_of(code) = case+ code of
  | 0 => LXX() | 1 => LAI() | 2 => LAK() | 3 => LAL()
  | 4 => LAP() | 5 => LAS() | 6 => LB2() | 7 => LBA()
  | 8 => LBB() | 9 => LBK() | 10 => LCB() | 11 => LCJ()
  | 12 => LCL() | 13 => LCM() | 14 => LCP() | 15 => LCR()
  | 16 => LEB() | 17 => LEM() | 18 => LEX() | 19 => LH2()
  | 20 => LH3() | 21 => LHH() | 22 => LHL() | 23 => LHY()
  | 24 => LID() | 25 => LIN() | 26 => LIS() | 27 => LJL()
  | 28 => LJT() | 29 => LJV() | 30 => LLF() | 31 => LNL()
  | 32 => LNS() | 33 => LNU() | 34 => LOP() | 35 => LPO()
  | 36 => LPR() | 37 => LQU() | 38 => LRI() | 39 => LSA()
  | 40 => LSG() | 41 => LSP() | 42 => LSY() | 43 => LVF()
  | 44 => LVI() | 45 => LWJ() | 46 => LZW() | 47 => LZWJ()
  | 48 => LGL()
  | _ => LMissing()

implement line_class_code(k) = case+ k of
  | LXX() => 0 | LAI() => 1 | LAK() => 2 | LAL() => 3
  | LAP() => 4 | LAS() => 5 | LB2() => 6 | LBA() => 7
  | LBB() => 8 | LBK() => 9 | LCB() => 10 | LCJ() => 11
  | LCL() => 12 | LCM() => 13 | LCP() => 14 | LCR() => 15
  | LEB() => 16 | LEM() => 17 | LEX() => 18 | LH2() => 19
  | LH3() => 20 | LHH() => 21 | LHL() => 22 | LHY() => 23
  | LID() => 24 | LIN() => 25 | LIS() => 26 | LJL() => 27
  | LJT() => 28 | LJV() => 29 | LLF() => 30 | LNL() => 31
  | LNS() => 32 | LNU() => 33 | LOP() => 34 | LPO() => 35
  | LPR() => 36 | LQU() => 37 | LRI() => 38 | LSA() => 39
  | LSG() => 40 | LSP() => 41 | LSY() => 42 | LVF() => 43
  | LVI() => 44 | LWJ() => 45 | LZW() => 46 | LZWJ() => 47
  | LGL() => 48
  | LMissing() => ~1

extern fun invalid_boundary(): LineBreak = "mac#anth_die_box"
implement line_break_of(code) = case+ code of
  | 0 => BreakForbidden() | 1 => BreakOptional() | 2 => BreakMandatory()
  | _ => invalid_boundary()
implement line_break_code(d) = case+ d of
  | BreakForbidden() => 0 | BreakOptional() => 1 | BreakMandatory() => 2
implement line_finalize(d) = case+ d of
  | LineForbidden() => BreakForbidden() | LineOptional() => BreakOptional()
  | LineMandatory() => BreakMandatory() | LinePending() => invalid_boundary()
