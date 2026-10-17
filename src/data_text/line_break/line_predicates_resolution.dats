#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_predicates.sats"

implement line_is_xx(k) = case+ k of
  | LXX() => true | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_ai(k) = case+ k of
  | LXX() => false | LAI() => true | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_cj(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => true | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_sa(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => true
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_sg(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => true | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false
