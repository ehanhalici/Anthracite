#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_types.sats"
staload "data_text/line_predicates.sats"

implement line_is_ak(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => true | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_ap(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => true
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_as(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => true | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_h2(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => true
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_h3(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => true | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_jl(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => true | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_jt(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => true | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_jv(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => true
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_vf(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => true | LVI() => false
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false

implement line_is_vi(k) = case+ k of
  | LXX() => false | LAI() => false | LAK() => false | LAL() => false | LAP() => false
  | LAS() => false | LB2() => false | LBA() => false | LBB() => false | LBK() => false
  | LCB() => false | LCJ() => false | LCL() => false | LCM() => false | LCP() => false
  | LCR() => false | LEB() => false | LEM() => false | LEX() => false | LH2() => false
  | LH3() => false | LHH() => false | LHL() => false | LHY() => false | LID() => false
  | LIN() => false | LIS() => false | LJL() => false | LJT() => false | LJV() => false
  | LLF() => false | LNL() => false | LNS() => false | LNU() => false | LOP() => false
  | LPO() => false | LPR() => false | LQU() => false | LRI() => false | LSA() => false
  | LSG() => false | LSP() => false | LSY() => false | LVF() => false | LVI() => true
  | LWJ() => false | LZW() => false | LZWJ() => false | LGL() => false | LMissing() => false
