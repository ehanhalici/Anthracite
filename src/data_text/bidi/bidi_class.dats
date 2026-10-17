#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"

extern fun bidi_invalid_class(): BidiClass = "mac#anth_die_box"
extern fun bidi_invalid_direction(): ParagraphDirection = "mac#anth_die_box"

implement bidi_class_of(code) = case+ code of
  | 0 => BL() | 1 => BR() | 2 => BAL() | 3 => BEN()
  | 4 => BES() | 5 => BET() | 6 => BAN() | 7 => BCS()
  | 8 => BB() | 9 => BS() | 10 => BWS() | 11 => BON()
  | 12 => BLRE() | 13 => BLRO() | 14 => BRLE() | 15 => BRLO()
  | 16 => BPDF() | 17 => BNSM() | 18 => BBN() | 19 => BFSI()
  | 20 => BLRI() | 21 => BRLI() | 22 => BPDI()
  | _ => bidi_invalid_class()

implement bidi_class_code(kind) = case+ kind of
  | BL() => 0 | BR() => 1 | BAL() => 2 | BEN() => 3
  | BES() => 4 | BET() => 5 | BAN() => 6 | BCS() => 7
  | BB() => 8 | BS() => 9 | BWS() => 10 | BON() => 11
  | BLRE() => 12 | BLRO() => 13 | BRLE() => 14 | BRLO() => 15
  | BPDF() => 16 | BNSM() => 17 | BBN() => 18 | BFSI() => 19
  | BLRI() => 20 | BRLI() => 21 | BPDI() => 22

implement bidi_direction_of(code) = case+ code of
  | 0 => ForceLtr() | 1 => ForceRtl() | 2 => AutoLtr() | 3 => AutoRtl()
  | _ => bidi_invalid_direction()

implement bidi_class_is_ltr(kind) = case+ kind of
  | BL() => true | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_class_is_strong(kind) = case+ kind of
  | BL() => true | BR() => true | BAL() => true | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false

implement bidi_class_is_isolate(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => true
  | BLRI() => true | BRLI() => true | BPDI() => false

implement bidi_class_is_pdi(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => false | BLRO() => false | BRLE() => false | BRLO() => false
  | BPDF() => false | BNSM() => false | BBN() => false | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => true

implement bidi_class_is_removed(kind) = case+ kind of
  | BL() => false | BR() => false | BAL() => false | BEN() => false
  | BES() => false | BET() => false | BAN() => false | BCS() => false
  | BB() => false | BS() => false | BWS() => false | BON() => false
  | BLRE() => true | BLRO() => true | BRLE() => true | BRLO() => true
  | BPDF() => true | BNSM() => false | BBN() => true | BFSI() => false
  | BLRI() => false | BRLI() => false | BPDI() => false
