#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/grapheme/grapheme.sats"

implement grapheme_initial() =
  @{previous=GControl(), regional=0, emoji=EmojiNone(), conjunct=ConjunctNone()}

fun is_control(k: GraphemeClass): bool = case+ k of
  | GCR() => true | GLF() => true | GControl() => true
  | GOther() => false | GExtend() => false | GZWJ() => false
  | GRegional() => false | GPrepend() => false | GSpacing() => false
  | GL() => false | GV() => false | GT() => false | GLV() => false | GLVT() => false

fun hangul_left(k: GraphemeClass): bool = case+ k of
  | GL() => true | GV() => true | GLV() => true | GLVT() => true
  | GOther() => false | GCR() => false | GLF() => false | GControl() => false
  | GExtend() => false | GZWJ() => false | GRegional() => false
  | GPrepend() => false | GSpacing() => false | GT() => false

fun hangul_v(k: GraphemeClass): bool = case+ k of
  | GV() => true | GT() => true
  | GOther() => false | GCR() => false | GLF() => false | GControl() => false
  | GExtend() => false | GZWJ() => false | GRegional() => false
  | GPrepend() => false | GSpacing() => false | GL() => false | GLV() => false | GLVT() => false

fun is_tail(k: GraphemeClass): bool = case+ k of
  | GT() => true
  | GOther() => false | GCR() => false | GLF() => false | GControl() => false
  | GExtend() => false | GZWJ() => false | GRegional() => false
  | GPrepend() => false | GSpacing() => false | GL() => false | GV() => false | GLV() => false | GLVT() => false

fun hangul_join(a: GraphemeClass, b: GraphemeClass): bool = case+ a of
  | GL() => hangul_left(b) | GV() => hangul_v(b) | GLV() => hangul_v(b)
  | GT() => is_tail(b) | GLVT() => is_tail(b)
  | GOther() => false | GCR() => false | GLF() => false | GControl() => false
  | GExtend() => false | GZWJ() => false | GRegional() => false | GPrepend() => false | GSpacing() => false

fun is_attached(k: GraphemeClass): bool = case+ k of
  | GExtend() => true | GZWJ() => true | GSpacing() => true
  | GOther() => false | GCR() => false | GLF() => false | GControl() => false
  | GRegional() => false | GPrepend() => false | GL() => false
  | GV() => false | GT() => false | GLV() => false | GLVT() => false

fun is_lf(k: GraphemeClass): bool = case+ k of
  | GLF() => true | GCR() => false | GControl() => false | GOther() => false
  | GExtend() => false | GZWJ() => false | GRegional() => false
  | GPrepend() => false | GSpacing() => false | GL() => false
  | GV() => false | GT() => false | GLV() => false | GLVT() => false

fun crlf(a: GraphemeClass, b: GraphemeClass): bool = case+ a of
  | GCR() => is_lf(b) | GLF() => false | GControl() => false | GOther() => false
  | GExtend() => false | GZWJ() => false | GRegional() => false
  | GPrepend() => false | GSpacing() => false | GL() => false
  | GV() => false | GT() => false | GLV() => false | GLVT() => false

fun is_prepend(k: GraphemeClass): bool =
  case+ k of | GPrepend() => true
  | GOther() => false | GCR() => false | GLF() => false | GControl() => false
  | GExtend() => false | GZWJ() => false | GRegional() => false
  | GSpacing() => false | GL() => false | GV() => false
  | GT() => false | GLV() => false | GLVT() => false

fun is_regional(k: GraphemeClass): bool =
  case+ k of | GRegional() => true
  | GOther() => false | GCR() => false | GLF() => false | GControl() => false
  | GExtend() => false | GZWJ() => false | GPrepend() => false
  | GSpacing() => false | GL() => false | GV() => false
  | GT() => false | GLV() => false | GLVT() => false

fun is_emoji_joiner(k: EmojiContext): bool =
  case+ k of | EmojiJoiner() => true | EmojiBase() => false | EmojiNone() => false

fun is_consonant(k: ConjunctClass): bool = case+ k of
  | InConsonant() => true | InNone() => false | InExtend() => false | InLinker() => false

fun conjunct_joins(ctx: ConjunctContext, current: ConjunctClass): bool = case+ ctx of
  | ConjunctLinked() => is_consonant(current) | ConjunctNone() => false

fun boundary(state: GraphemeState, k: GraphemeClass, incb: ConjunctClass, emoji: bool): bool =
  if crlf(state.previous,k) then false
  else if is_control(state.previous) orelse is_control(k) then true
  else if hangul_join(state.previous,k) orelse is_attached(k) then false
  else if is_prepend(state.previous) orelse conjunct_joins(state.conjunct,incb) then false
  else if emoji andalso is_emoji_joiner(state.emoji) then false
  else if is_regional(k) andalso ieq(imod(state.regional,2),1) then false
  else true

fun emoji_after_base(k: GraphemeClass): EmojiContext = case+ k of
  | GExtend() => EmojiBase() | GZWJ() => EmojiJoiner()
  | GOther() => EmojiNone() | GCR() => EmojiNone() | GLF() => EmojiNone()
  | GControl() => EmojiNone() | GRegional() => EmojiNone() | GPrepend() => EmojiNone()
  | GSpacing() => EmojiNone() | GL() => EmojiNone() | GV() => EmojiNone()
  | GT() => EmojiNone() | GLV() => EmojiNone() | GLVT() => EmojiNone()

fun emoji_next(previous: EmojiContext, k: GraphemeClass, pictographic: bool): EmojiContext =
  if pictographic then EmojiBase() else case+ previous of
  | EmojiBase() => emoji_after_base(k)
  | EmojiJoiner() => EmojiNone() | EmojiNone() => EmojiNone()

(* Unicode 18 GB9c: Linker Extend* x Consonant; no preceding consonant
   is required. This deliberately differs from the Unicode 17 rule. *)
fun conjunct_next(previous: ConjunctContext, current: ConjunctClass): ConjunctContext =
  case+ current of
  | InNone() => ConjunctNone() | InConsonant() => ConjunctNone()
  | InExtend() => previous | InLinker() => ConjunctLinked()

implement grapheme_step(db, state, cp) = let
  val k = unicode_grapheme(db,cp)
  val incb = unicode_conjunct(db,cp)
  val emoji = unicode_pictographic(db,cp)
  val stop = boundary(state,k,incb,emoji)
  val next = @{previous=k, regional=(if is_regional(k) then iadd(state.regional,1) else 0),
    emoji=emoji_next(state.emoji,k,emoji), conjunct=conjunct_next(state.conjunct,incb)}
in @{boundary=stop,state=next} end

extern fun grapheme_exhausted(): void = "mac#anth_die_void"

fun segment {fuel:nat} .<fuel>. (
  fuel: int(fuel), db: !UnicodeDb, text: !ScalarText, i: int,
  n: int, state: GraphemeState, result: !Buf
): void =
  if ige(i,n) then buf_set(result,n,1)
  else if fuel > 0 then let
    val step = grapheme_step(db,state,scalar_value(text,i))
    val () = buf_set(result,i,if step.boundary then 1 else 0)
  in segment(fuel-1,db,text,iadd(i,1),n,step.state,result) end
  else grapheme_exhausted()

implement grapheme_boundaries(db,text) = let
  val n = scalar_count(text)
  val result = buf_make(iadd(n,1))
  val () = segment(airlock_nat(n),db,text,0,n,grapheme_initial(),result)
in result end
