#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_predicates.sats"
staload "data_text/line_break/line_groups.sats"
staload "data_text/line_break/line_rules.sats"

fun decide_syllables(c: LineContext): LineDecision = case+ line_rules_syllables(c) of
  | LinePending() => line_rules_final(c)
  | LineForbidden() => LineForbidden()
  | LineOptional() => LineOptional()
  | LineMandatory() => LineMandatory()

fun decide_numbers(c: LineContext): LineDecision = case+ line_rules_numbers(c) of
  | LinePending() => decide_syllables(c)
  | LineForbidden() => LineForbidden()
  | LineOptional() => LineOptional()
  | LineMandatory() => LineMandatory()

fun decide_words(c: LineContext): LineDecision = case+ line_rules_words(c) of
  | LinePending() => decide_numbers(c)
  | LineForbidden() => LineForbidden()
  | LineOptional() => LineOptional()
  | LineMandatory() => LineMandatory()

fun decide_quotes(c: LineContext): LineDecision = case+ line_rules_quotes(c) of
  | LinePending() => decide_words(c)
  | LineForbidden() => LineForbidden()
  | LineOptional() => LineOptional()
  | LineMandatory() => LineMandatory()

fun decide_punctuation(c: LineContext): LineDecision = case+ line_rules_punctuation(c) of
  | LinePending() => decide_quotes(c)
  | LineForbidden() => LineForbidden()
  | LineOptional() => LineOptional()
  | LineMandatory() => LineMandatory()

fun decide_glue(c: LineContext): LineDecision = case+ line_rules_glue(c) of
  | LinePending() => decide_punctuation(c)
  | LineForbidden() => LineForbidden()
  | LineOptional() => LineOptional()
  | LineMandatory() => LineMandatory()

fun decide_hard(c: LineContext): LineDecision = case+ line_rules_hard(c) of
  | LinePending() => decide_glue(c)
  | LineForbidden() => LineForbidden()
  | LineOptional() => LineOptional()
  | LineMandatory() => LineMandatory()

implement line_decide(c) = decide_hard(c)
