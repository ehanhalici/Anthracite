#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_predicates.sats"

implement bidi_is_nsm(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => true | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_arabic(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => true | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_en(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => true
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_an(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => true | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_et(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => true | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_separator(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => true | BET() => false | BAN() => false | BCS() => true
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_cs(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => true
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_neutral(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => true | BS() => true | BWS() => true | BON() => true
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => true
  | BLRI() => true | BRLI() => true | BPDI() => true

implement bidi_is_other(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => true
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_line_separator(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => true | BS() => true | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_is_line_space(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => true | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => true
  | BLRI() => true | BRLI() => true | BPDI() => true

implement bidi_level_direction(level) =
  if ieq(imod(level,2),0) then BL() else BR()

implement bidi_is_paragraph_separator(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => true | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_numeric_direction(kind) =
  if bidi_is_en(kind) orelse bidi_is_an(kind) then BR() else kind
